#
# Module manifest for module 'Dotted'
#

@{

RootModule = 'Dotted.psm1'

# Version number of this module.
ModuleVersion = '0.0.1'

# ID used to uniquely identify this module
GUID = '15299202-48fa-4b29-a3f7-7e744308f410'

# Author of this module
Author = 'Paul Volavsek'

# Description of the functionality provided by this module
Description = 'Cross platform dotfile managing and dev environment bootstrapping tool'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('powershell-yaml')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @('Link-Dots', 'Sync-Dots', 'Install-Dots', 'Update-Dots')
AliasesToExport = @('Link-Dot', 'Mount-Dots', 'Mount-Dot', 'Sync-Dot', 'Install-Dot', 'Update-Dot')

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

  PSData = @{

    # Tags applied to this module. These help with module discovery in online galleries.
    Tags = 'dotfile', 'dotfiles'

    # A URL to the license for this module.
    LicenseUri = 'https://github.com/volllly/Dotted/blob/master/LICENSE'

    # A URL to the main website for this project.
    ProjectUri = 'https://volllly.github.io/Dotted/'

    # External dependent modules of this module
    ExternalModuleDependencies = 'powershell-yaml'

  } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://volllly.github.io/Dotted/'

}

