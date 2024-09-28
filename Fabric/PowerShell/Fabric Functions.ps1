function Test-FabricId {
    param (
        [string]$String
    )

    <#
        Description: Determines if the string value matches the pattern of an id in Fabric (WorkspaceID, ItemID, etc.) or not.
        Returns: $true or $false
    #>
    
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


function Get-FabricWorkspace {
    param (
        [string]$Workspace = $null,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $Uri            = "https://api.fabric.microsoft.com/v1/workspaces"
    $Headers        = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    $WorkspaceList  = (Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120).value

    if($Workspace) {
        if(!(Test-FabricId -String $Workspace)) {
            $WorkspaceList | Where-Object {$_.displayName -like $Workspace}
        }
        else {
            $WorkspaceList | Where-Object {$_.id -eq $Workspace}
        }
    }
    else {
        $WorkspaceList
    }

}


function Get-FabricItem {
    param (
        [string]$Workspace,
        [string]$Item = $null,
        [string]$ItemType = $null,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    $WorkspaceID = (Get-FabricWorkspace -Workspace $Workspace -AccessToken $AccessToken).id
    
    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/items" -f $WorkspaceID
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    $ItemList   = (Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120).value

    # Check if an item or item type were provided.
    if($Item -or $ItemType) {
        
        if($Item) {
            # If an item id was provided.
            if((Test-FabricId -String $Item)) {
                $FilteredItemList = $ItemList | Where-Object {$_.id -eq $Item}
            }
            # If an item name was provided.
            else {
                $FilteredItemList = $ItemList | Where-Object {$_.displayName -like $Item}
            }
        }
        else {
            $FilteredItemList = $ItemList
        }

        if($ItemType) {
            $FilteredItemList = $FilteredItemList | Where-Object {$_.type -like $ItemType}
        }
        
        $FilteredItemList
    }
    else {
        $ItemList
    }
}


function Get-FabricCapacity {
    param (
        [string]$Location = "Fabric", #Azure or Fabric
        [string]$Capacity = $null,
        [string]$SubscriptionID = $null,
        [string]$ResourceGroupName = $null,
        [string]$Filter = $null,
        [string]$AccessToken = $null,
        [string]$APIVersion = "2022-07-01-preview"
    )

    if($Location -eq "Fabric") {
        if(!$AccessToken) {
            $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
        }
        
        $Uri            = "https://api.fabric.microsoft.com/v1/capacities"
        $Headers        = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
        $CapacityList   = (Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120).value

        if($Capacity) {
            # If a capacity id was provided.
            if((Test-FabricId -String $Capacity)) {
                $CapacityList | Where-Object {$_.id -eq $Capacity}
            }
            # If a capacity name was provided.
            else {
                $CapacityList | Where-Object {$_.displayName -like $Capacity}
            }
        }
        else {
            $CapacityList
        }
    }

    if($Location -eq "Azure") {
        if(!$AccessToken) {
            $AccessToken = Get-FabricAccessToken -ResourceType "Azure"
        }
        
        $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $Capacity, $APIVersion
        $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken)}
        
        Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120
    }
}


function Suspend-FabricCapacity {
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
    
    $Capacity = Get-FabricCapacity -Location "Azure" -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion
    
    if ($Capacity.properties.state -eq "Paused") {
        #Do nothing.
    }
    elseif ($Capacity.properties.state -eq "Active") {
        try {  
            $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}/suspend?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken)}
            $null = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120
            
            Start-Sleep -Seconds 5

            do {
                $Capacity = Get-FabricCapacity -Location "Azure" -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion
                    
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

    $Capacity = Get-FabricCapacity -Location "Azure" -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion
    
    if ($Capacity.properties.state -eq "Active") {
        #Do nothing.
    }
    elseif ($Capacity.properties.state -eq "Paused") {    
        try {
            $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}/resume?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken)}
            $null = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120       

            Start-Sleep -Seconds 5

            do {
                $Capacity = Get-FabricCapacity -Location "Azure" -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion
                    
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


function Set-FabricCapacitySku {
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
    $Capacity = Get-FabricCapacity -Location "Azure" -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName
        
    if ($Capacity.sku.name -eq $Sku) {
        #Do nothing.
    }
    elseif ($Capacity.sku.name -ne $Sku) {
        try {
            $Uri        = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Fabric/capacities/{2}?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $CapacityName, $APIVersion
            $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
            $Body       = '{"sku": {"name": "' + $Sku + '"}}'
            $null = Invoke-RestMethod -Method Patch -Uri $Uri -Body $Body -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120

            Start-Sleep -Seconds 5

            do {
                
                $Capacity = Get-FabricCapacity -Location "Azure" -AccessToken $AccessToken -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Capacity $CapacityName -APIVersion $APIVersion

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

    if(!(Test-FabricID -String $Capacity)) {
        $CapacityID = (Get-FabricCapacity -Location "Fabric" -Capacity $Capacity -AccessToken $AccessToken).id
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
            $null = Invoke-RestMethod -Method POST -Uri $Uri -Body $Body -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120
    
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


function Find-FabricSQLMessage
    ($Message) {
        
    #QueryHash
    $Pattern = "Query Hash: (?<QueryHash>0x\w+)"
    $PatternMatches = ($Message | Select-String -Pattern $Pattern).Matches
    if ($PatternMatches) {
        $QueryHash = $PatternMatches[0].Groups['QueryHash'].Value
    }
    else {
        $QueryHash = $null
    }

    #RequestID
    $Pattern = "Distributed request ID: \{(?<DistributedRequestID>[\w-]+)\}"
    $PatternMatches = ($Message | Select-String -Pattern $Pattern).Matches
    if ($PatternMatches) {
        $DistributedRequestID = $PatternMatches[0].Groups['DistributedRequestID'].Value
    }
    else {
        $DistributedRequestID = $null
    }
    
    #StatementID
    $Pattern = "Statement ID: \{(?<StatementID>[\w-]{36})\}"
    $PatternMatches = ($Message | Select-String -Pattern $Pattern).Matches
    if ($PatternMatches) {
        $StatementID = $PatternMatches[0].Groups['StatementID'].Value
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
	
	$Results = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120 -Body $Body

    $Results.results.tables.rows | Select-Object name, @{Name='WorkspaceName'; Expression={ $_.'Items[WorkspaceName]' }}, @{Name='ItemKind'; Expression={ $_.'Items[ItemKind]' }}, @{Name='ItemName'; Expression={ $_.'Items[ItemName]' }}, @{Name='OperationStartTime'; Expression={ $_.'TimePointBackgroundDetail[OperationStartTime]' }}, @{Name='OperationEndTime'; Expression={ $_.'TimePointBackgroundDetail[OperationEndTime]' }}, @{Name='OperationID'; Expression={ $_.'TimePointBackgroundDetail[OperationId]' }}, @{Name='Sum_CUs'; Expression={ $_.'[Sum_CUs]' }}, @{Name='Sum_Duration'; Expression={ $_.'[Sum_Duration]' }}
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
    
    if(!(Test-FabricID -String $Lakehouse)) {
        $LakehouseID = (Get-FabricItem -Workspace $WorkspaceID -Item $Lakehouse -ItemType "Lakehouse" -AccessToken $AccessToken).id
    }
    else {
        $LakehouseID = $Lakehouse
    }
    
    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/lakehouses/{1}" -f $WorkspaceID, $LakehouseID
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120

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

    if(!(Test-FabricID -String $Warehouse)) {
        $WarehouseID = (Get-FabricItem -Workspace $WorkspaceID -Item $Warehouse -ItemType "Warehouse" -AccessToken $AccessToken).id
    }
    else {
        $WarehouseID = $Warehouse
    }
    
    $Uri        = "https://api.fabric.microsoft.com/v1/workspaces/{0}/warehouses/{1}" -f $WorkspaceID, $WarehouseID
    $Headers    = @{'Authorization' = ('Bearer {0}' -f $AccessToken); 'Content-Type' = 'application/json'}
    Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120
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

    if(!(Test-FabricID -String $Workspace)) {
        $WorkspaceID = (Get-FabricWorkspace -AccessToken $AccessToken | Where-Object {$_.displayName -eq $Workspace}).id
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


function Get-FabricCUPricePerHour {
    param (
        [string]$Capacity = $null,
        [string]$Region = $null,
        [string]$AccessToken = $null
    )

    if(!$AccessToken) {
        $AccessToken = Get-FabricAccessToken -ResourceType "Fabric"
    }

    if($Capacity -notin ("", $null)) {
        $CapacityRegion = (Get-FabricCapacity -Location "Fabric" -Capacity $Capacity).region
    
        $Region = (Get-AzLocation | Where-Object {$_.DisplayName -eq $CapacityRegion}).Location
    }
    else {
        $Region = (Get-AzLocation | Where-Object {$_.DisplayName -like $Region}).Location
    }
    
    $Uri = "https://prices.azure.com/api/retail/prices?`$filter=serviceName eq 'Microsoft Fabric' and skuName eq 'Compute Pool Capacity Usage' and armRegionName eq '{0}'" -f $Region
    (Invoke-RestMethod -Method GET -Uri $Uri -ConnectionTimeoutSeconds 120 -OperationTimeoutSeconds 120).Items.retailPrice
}
