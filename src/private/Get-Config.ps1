Function Get-Config {
  Import-Module $PSScriptRoot/Find-Config.ps1
  Import-Module powershell-yaml
  Import-Module Poshstache
  
  $cfg = @{}
  $cfgDirectory = Find-Config

  Get-ChildItem $cfgDirectory -Directory | ForEach-Object {
    $currentName = $currentDirectory
    $currentDirectory = Join-Path $cfgDirectory -ChildPath $_
    $cfgfile = ''
    $currentFile = $(Join-Path -Path $currentDirectory -ChildPath "dot.yaml")

    If(!(Test-Path $currentFile)) {
      Return
    }
    
    foreach ($line In Get-Content $currentFile) { $cfgfile += "`n" + $line }
    $cfg[$currentName] = ConvertFrom-YAML $cfgfile
    If($cfg[$currentName]["installs"]) {
      If($cfg[$currentName]["installs"].GetType().Name -Eq "String") {
        $cfg[$currentName]["installs"] = @{ "cmd" = $cfg[$currentName]["installs"]}
      }
      If($cfg[$currentName]["installs"]["depends"]) {
        If($cfg[$currentName]["installs"]["depends"].GetType().Name -Eq "String") {
          $cfg[$currentName]["installs"]["depends"] = @($cfg[$currentName]["installs"]["depends"])
        }
      }
      $cfg[$currentName]["installs"]["installed"] = $False
    }
    If($cfg[$currentName]["links"]) {
      If($cfg[$currentName]["links"].GetType().Name -Eq "String") {
        $cfg[$currentName]["links"] = @($cfg[$currentName]["links"])
          
      }
    }
  }

  Write-Host $cfg["scoop"]
  Return $cfg
}
