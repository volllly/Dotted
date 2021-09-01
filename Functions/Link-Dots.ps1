<#
.Synopsis
Cross platform dotfile managing and dev environment bootstrapping tool.

.Description
Manages dotfiles based on a git repo.
Allows for automatic linking of dotfiles from the repo to the correct paths.

.Example
  # Link all dots.
  Link-Dots

.Example
  # Link some dots and pull dotfiles.
  Link-Dots -Pull git neovim
#>
Function Link-Dots() {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    # Execute for these dots.
    [String[]]$Dots = "*",

    [Alias("p")]
    # Pull dotfiles from repo.
    [Switch]$Pull = $false,

    # Specify dotfiles repo path. Read from config otherwise.
    [String]$DotfilesPath = $null,
    
    # Specify config file path. Use default path "~/.config/dotted/config.yaml" otherwise. Creates default config if none found.
    [String]$ConfigPath = "~/.config/dotted/config.y*ml",
    
    [ValidateSet("SymbolicLink", "HardLink")]
    [Alias("l")]
    # Specify wich linktype to use. Default is Hardlink.
    [String]$LinkType = "HardLink"
  )

  $init = Init $Dots $Pull $DotfilesPath $ConfigPath
  $dotsData = $init.dotsData
  $DotfilesPath = $init.DotfilesPath

  $dotsData.Keys | ForEach-Object {
    $name = $_
    if($Dots.Contains("*") -Or $Dots.Contains($name)) {
      $links = $dotsData[$name]["links"]
      if(!$links) { return; }
      Write-Host "linking $name"
      $links.Keys | ForEach-Object {
        $Key = $_
        $links[$Key] | ForEach-Object {
          Write-Host "  $Key -> $_"

          if((Test-Path -Path $(Resolve-Path $(Join-Path -Path $DotfilesPath -ChildPath $(Join-Path -Path $name -ChildPath $Key))) -PathType Container) -and ($LinkType -eq "HardLink")) {
            New-Item -ItemType "Junction" -Force -Path $_ -Target $(Resolve-Path $(Join-Path -Path $DotfilesPath -ChildPath $(Join-Path -Path $name -ChildPath $Key))) | Out-Null
          } else {
            New-Item -ItemType $LinkType -Force -Path $_ -Target $(Resolve-Path $(Join-Path -Path $DotfilesPath -ChildPath $(Join-Path -Path $name -ChildPath $Key))) | Out-Null
          }
        }
      }
      Write-Host ""
    }
  }
}

New-Alias -Name "Link-Dot" Link-Dots
New-Alias -Name "Mount-Dot" Link-Dots
New-Alias -Name "Mount-Dots" Link-Dots

Export-ModuleMember -Function Link-Dots -Alias @('Link-Dot', 'Mount-Dot', 'Mount-Dots')
