<#
.Synopsis
Cross platform dotfile managing and dev environment bootstrapping tool.

.Description
Manages dotfiles based on a git repo.
Allows for automatic installation of the corresponding applications.

.Example
  # Install all dots.
  Install-Dots

.Example
  # Install some dots.
  Install-Dots vscode nodejs
#>
Function Install-Dots() {
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
    [String]$ConfigPath = "~/.config/dotted/config.y*ml"
  )

  $init = Init $Dots $Pull $DotfilesPath $ConfigPath
  $dotsData = $init.dotsData

  $dotsData.Keys | ForEach-Object {
    $name = $_
    if($Dots.Contains("*") -Or $Dots.Contains($name)) {
      PackageAction $dotsData $name "installs"
    }
  }
}

New-Alias -Name "Install-Dot" Install-Dots
Export-ModuleMember -Function Install-Dots -Alias Install-Dot
