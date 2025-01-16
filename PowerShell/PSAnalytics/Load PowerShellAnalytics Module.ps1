# https://stackoverflow.com/questions/44509704/creating-powershell-modules-from-multiple-files-referencing-with-module

# Script to the current folder location was taken from this kind person's Reddit post: https://www.reddit.com/r/PowerShell/comments/b72t27/path_to_this_script_check_ise_vscode_and_running/
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

Remove-Module "PSAnalytics" -Force -ErrorAction SilentlyContinue
Remove-Module "PSAnalytics.Fabric" -Force -ErrorAction SilentlyContinue
Remove-Module "PSAnalytics.SQLLoadTest" -Force -ErrorAction SilentlyContinue
Import-Module $PathToScript -Force -Global