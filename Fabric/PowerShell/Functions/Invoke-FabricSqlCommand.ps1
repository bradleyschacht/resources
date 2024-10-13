function Invoke-FabricSqlCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Server,
        [Parameter(Mandatory = $true)] [string] $Database,
        [Parameter(Mandatory = $true)] [string] $Query,
        [Parameter(Mandatory = $false)] [string] $AccessToken
    )

    if ([string]::IsNullOrEmpty($AccessToken)) { 
        $AccessToken = Get-FabricAccessToken -ResourceType "SQL"
    }
    
    $global:MessageOutput = @()
    $global:ErrorOutput = @()

    $ConnectionStringBuilder = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder
    $ConnectionStringBuilder["Server"] = $Server
    $ConnectionStringBuilder["Database"] = $Database
    $ConnectionStringBuilder["Connection Timeout"] = 60
    $ConnectionString = $ConnectionStringBuilder.ToString()
    
    $EventHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
        param (
            $Sender,
            $Event
        )
        $global:MessageOutput += $Event.Message
    };
    $Connection = New-Object System.Data.SqlClient.SQLConnection($ConnectionString)
    $Connection.ConnectionString = $ConnectionString
    $Connection.AccessToken = $AccessToken
    $Connection.Add_InfoMessage($EventHandler);
    $Connection.FireInfoMessageEventOnUserErrors = $false; #Changed this to false so errors actually thorw errors.
    $Connection.Open()

    $Command = New-Object System.Data.SqlClient.SqlCommand($Query, $Connection)
    $Command.CommandTimeout = 0
    $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
    $Dataset = New-Object System.Data.DataSet
    $QueryStartTime = (Get-Date)
    try {
        $Adapter.Fill($Dataset) | Out-Null
    }
    catch {
        $global:ErrorOutput += $_.Exception.Message
    }
    finally {
        $Connection.Close()
    }
    $QueryEndTime = (Get-Date)
    $QueryExecutionTime = $QueryEndTime - $QueryStartTime

    return [ordered] @{
        "Dataset"               = $Dataset
        "Messages"              = $MessageOutput
        "Errors"                = $ErrorOutput
        "QueryStartTime"        = $QueryStartTime
        "QueryEndTime"          = $QueryEndTime
        "QueryExecutionTime"    = $QueryExecutionTime
    }
}