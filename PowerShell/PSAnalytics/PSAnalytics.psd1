@{
    # Version number of this module.
    ModuleVersion = '2025.1.16.0'
    
    # ID used to uniquely identify this module
    GUID = 'aedb5772-a962-4260-9cda-e97266967467'
    
    # Author of this module
    Author = 'Bradley Schacht | https://bradleyschacht.com'
    
    # Description of the functionality provided by this module
    Description = ''
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @('.\PSAnalytics.Fabric', '.\PSAnalytics.SQLLoadTest')

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @('')

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    # FunctionsToExport = @('')
}