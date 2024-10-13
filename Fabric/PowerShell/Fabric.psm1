$PathToScript = if ($PSScriptRoot) { 
    # Console or vscode debug/run button/F5 temp console
    $PSScriptRoot 
}
else {
    if ($psISE) {Split-Path -Path $psISE.CurrentFile.FullPath}
    else {
        if ($profile -match "VScode") { 
            # vscode "Run Code Selection" button/F8 in integrated console
            Split-Path $psEditor.GetEditorContext().CurrentFile.Path 
        }
        else { 
            Write-Output "unknown directory to set path variable. exiting script."
            exit
        } 
    } 
}

# Change the location to the folder where the scripts are stored. 
Set-Location $PathToScript

foreach($Module in (Get-ChildItem -Path .\Functions | Where-Object {$_.Extension -eq ".ps1"})) {
    . $Module.FullName
    Export-ModuleMember -Function $Module.BaseName
}