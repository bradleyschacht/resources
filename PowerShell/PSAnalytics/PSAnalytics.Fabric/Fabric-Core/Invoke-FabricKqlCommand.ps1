function Invoke-FabricKqlCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $KustoQueryURI,
        [Parameter(Mandatory = $true)] [string] $Database,
        [Parameter(Mandatory = $true)] [string] $Query,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = (Get-AzAccessToken -ResourceUrl $KustoQueryURI -AsSecureString).Token | ConvertFrom-SecureString -AsPlainText
    }

    # Load the Kusto tools.
    $KustoPackage = Get-Package Microsoft.Azure.Kusto.Tools

    if($KustoPackage.Source) {
    }
    else {
        $null = Register-PackageSource -Name nuget.org -Location http://www.nuget.org/api/v2 -Force -Trusted -ProviderName NuGet;
        Install-Package Microsoft.Azure.Kusto.Tools -ProviderName NuGet -Force -Scope CurrentUser
        $KustoPackage = Get-Package Microsoft.Azure.Kusto.Tools
    }

    $null = [System.Reflection.Assembly]::LoadFrom((Join-Path -Path (Split-Path $KustoPackage.Source) -ChildPath "\tools\net8.0\Kusto.Data.dll"))

    # Create the Kusto connection string. 
    $KustoConnectionString = New-Object Kusto.Data.KustoConnectionStringBuilder ($KustoQueryURI)
    $KustoConnectionString.'Initial Catalog' = $Database
    $KustoConnectionString.'User Token' = $AccessToken.ToString() <#= $KustoConnectionString.WithAadUserTokenAuthentication($AccessToken).'User Token'#>

    # Create the query provider.
    $QueryProvider = [Kusto.Data.Net.Client.KustoClientFactory]::CreateCslQueryProvider($KustoConnectionString)

    # Set the properties for the request (optional).
    <#
    $RequestProperties = New-Object Kusto.Data.Common.ClientRequestProperties
    $RequestProperties.ClientRequestId = "MyPowershellScript.ExecuteQuery." + [Guid]::NewGuid().ToString()
    $RequestProperties.SetOption([Kusto.Data.Common.ClientRequestProperties]::OptionServerTimeout, [TimeSpan]::FromSeconds(30))
    #>

    # Run the query and parse out the results table.
    $QueryResults = $QueryProvider.ExecuteQuery($Query) #, $RequestProperties)
    $ResultsTable = [Kusto.Cloud.Platform.Data.ExtendedDataReader]::ToDataSet($QueryResults).Tables[0]
    $Dataset = New-Object System.Data.DataView($ResultsTable)

    return $Dataset | Select-Object * -ExcludeProperty Error, RowVersion, Row, DataView, IsNew, IsEdit, RequireRegisteredTypes
}