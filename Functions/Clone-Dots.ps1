<#
.Synopsis
Cross platform dotfile managing and dev environment bootstrapping tool.

.Description
Manages dotfiles based on a git repo.
Clones toe repo to a local directory.

.Example
  # Clone repo to default directory.
  Clone-Dots

.Example
  # Clone repo.
  Clone-Dots -DotfilesPath ~/.dotfiles
#>
Function Clone-Dots() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    # Url to the dotfiles repository.
    [String[]]$RepoUrl,

    # Specify dotfiles repo path. Read from config otherwise.
    [String]$DotfilesPath = $null,
    
    # Specify config file path. Use default path "~/.config/dotted/config.yaml" otherwise. Creates default config if none found.
    [String]$ConfigPath = "~/.config/dotted/config.y*ml"
  )

  $init = Init $Dots $Pull $DotfilesPath $ConfigPath
  $DotfilesPath = $init.DotfilesPath

  New-Item -ItemType Directory -Path $DotfilesPath
  Invoke-Expression "git clone `"$RepoUrl`" `"$(Resolve-Path $DotfilesPath)`""
}

New-Alias -Name "Connect-Dots" Clone-Dots
Export-ModuleMember -Function Clone-Dots -Alias Connect-Dots
