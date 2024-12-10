function Get-FabricAccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] [ValidateSet("Azure", "Fabric", "SQL")] [string] $ResourceType = "Fabric"
    )

    $ResourceUrl = switch ($ResourceType) {
        "Azure"     {"https://management.azure.com"}
        "Fabric"    {"https://api.fabric.microsoft.com"}
        "SQL"       {"https://database.windows.net/"}
    }

    (Get-AzAccessToken -ResourceUrl $ResourceUrl -AsSecureString).Token | ConvertFrom-SecureString -AsPlainText
}