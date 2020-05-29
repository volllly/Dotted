function dotfiler() {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0, Mandatory = $true)]
    [ValidateSet("Install", "Update", "Link", "Sync")]
    $Command,

    [Switch]$NoUpdate = $false,

    [Switch]$NoLink = $false,

    [Switch]$NoInstall = $false,

    [Switch]$Pull = $false,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    $Path = $PWD,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [ValidateSet("SymbolicLink", "HardLink")]
    $LinkType = "HardLink",
    
    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [String[]] $Dotfiles
  )

  Import-Module powershell-yaml
  Import-Module PsTokens

  $os = $false
  if($PSVersionTable.OS) {
    if($PSVersionTable.OS.StartsWith("Microsoft Windows")) {
      $os = "windows";
    }

    if($PSVersionTable.OS.StartsWith("Linux")) {
      $os = "linux";
    }

    if($PSVersionTable.OS.StartsWith("Darwin")) {
      $os = "darwin";
    }
  } else {
    $os = "windows";
  }

  $dots = @{ }
  $dotsDefault = @{ }

  $rawDot = ""
  $currentFile = $(Join-Path -Path $Path -ChildPath "dots.yaml")

  if(!(Test-Path $currentFile)) {
    Write-Error "Did Not find dots.yaml"
    Return
  }

  foreach ($line in Get-Content $currentFile) { $rawDot += "`n" + $line }
  $dotsDefault = ConvertFrom-Yaml $rawDot

  
  $dotsDefault = ResolveOs $dotsDefault $os

  $dotsDefault = Enlarge $dotsDefault

  Get-ChildItem $Path -Directory | ForEach-Object {
    $currentDirectory = Join-Path -Path $Path -ChildPath $_.Name
    $currentName = $_.Name
    $rawDot = ""
    $currentFile = $(Join-Path -Path $currentDirectory -ChildPath "dot.yaml")

    if(!(Test-Path $currentFile)) {
      Return
    }
    
    foreach ($line in Get-Content $currentFile) { $rawDot += "`n" + $line }


    $dots[$currentName] = ConvertFrom-Yaml $rawDot

    if(!($dots[$currentName])) {
      $dots[$currentName] = @{ }
    }

    $dots[$currentName] = Enlarge $dots[$currentName]
    
    $dots[$currentName] = ResolveOs $dots[$currentName] $os

    if($null -eq $dots[$currentName]) { $dots[$currentName] = @{ } }

    if($dots[$currentName]) {
      $dots[$currentName] = Merge $dotsDefault $dots[$currentName].Clone()
    }

    if(!($dots[$currentName])) {
      $dots.Remove($currentName)
      return
    }

    if($dots[$currentName]["installs"]) {
      $dots[$currentName]["installs"]["cmd"] = $dots[$currentName]["installs"]["cmd"] | Merge-Tokens -Tokens @{
        name = $currentName
      }
    }

    if($dots[$currentName]["updates"]) {
      $dots[$currentName]["updates"]["cmd"] = $dots[$currentName]["updates"]["cmd"] | Merge-Tokens -Tokens @{
        name = $currentName
      }
    }
  }


  if($Pull -and ($Command -ne "Sync")) {
    Write-Host "Pulling from git remote"
    Invoke-Expression "git -C $(Resolve-Path $path) pull"
    Write-Host ""
  }

  switch($Command) {
    "Sync" {
      Syncs $Dotfiles $Path
    }
    default {
      $dots.Keys | ForEach-Object {

        $name = $_
        if($Dotfiles.Contains("*") -Or $Dotfiles.Contains($name)) {
          switch($Command) {
            "Install" {
              if($dots[$name]["links"] -And !($NoLink)) {
                Links $dots $name
              }
              if($dots[$name]["installs"] -And !($NoInstall)) {
                Installs $dots $name
              }
            }
            "Update" {
              if($dots[$name]["links"] -And !($NoLink)) {
                Links $dots $name
              }
              if($dots[$name]["updates"] -And !($NoUpdate)) {
                Updates $dots $name
              }
            }
            "Link" {
              if($dots[$name]["links"] -And !($NoLinks)) {
                Links $dots $name
              }
            }
            "help" {
              help
            }
            default {
              help
            }
          }
        }
      }
    }
  }
}

function Merge($object, $assign) {
  $new = @{ }
  foreach ($key in $object.Keys) {
    $new[$key] = $object[$key].Clone()
  }
  foreach ($key in $assign.Keys) {
    if($assign[$key].GetType().Name -eq "Hashtable") {
      if(!$new[$key]) {
        $new[$key] = $assign[$key]
      } else {
        $new[$key] = Merge $new[$key] $assign[$key]
      }
    } else {
      $new[$key] = $assign[$key]
    }
  }

  return $new
}

function ResolveOs($dot, $os) {
  $dotOs = $false
  if($dot.ContainsKey("windows") -or $dot.ContainsKey("linux") -or $dot.ContainsKey("darwin") -or $dot.ContainsKey("global")) {
    if($dot.ContainsKey($os) -or $dot.ContainsKey("global")) {
      
      if($dot.ContainsKey("global")) {
        $dotOs = $dot["global"]
      } else {
        $dotOs = @{ }
      }
      
      if($dot.ContainsKey($os)) {
        $dotOs = Merge $dotOs $dot[$os]
      }
    }
  } else {
    $dotOs = $dot
  }

  return $dotOs
}

function Enlarge($dot) {
  function EnlargeSingle($dot) {
    if($dot["installs"]) {
      if($dot["installs"].GetType().Name -Eq "String") {
        $dot["installs"] = @{
          "cmd" = $dot["installs"]
          "depends" = @()
        }
      }
      if($dot["installs"]["depends"]) {
        if($dot["installs"]["depends"].GetType().Name -Eq "String") {
          $dot["installs"]["depends"] = @($dot["installs"]["depends"])
        }
      }
    }
    if($dot["links"]) {
      if($dot["links"].GetType().Name -Eq "String") {
        $dot["links"] = @($dot["links"])
        $dot["links"].Keys | ForEach-Object {
          if($dot["links"][$_].GetType().Name -Eq "String") {
            $dot["links"][$_] = @($dot["links"][$_])
          }
        }
      }
    }
    if($dot["updates"]) {
      if($dot["updates"].GetType().Name -Eq "String") {
        $dot["updates"] = @{
          "cmd" = $dot["updates"].Clone()
          "depends" = @()
        }
      }
      if($dot["updates"]["depends"]) {
        if($dot["updates"]["depends"].GetType().Name -Eq "String") {
          $dot["updates"]["depends"] = @($dot["updates"]["depends"])
        }
      }
    }
    return $dot
  }

  if($dot["windows"] -or $dot["linux"] -or $dot["darwin"] -or $dot["global"]) {
    if($dot["windows"]) {
      $dot["windows"] = EnlargeSingle($dot["windows"])
    }

    if($dot["linux"]) {
      $dot["linux"] = EnlargeSingle($dot["linux"])
    }

    if($dot["darwin"]) {
      $dot["darwin"] = EnlargeSingle($dot["darwin"])
    }

    if($dot["global"]) {
      $dot["global"] = EnlargeSingle($dot["global"])
    }
  } else {
    $dot = EnlargeSingle($dot)
  }

  return $dot
}

Function PackageAction($dots, $name, $action) {
  $packageaction = $dots[$name]["$action"]
  $depends = $dots[$name]["depends"]

  if(($packageaction["packageactiondone"]) -Or ($packageaction["error"])) {
    Return
  }

  if(($packageaction["depended"] -Gt 1) -Or ($dots[$name]["depended"] -Gt 1)) {
    Write-Host "detected circular dependency for $name" -ForegroundColor Red
    Return
  }
  if($packageaction["depends"]) {
    $packageaction["depends"] | ForEach-Object {
      $dots[$_]["$action"]["depended"] += 1
      PackageAction $dots $_ $action
    }
  }

  switch ($action) {
    "updates" { 
      Write-Host "updating $name"
     }
     "installs" { 
       Write-Host "installing $name"
    }
  }

  Invoke-Expression $packageaction["cmd"]

  $dots[$name]["$action"]["packageactiondone"] = $true

  if($depends) {
    $depends | ForEach-Object {
      $dots[$_]["depended"] += 1
      PackageAction $dots $_ $action
    }
  }

  Write-Host ""
}

Function Updates($dots, $name) {
  PackageAction $dots $name "updates"
}

Function Installs($dots, $name) {
  PackageAction $dots $name "installs"
}

function Syncs($dotfiles, $path) {
  $changes = @{ }

  if($Dotfiles.Contains("*") -Or $Dotfiles.Contains("dots.yaml")) {
    Invoke-Expression "git -C $(Resolve-Path $path) add dots.yaml -v" | ForEach-Object {
      $changes[$_.Split(" ")[1].Trim("'").Split("/")[0]] = $true
    }
  }

  $dotfiles.Split(" ") | ForEach-Object {
    Invoke-Expression "git -C $(Resolve-Path $path) add $_/* -v" | ForEach-Object {
      $changes[$_.Split(" ")[1].Trim("'").Split("/")[0]] = $true
    }
  }

  if($changes.Count -Ne 0) {
    $message = ""
    $changes.Keys | ForEach-Object {
      $message += "update $_. "
    }
    Invoke-Expression "git -C $(Resolve-Path $path) commit -m `"$message`""
  }

  Invoke-Expression "git -C $(Resolve-Path $path) pull"
  Invoke-Expression "git -C $(Resolve-Path $path) push"
}

Function Links($dots, $name) {
  Write-Host "linking $name"
  $links = $dots[$name]["links"]
  $links.Keys | ForEach-Object {
    $Key = $_
    $links[$Key] | ForEach-Object {
      Write-Host "  $Key -> $_"

      New-Item -ItemType $LinkType -Force -Path $_ -Target $(Resolve-Path $(Join-Path -Path $Path -ChildPath $(Join-Path -Path $name -ChildPath $Key))) | Out-Null
    }
  }
  Write-Host ""
}

Function Help() {
  Write-Error "not implemented"
}

Export-ModuleMember -Function dotfiler
