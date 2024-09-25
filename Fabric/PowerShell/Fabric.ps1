function Find-FabricId {
    param (
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


function Get-FabricAccessToken {
    param (
        [string]$ResourceType
    )

    $ResourceUrl = switch ($ResourceType) {
        "Azure"     {"https://management.azure.com"}
        "Fabric"    {"https://api.fabric.microsoft.com"}
        "SQL"       {"https://database.windows.net/"}
    }

    if ($ResourceUrl) {
        (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token
    }

}


function Get-FabricWorkspaceList {
    param (
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces"
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    (Invoke-RestMethod -Uri $Uri -Method GET -Headers $Headers).value

}


function Get-FabricWorkspace {
    param (
        [string]$Workspace,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    if(!(Find-FabricID -String $Workspace)) {
        $WorkspaceID = (Get-FabricWorkspaceList -AccessToken $AccessToken | Where-Object {$_.displayName -eq $Workspace}).id
    }
    else {
        $WorkspaceID = $Workspace
    }
        
    if($WorkspaceID) {
        $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}" -f $WorkspaceID
        $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
        Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
    }

}


function Get-FabricItemList {
    param (
        [string]$Workspace,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id
    
    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/items" -f $WorkspaceID
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    (Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers).value

}


function Get-FabricItem {
    param (
        [string]$Workspace,
        [string]$Item,
        [string]$ItemType = $null,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    if(!(Find-FabricID -String $Item)) {
        if(!$ItemType) {
            throw "The -ItemType parameter is required when providing an Item name. Include the -ItemType parameter or pass an id to the -Item parameter."

        }
        else {
            $ItemID = (Get-FabricItemList -Workspace $WorkspaceID -AccessToken $AccessToken | Where-Object {$_.displayName -eq $Item -and $_.type -eq $ItemType}).id
        }
    }
    else {
        $ItemID = $Item
    }

    if($ItemID) {
        $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/items/{1}" -f $WorkspaceID, $ItemID
        $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
        Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
    }

}


function Get-FabricCapacityList {
    param (
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }
    
    $Uri        = "https://api.fabric.microsoft.com/v1/capacities"
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    (Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers).value

}


function Get-FabricLakehouse {
    param (
        [string]$Workspace,
        [string]$Lakehouse,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id
    
    if(!(Find-FabricID -String $Lakehouse)) {
        $LakehouseID = (Get-FabricItem -Workspace $WorkspaceID -Item $Lakehouse -ItemType "Lakehouse" -AccessToken $AccessToken).id
    }
    else {
        $LakehouseID = $Lakehouse
    }
    
    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/lakehouses/{1}" -f $WorkspaceID, $LakehouseID
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

}


function Get-FabricWarehouse {
    param (
        [string]$Workspace,
        [string]$Warehouse,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id

    if(!(Find-FabricID -String $Warehouse)) {
        $WarehouseID = (Get-FabricItem -Workspace $WorkspaceID -Item $Warehouse -ItemType "Warehouse" -AccessToken $AccessToken).id
    }
    else {
        $WarehouseID = $Warehouse
    }
    
    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses/{1}" -f $WorkspaceID, $WarehouseID
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
}


function Get-FabricSqlConnectionString {
    param (
        [string]$Workspace,
        [string]$Item,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    if(!(Find-FabricID -String $Workspace)) {
        $WorkspaceID = (Get-FabricWorkspaceList -AccessToken $AccessToken | Where-Object {$_.displayName -eq $Workspace}).id
    }
    else {
        $WorkspaceID = $Workspace
    }
        
    $Lakehouse = (Get-FabricLakehouse -Workspace $WorkspaceID -Lakehouse $Item -AccessToken $AccessToken).properties.sqlEndpointProperties.connectionString
    $Warehouse = (Get-FabricWarehouse -Workspace $WorkspaceID -Warehouse $Item -AccessToken $AccessToken).properties.connectionString

    if($null -ne $Lakehouse -and $Lakehouse -ne ""){
        $Lakehouse
    }
    elseif ($null -ne $Warehouse -and $Warehouse -ne "") {
        $Warehouse
    }
    else {
        "No connection string found."
    }
    
}


function Get-FabricCapacity {
    param (
        [string]$SubscriptionID,
        [string]$ResourceGroupName,
        [string]$CapacityName,
        [string]$AccessToken = $null,
        [string]$APIVersion = "2022-07-01-preview"

    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
    }
    
    $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken)}
    
    Invoke-RestMethod -Uri $Uri -Method GET -Headers $Headers

}


function Pause-FabricCapacity {
    param (
        [string]$SubscriptionID,
        [string]$ResourceGroupName,
        [string]$CapacityName,
        [string]$AccessToken = $null,
        [string]$APIVersion = "2022-07-01-preview"

    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
    }

    $Capacity = Get-FabricCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName -APIVersion $APIVersion
    
    if ($Capacity.properties.state -eq "Paused") {
        #Do nothing.
    }
    elseif ($Capacity.properties.state -eq "Active") {
        try {  
            $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}/suspend?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken)}
            $null = Invoke-RestMethod -Uri $Uri -Method POST -Headers $Headers
            
            Start-Sleep -Seconds 5

            do {
                $Capacity = Get-FabricCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName -APIVersion $APIVersion
                    
                if ($Capacity.properties.state -ne "Paused") {
                    Start-Sleep -Seconds 5
                }
            } until (
                $Capacity.properties.state -eq "Paused"
            )
        }
        catch {
            $_
        }
    }
    else {
        Write-Host "Capacity in an unknown state."
    }

    $Capacity
}


function Resume-FabricCapacity {
    param (
        [string]$SubscriptionID,
        [string]$ResourceGroupName,
        [string]$CapacityName,
        [string]$AccessToken = $null,
        [string]$APIVersion = "2022-07-01-preview"

    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
    }

    $Capacity = Get-FabricCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName -APIVersion $APIVersion
    
    if ($Capacity.properties.state -eq "Active") {
        #Do nothing.
    }
    elseif ($Capacity.properties.state -eq "Paused") {    
        try {
            $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}/resume?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken)}
            $null = Invoke-RestMethod -Uri $Uri -Method POST -Headers $Headers       

            Start-Sleep -Seconds 5

            do {
                $Capacity = Get-FabricCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName -APIVersion $APIVersion
                    
                if ($Capacity.properties.state -ne "Active") {
                    Start-Sleep -Seconds 5
                }
            } until (
                $Capacity.properties.state -eq "Active"
            )
        }
        catch {
            $_
        }
    }
    else {
        Write-Host "Capacity in an unknown state."
    }

    $Capacity

}


function Scale-FabricCapacity {
    param (
        [string]$SubscriptionID,
        [string]$ResourceGroupName,
        [string]$CapacityName,
        [string]$Sku,
        [string]$AccessToken = $null,
        [string]$APIVersion = "2022-07-01-preview"

    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
    }
        
    #Get the current SKU
    $Capacity = Get-FabricCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName
        
    if ($Capacity.sku.name -eq $Sku) {
        #Do nothing.
    }
    elseif ($Capacity.sku.name -ne $Sku) {
        try {
            $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
            $Body       = '{"sku": {"name": "' + $Sku + '"}}'
            $null = Invoke-RestMethod -Uri $Uri -Method Patch -Body $Body -Headers $Headers

            Start-Sleep -Seconds 5

            do {
                
                $Capacity = Get-FabricCapacity -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName -APIVersion $APIVersion

                if ($Capacity.sku.name -ne $Sku) {
                    Start-Sleep -Seconds 5
                }
            } until (
                $Capacity.sku.name -eq $Sku
            )        }
        catch {
            $_
        }
    }
    else {
        Write-Host "Capacity in an unknown state."
    }

    $Capacity

}


function Set-FabricWorkspaceCapacity {
    param (
        [string]$Workspace,
        [string]$Capacity,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceDetail = Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken
    $WorkspaceID = $WorkspaceDetail.id

    if(!(Find-FabricID -String $Capacity)) {
        $CapacityID = (Get-FabricCapacityList -AccessToken $AccessToken | Where-Object {$_.displayName -eq $Capacity}).id
    }
    else {
        $CapacityID = $Capacity
    }

    if($WorkspaceDetail.capacityId -eq $CapacityID) {
        #Do nothing.
    }
    elseif ($WorkspaceDetail.capacityId -ne $CapacityID) {
        try {
            $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/assignToCapacity" -f $WorkspaceID
            $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
            $Body       = '{"capacityId": "' + $CapacityID + '"}'
            $null = Invoke-RestMethod -Uri $Uri -Method POST -Body $Body -Headers $Headers
    
            Start-Sleep -Seconds 5        

            do {
                $WorkspaceDetail = Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken

                if ($WorkspaceDetail.capacityId -ne $CapacityID -or $WorkspaceDetail.CapacityAssignmentProgress -ne "Completed") {
                    Start-Sleep -Seconds 5
                }
            } until (
                $WorkspaceDetail.capacityId -eq $CapacityID -and $WorkspaceDetail.CapacityAssignmentProgress -eq "Completed"
            )
        }
        catch {
            $_
        }
    }
    else {
        Write-Host "Capacity or workspace in an unknown state."
    }

    $WorkspaceDetail
}


function Invoke-FabricSQLCommand {
    param (
        [string]$Server,
        [string]$Database,
        [string]$Query,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
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
    try {
        $Adapter.Fill($Dataset) | Out-Null
    }
    catch {
        $global:ErrorOutput += $_.Exception.Message
    }
    finally {
        $Connection.Close()
    }

    return @{
        "Dataset"   = $Dataset
        "Messages"  = $MessageOutput
        "Errors"    = $ErrorOutput
    }
}

function Prase-FabricSQLMessage
    ($Message) {
        
    #QueryHash
    $Pattern = "Query Hash: (?<QueryHash>0x\w+)"
    $Matches = ($Message | Select-String -Pattern $Pattern).Matches
    if ($Matches) {
        $QueryHash = $Matches[0].Groups['QueryHash'].Value
    }
    else {
        $QueryHash = $null
    }

    #RequestID
    $Pattern = "Distributed request ID: \{(?<DistributedRequestID>[\w-]+)\}"
    $Matches = ($Message | Select-String -Pattern $Pattern).Matches
    if ($Matches) {
        $DistributedRequestID = $Matches[0].Groups['DistributedRequestID'].Value
    }
    else {
        $DistributedRequestID = $null
    }
    
    #StatementID
    $Pattern = "Statement ID: \{(?<StatementID>[\w-]{36})\}"
    $Matches = ($Message | Select-String -Pattern $Pattern).Matches
    if ($Matches) {
        $StatementID = $Matches[0].Groups['StatementID'].Value
    }
    else {
        $StatementID = $null
    }

    return [ordered]@{
        "DistributedRequestID"  = $DistributedRequestID
        "Message"               = $Message
        "QueryHash"             = $QueryHash
        "StatementID"           = $StatementID
    }
}

function Get-FabricCapacityMetrics {
	param (
		[string]$CapacityMetricsDatasetID,	
		[string]$CapacityID,
		[string]$DistributedStatementIDList,
		[string]$QueryDate,
		[string]$AccessToken = $null
	)

	if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

	$Date = [datetime]$QueryDate

	$DaxQuery = "
	DEFINE
			
	MPARAMETER 'CapacityID' 	= \""{0}\""
	MPARAMETER 'TimePoint' 		= (DATE({2}, {3}, {4}) + TIME({5}, {6}, {7}))

	VAR __Var_CapacityId	= {{\""{0}\""}}
	VAR __Var_OperationId	= {{{1}}}

	VAR __Filter_OperationId 	= TREATAS(__Var_OperationId, 'TimePointBackgroundDetail'[OperationId])
	VAR __Filter_CapacityId 	= TREATAS(__Var_CapacityId, 'Capacities'[capacityId])

	VAR __DS0Core = 
		SUMMARIZECOLUMNS(
			'Items'[WorkspaceName],
			'Items'[ItemKind],
			'Items'[ItemName],
			'TimePointBackgroundDetail'[OperationStartTime],
			'TimePointBackgroundDetail'[OperationEndTime],
			'TimePointBackgroundDetail'[OperationId],
			__Filter_OperationId,
			__Filter_CapacityId,
			\""Sum_CUs\"", CALCULATE(SUM('TimePointBackgroundDetail'[Total CU (s)])),
			\""Sum_Duration\"", CALCULATE(SUM('TimePointBackgroundDetail'[Duration (s)]))
		)
		
	EVALUATE
	__DS0Core" -f $CapacityID, $DistributedStatementIDList, $Date.Year, $Date.Month, $Date.Day, $Date.Hour, $Date.Minute, $Date.Second

	$Uri = "https://api.powerbi.com/v1.0/myorg/datasets/{0}/executeQueries" -f $CapacityMetricsDatasetID
	$Headers = @{"Content-Type"="application/json"; Authorization=("Bearer {0}" -f ($AccessToken))}
	$Body = "{""queries"": [ {""query"": ""$DaxQuery""} ], ""serializerSettings"": {""includeNulls"": true}}"
	
	$Results = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $Body

    $Results.results.tables.rows | Select-Object name, @{Name='WorkspaceName'; Expression={ $_.'Items[WorkspaceName]' }}, @{Name='ItemKind'; Expression={ $_.'Items[ItemKind]' }}, @{Name='ItemName'; Expression={ $_.'Items[ItemName]' }}, @{Name='OperationStartTime'; Expression={ $_.'TimePointBackgroundDetail[OperationStartTime]' }}, @{Name='OperationEndTime'; Expression={ $_.'TimePointBackgroundDetail[OperationEndTime]' }}, @{Name='OperationID'; Expression={ $_.'TimePointBackgroundDetail[OperationId]' }}, @{Name='Sum_CUs'; Expression={ $_.'[Sum_CUs]' }}, @{Name='Sum_Duration'; Expression={ $_.'[Sum_Duration]' }}
}