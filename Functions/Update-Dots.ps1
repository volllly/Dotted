<#
.Synopsis
Cross platform dotfile managing and dev environment bootstrapping tool.

.Description
Manages dotfiles based on a git repo.
Allows for automatic installation of the corresponding applications.

.Example
  # Update all dots.
  Update-Dots

.Example
  # Update some dots.
  Update-Dots vscode nodejs
#>
Function Update-Dots() {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
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
      PackageAction $dotsData $name "updates"
    }
  }
}

New-Alias -Name "Update-Dot" Update-Dots
Export-ModuleMember -Function Update-Dots -Alias Update-Dot
