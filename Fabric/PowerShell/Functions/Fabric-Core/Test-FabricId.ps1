function Test-FabricId {
    param (
        [Parameter(Mandatory)]
        [string]$String
    )
    
    $Pattern = "[\w-]{8}-[\w-]{4}-[\w-]{4}-[\w-]{4}-[\w-]{12}"
    
    if (($String | Select-String -Pattern $Pattern).Matches) {
        $true
    }
    else {
        $false
    }
}