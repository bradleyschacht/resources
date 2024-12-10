function Get-FabricFilterHashtable {
    param (
        [Parameter(Mandatory = $true)] [hashtable] $InputHashtable
    )

    [hashtable] $OutputHashtable = @{}

    $InputHashtable.Keys | ForEach-Object {
        if ($InputHashtable[$_] -ne "" -and $null -ne $InputHashtable[$_]) {
            $OutputHashtable.Add($_, $InputHashtable[$_])
        }
    }

    $OutputHashtable
}