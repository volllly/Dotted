<#
.Synopsis
Cross platform dotfile managing and dev environment bootstrapping tool.

.Description
Manages dotfiles based on a git repo.
Allows for automatic syncing of dotfiles with the repo .

.Example
  # Sync all dots with git repo.
  Sync-Dots

  .Example
  # Sync some dots with git repo.
  Sync-Dots git neovim
#>
function Sync-Dots() {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    # Execute for these dots.
    [String[]]$Dots = "*",

    # Specify dotfiles repo path. Read from config otherwise.
    [String]$DotfilesPath = $null,
    
    # Specify config file path. Use default path "~/.config/dotted/config.yaml" otherwise. Creates default config if none found.
    [String]$ConfigPath = "~/.config/dotted/config.y*ml"
  )

  $init = Init $Dots $Pull $DotfilesPath $ConfigPath
  $DotfilesPath = $init.DotfilesPath

  $changes = @{ }

  Write-Host "syncing dotfiles"
  
  if($Dots.Contains("*") -Or $Dots.Contains("dots.yaml")) {
    Invoke-Expression "git -C $(Resolve-Path $DotfilesPath) add dots.yaml -v" | ForEach-Object {
      $changes[$_.Split(" ")[1].Trim("'").Split("/")[0]] = $true
    }
  }

  $Dots.Split(" ") | ForEach-Object {
    Invoke-Expression "git -C $(Resolve-Path $DotfilesPath) add `"$_/*`" -v" | ForEach-Object {
      $changes[$_.Split(" ")[1].Trim("'").Split("/")[0]] = $true
    }
  }

  if($changes.Count -Ne 0) {
    $message = ""
    $changes.Keys | ForEach-Object {
      $message += "update $_. "
    }
    Invoke-Expression "git -C $(Resolve-Path $DotfilesPath) commit -m `"$message`""
  }

  Invoke-Expression "git -C $(Resolve-Path $DotfilesPath) pull"
  Invoke-Expression "git -C $(Resolve-Path $DotfilesPath) push"
}

New-Alias -Name "Sync-Dot" Sync-Dots
Export-ModuleMember -Function Sync-Dots -Alias Sync-Dot
