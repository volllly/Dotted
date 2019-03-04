Import-Module powershell-yaml
Import-Module Poshstache

<#
  .Synopsis
  Manages your dotfiles from a git repo.

  .Description
  Automatically clones and links your dotfiles.
  Automatically installs and updates your applications.

  .Parameter Command
#>

Function Mount-Dotfiles {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,Position=0)]
    [ValidateSet("Install", "Update", "Link", "Sync", "Setup", "Help")]
    $Command = "Help",
    [Switch]$NoUpdate = $False,
    [Switch]$NoLink = $False,
    [Switch]$NoInstall = $False,
    [Switch]$Pull = $False,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [ValidateSet("SymbolicLink", "HardLink")]
    $LinkType = "HardLink",
    [Parameter(Mandatory=$True,ValueFromRemainingArguments=$True)]
    [String[]] $Dotfiles
  )

  $cfg = @{}

  Get-ChildItem $PSScriptRoot -Directory | ForEach-Object {
    $currentDirectory = $_
    $currentName = Split-Path $currentDirectory -Leaf
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

  If($Pull) {
    Write-Host "Pulling from git remote"
    Invoke-Expression "git pull"
    Write-Host ""
  }

  Function Installs($name) {
    $installs = $cfg[$name]["installs"]
    $depends = $cfg[$name]["depends"]

    If(($installs["installed"]) -Or ($installs["error"])) {
      Return
    }

    If(($installs["depended"] -Gt 1) -Or ($cfg[$name]["depended"] -Gt 1)) {
      Write-Host "detected circular dependency for $name" -ForegroundColor Red
      Return
    }
    If($installs["depends"]) {
      $installs["depends"] | ForEach-Object {
      $cfg[$_]["installs"]["depended"] += 1
      Installs $_
      }
    }

    Write-Host "installing $name"

    Invoke-Expression $installs["cmd"]

    $cfg[$name]["installs"]["installed"] = $True

    If($depends) {
      $depends | ForEach-Object {
        $cfg[$_]["depended"] += 1
        Installs $_
      }
    }

    Write-Host ""
  }

  Function Links($name) {
    Write-Host "linking $name"
    $links = $cfg[$name]["links"]
    $links.Keys | ForEach-Object {
      $Key = $_
      $links[$Key] | ForEach-Object {
        Write-Host "  $Key -> $_"
        New-Item -Path $_ -ItemType $LinkType -Value $(Join-Path -Path $PSScriptRoot -ChildPath $(Join-Path -Path $name -ChildPath $Key)) -Force | Out-Null
      }
    }
    Write-Host ""
  }

  Function Upadtes($name) {
    Write-Host "linking $name"
    $updates = $cfg[$name]["updates"]

    Invoke-Expression $updates

    Write-Host ""
  }

  Function Syncs($path) {
    $changes = @{}

    Invoke-Expression "git add $path/* -v" | ForEach-Object {
      $changes[$_.Split(" ")[1].Trim("'").Split("/")[0]] = $True
    }

    If($changes.Count -Ne 0) {
      $message = ""
      $changes.Keys | ForEach-Object {
        $message = "Update $_."
      }
      Invoke-Expression "git commit -m `"$message`""
    }

    Invoke-Expression "git pull"
    Invoke-Expression "git push"
  }

  Function Help() {
    Write-Error "not implemented"
  }

  Switch($Command) {
    "Sync" {
      Syncs $Dotfiles
    }
    default {
      $cfg.Keys | ForEach-Object {
        $name = $_
        If($Dotfiles.Contains("*") -Or $Dotfiles.Contains($name)) {
          Switch($Command) {
            "Install" {
              If($cfg[$name]["links"] -And !($NoLink)) {
                Links $name
              }
              If($cfg[$name]["installs"] -And !($NoInstall)) {
                Installs $name
              }
            }
            "Update" {
              If($cfg[$name]["links"] -And !($NoLink)) {
                Links $name
              }
              If($cfg[$name]["updates"] -And !($NoUpdate)) {
                Updates $name
              }
            }
            "Link" {
              If($cfg[$name]["links"] -And !($NoLinks)) {
                Links $name
              }
            }
            "help" {
              Help
            }
            default {
              Help
            }
          }
        }
      }
    }
  }
}
