$Parameters = @{
    Server           = ""
    Database         = ""
    LogDirectory     = "C:\SQLLoadTest"
    ArchiveDirectory = "C:\SQLLoadTest\Archive"
}

Invoke-SqlLoadTestLogImport @Parameters