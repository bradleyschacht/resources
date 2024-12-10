function Find-FabricSQLMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Message
    )
        
    # QueryHash
    $Pattern = "Query Hash: (?<QueryHash>0x\w+)"
    $PatternMatches = ($Message | Select-String -Pattern $Pattern).Matches
    if ($PatternMatches) {
        $QueryHash = $PatternMatches[0].Groups['QueryHash'].Value
    }
    else {
        $QueryHash = $null
    }

    # RequestID
    $Pattern = "Distributed request ID: \{(?<DistributedRequestID>[\w-]+)\}"
    $PatternMatches = ($Message | Select-String -Pattern $Pattern).Matches
    if ($PatternMatches) {
        $DistributedRequestID = $PatternMatches[0].Groups['DistributedRequestID'].Value
    }
    else {
        $DistributedRequestID = $null
    }
    
    # StatementID
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