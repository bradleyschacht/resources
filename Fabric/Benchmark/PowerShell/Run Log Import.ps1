$Parameters = @{
    Server           = ""
    Database         = ""
    LogDirectory     = "C:\BenchmarkOutput"
    ArchiveDirectory = "C:\BenchmarkOutput\Archive"
}

Invoke-FabricBenchmarkLogImport @Parameters