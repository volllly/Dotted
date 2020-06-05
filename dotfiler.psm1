<#
.Synopsis
Cross platform dotfile managing and dev environment bootstrapping tool.

.Description
Manages dotfiles based on a git repo.
Allows for automatic linking of dotfiles fro the repo to the correct paths.
Allows for automatic installation and updating of the corresponding applications.

.Example
  # Link all dots.
  dotfiler link

.Example
  # Link some dots and pull dotfiles.
  dotfiler link -pull git neovim

.Example
  # Install some dots.
  dotfiler install vscode nodejs

.Example
  # Update all dots but do not link.
  dotfiler update -no-link

.Example
  # Sync all dots with git repo.
  dotfiler sync
#>
function dotfiler() {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("install", "update", "link", "sync")]
    # Subcommand to execute.
    [String]$Command,
    
    [Parameter(ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
    # Execute for these dots.
    [String[]]$Dots = "*",

    [Alias("p")]
    # Pull dotfiles from repo.
    [Switch]$Pull = $false,

    [Alias("no-link", "nl")]
    # Do not link dots.
    [Switch]$NoLink = $false,

    # Specify dotfiles repo path. Read from config otherwise.
    [String]$DotfilesPath = $null,
    
    # Specify config file path. Use default path "~/.config/dotfiler/config.yaml" otherwise. Creates default config if none found.
    [String]$ConfigPath = "~/.config/dotfiler/config.y*ml",
    
    [ValidateSet("SymbolicLink", "HardLink")]
    [Alias("l")]
    # Specify wich linktype to use. Default is Hardlink.
    [String]$LinkType = "HardLink"
  )

  Import-Module powershell-yaml

  $config = @{ }
  if(Test-Path $ConfigPath) {
    $rawConfig = ""
    foreach ($line in Get-Content $(Resolve-Path $ConfigPath)) { $rawConfig += "`n" + $line }
    $config = ConvertFrom-Yaml $rawConfig
  } else {
    $config = @{
      "path" = "~/.dotfiles"
    };

    ConvertTo-Yaml -Data $config -OutFile $ConfigPath
  }

  if(!$DotfilesPath) {
    $DotfilesPath = $config["path"]
  }

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

  
  if($Pull -and ($Command -ne "Sync")) {
    Invoke-Expression "git -C $(Resolve-Path $DotfilesPath) pull"
    Write-Host ""
  }

  $dotsData = @{ }
  $dotsDefault = @{ }

  $rawDot = ""
  $currentFile = $(Join-Path -Path $DotfilesPath -ChildPath "dots.y*ml")

  if(!(Test-Path $currentFile)) {
    Write-Error "Did Not find dots.yaml"
    Return
  }

  foreach ($line in Get-Content $currentFile) { $rawDot += "`n" + $line }
  $dotsDefault = ConvertFrom-Yaml $rawDot

  
  $dotsDefault = ResolveOs $dotsDefault $os

  $dotsDefault = Enlarge $dotsDefault

  Get-ChildItem $DotfilesPath -Directory | ForEach-Object {
    $currentDirectory = Join-Path -Path $DotfilesPath -ChildPath $_.Name
    $currentName = $_.Name
    $rawDot = ""
    $currentFile = $(Resolve-Path $(Join-Path -Path $currentDirectory -ChildPath "dot.y*ml"))

    if(!(Test-Path $currentFile)) {
      Return
    }
    
    foreach ($line in Get-Content $currentFile) { $rawDot += "`n" + $line }


    $dotsData[$currentName] = ConvertFrom-Yaml $rawDot

    if(!($dotsData[$currentName])) {
      $dotsData[$currentName] = @{ }
    }

    $dotsData[$currentName] = Enlarge $dotsData[$currentName]
    
    $dotsData[$currentName] = ResolveOs $dotsData[$currentName] $os

    if($null -eq $dotsData[$currentName]) { $dotsData[$currentName] = @{ } }

    if($dotsData[$currentName]) {
      $dotsData[$currentName] = Merge $dotsDefault $dotsData[$currentName].Clone()
    }

    if(!($dotsData[$currentName])) {
      $dotsData.Remove($currentName)
      return
    }

    if($dotsData[$currentName]["installs"]) {
      $dotsData[$currentName]["installs"]["cmd"] = $dotsData[$currentName]["installs"]["cmd"] | Merge-Tokens -Tokens @{
        name = $currentName
      }
    }

    if($dotsData[$currentName]["updates"]) {
      $dotsData[$currentName]["updates"]["cmd"] = $dotsData[$currentName]["updates"]["cmd"] | Merge-Tokens -Tokens @{
        name = $currentName
      }
    }
  }

  switch($Command) {
    "Sync" {
      Syncs $Dots $DotfilesPath
    }
    default {
      $dotsData.Keys | ForEach-Object {

        $name = $_
        if($Dots.Contains("*") -Or $Dots.Contains($name)) {
          switch($Command) {
            "install" {
              if($dotsData[$name]["links"] -And !($NoLink)) {
                Links $dotsData $name
              }
              if($dotsData[$name]["installs"]) {
                Installs $dotsData $name
              }
            }
            "update" {
              if($dotsData[$name]["links"] -And !($NoLink)) {
                Links $dotsData $name
              }
              if($dotsData[$name]["updates"]) {
                Updates $dotsData $name
              }
            }
            "link" {
              if($dotsData[$name]["links"] -And !($NoLinks)) {
                Links $dotsData $name
              }
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
    if($object[$key].Clone) {
      $new[$key] = $object[$key].Clone()
    } else {
      $new[$key] = $object[$key]
    }
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
  $keys = @{
    "windows" = $dot.Keys | Where-Object { $_ -match '[a-z|]*windows[a-z|]*' };
    "linux"   = $dot.Keys | Where-Object { $_ -match '[a-z|]*linux[a-z|]*' };
    "darwin"  = $dot.Keys | Where-Object { $_ -match '[a-z|]*darwin[a-z|]*' };
  }

  if($keys["windows"] -or $keys["linux"] -or $keys["darwin"] -or $dot.ContainsKey("global")) {
    if($keys[$os] -or $dot.ContainsKey("global")) {
      
      if($dot.ContainsKey("global")) {
        $dotOs = $dot["global"]
      } else {
        $dotOs = @{ }
      }
      
      foreach($key in $keys[$os]) {
        $dotOs = Merge $dotOs $dot[$key]
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
          "cmd"     = $dot["installs"]
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
          "cmd"     = $dot["updates"].Clone()
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

Function PackageAction($dotsData, $name, $action) {
  $packageaction = $dotsData[$name][$action]
  $depends = $dotsData[$name]["depends"]

  if(($packageaction["packageactiondone"]) -Or ($packageaction["error"])) {
    Return
  }

  if(($packageaction["depended"] -Gt 1) -Or ($dotsData[$name]["depended"] -Gt 1)) {
    Write-Host "detected circular dependency for $name" -ForegroundColor Red
    Return
  }
  if($packageaction["depends"]) {
    $packageaction["depends"] | ForEach-Object {
      if(!$dotsData[$_]) {
        Write-Error "Could not find dependency `"$_`" for `"$name`""
        exit
      }
      if(!$dotsData[$_][$action]) {
        Write-Error "Could not find `"$action`" for dependency `"$_`" for `"$name`""
        exit
      }
      $dotsData[$_][$action]["depended"] += 1
      PackageAction $dotsData $_ $action
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

  $dotsData[$name][$action]["packageactiondone"] = $true

  if($depends) {
    $depends | ForEach-Object {
      $dotsData[$_]["depended"] += 1
      PackageAction $dotsData $_ $action
    }
  }

  Write-Host ""
}

function Merge-Tokens() {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
    [AllowEmptyString()]
    [String] $template,

    [Parameter(Mandatory = $true)]
    [HashTable] $tokens
  ) 
  try {

    [regex]::Replace( $template, '{{ *(?<tokenName>[\w\.]+) *}}', {
        param($match)
        $value = Invoke-Expression "`$tokens.$($match.Groups['tokenName'].Value)"

        if($value) {
          return $tokenValue
        } else {
          return $match
        }
      })

  } catch {
    Write-Error $_
  }
} 

Function Updates($dotsData, $name) {
  PackageAction $dotsData $name "updates"
}

Function Installs($dotsData, $name) {
  PackageAction $dotsData $name "installs"
}

function Syncs($dotsData, $path) {
  $changes = @{ }

  if($dotsData.Contains("*") -Or $dotsData.Contains("dots.yaml")) {
    Invoke-Expression "git -C $(Resolve-Path $path) add dots.yaml -v" | ForEach-Object {
      $changes[$_.Split(" ")[1].Trim("'").Split("/")[0]] = $true
    }
  }

  $dotsData.Split(" ") | ForEach-Object {
    Invoke-Expression "git -C $(Resolve-Path $path) add `"$_/*`" -v" | ForEach-Object {
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

Function Links($dotsData, $name) {
  Write-Host "linking $name"
  $links = $dotsData[$name]["links"]
  $links.Keys | ForEach-Object {
    $Key = $_
    $links[$Key] | ForEach-Object {
      Write-Host "  $Key -> $_"

      New-Item -ItemType $LinkType -Force -Path $_ -Target $(Resolve-Path $(Join-Path -Path $DotfilesPath -ChildPath $(Join-Path -Path $name -ChildPath $Key))) | Out-Null
    }
  }
  Write-Host ""
}

Export-ModuleMember -Function dotfiler
