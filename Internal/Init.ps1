function Init($Dots, $Pull, $DotfilesPath, $ConfigPath) {
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

    New-Item -Path $($ConfigPath.replace("y*ml", "yaml")) -ItemType File -Value $(ConvertTo-Yaml -Data $config) -Force
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
  
  if($Dots) {
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

      if((!$currentFile) -or (!(Test-Path $currentFile))) {
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
  }
  return @{
    "config"       = $config;
    "dotsData"     = $dotsData;
    "DotfilesPath" = $DotfilesPath
  }
}
