@{
  ModuleVersion = "0.0.0"
  RequiredModules = @(
    "powershell-yaml",
    "Poshstache"
  )
  NestedModules = @(
    "./src/public/Mount-Dotfiles.ps1"
  )
  FunctionsToExport = @("*")
}


# "./src/Initialize-Dotfiles.ps1",
# "./src/Import-Dotfiles.ps1",
# "./src/Export-Dotfiles"
# "./src/Update-Dotfiles.ps1",
# "./src/Sync-Dotfiles.ps1",
# "./src/Mount-Dotfiles.ps1",
# "./src/Dismount-Dotfiles.ps1",
# "./src/Install-Dotfiles.ps1"
