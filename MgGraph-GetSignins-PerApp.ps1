param (
    [Parameter(Mandatory = $true)]
    [string]$tId,  # Tenant ID

    [Parameter(Mandatory = $true)]
    [string]$appId,  # Application ID

    [Parameter(Mandatory = $true)]
    [int]$agoDays  # Number of days to filter sign-ins
)

function Export-SignInsToCsv {
    param (
        [Parameter(Mandatory = $true)]
        [array]$SignIns,
        
        [Parameter(Mandatory = $true)]
        [string]$ExportPath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ColumnList
    )

    $SignIns | Add-Member -MemberType NoteProperty -Name "AuthenticationProcessingDetails1" -Value $null -Force  # Add a new property to the sign-ins object.
    $SignIns | Add-Member -MemberType NoteProperty -Name "SignInEventTypes1" -Value $null -Force  # Add a new property to the sign-ins object.

    $SignIns | 
        ForEach-Object {  # Enumerate the sign-ins and add the new properties.
            $_.AppDisplayName = $_.AppDisplayName  # Select the AppDisplayName property.
            $_.AppId = $_.AppId  # Select the AppId property.
            $_.createdDateTime = $_.createdDateTime  # Select the createdDateTime property.
            $_.CorrelationId = $_.CorrelationId  # Select the CorrelationId property.
            $_.AuthenticationProcessingDetails1 = $_.AuthenticationProcessingDetails | ConvertTo-Json -Depth 10  # Convert the AuthenticationProcessingDetails property to JSON format.
            $_.ipAddress = $_.ipAddress  # Select the ipAddress property.
            $_.SignInEventTypes1 = $_.SignInEventTypes | ConvertTo-Json -Depth 10  # Convert the SignInEventTypes property to JSON format.
        } 
    
    $SignIns | 
        Select-Object -Property $ColumnList.Property |  # Select the properties to be exported.
        Export-Csv -Path $ExportPath -NoTypeInformation -Append

}

write-host "This script will get sign-ins for a specific application ID from Microsoft Graph and export them to a CSV file." -ForegroundColor Green
write-host "This script requires the Microsoft.Graph.Authentication module to be installed." -ForegroundColor Green
write-host "This script requires the Microsoft.Graph.Beta module to be installed. `n" -ForegroundColor Green
Remove-Module Microsoft.Graph.Beta.Reports -Force -ErrorAction SilentlyContinue  # Unload the module if it is already loaded.
Remove-Module Microsoft.Graph.Authentication -Force -ErrorAction SilentlyContinue # Unload the module if it is already loaded.

Import-Module Microsoft.Graph.Authentication -Force # Load the authentication module.
Import-Module Microsoft.Graph.Beta.Reports -Force # Load the reports module.

$startDate = (Get-Date).AddDays(-($agoDays)).ToString('yyyy-MM-dd')  # Get filter start date.
$pathForExport = "./"  # The path to the local filesystem for export of the CSV file.

Connect-MgGraph -Scopes "AuditLog.Read.All" -TenantId $tId -NoWelcome # Or use Directory.Read.All.

write-host "Connected to Microsoft Graph with Tenant ID: $tId `n" -ForegroundColor Green

$clauses = (
    "createdDateTime ge $startDate",  # Filter for sign-ins from the last $agoDays days.
    "appId eq '$appId'",  # Filter for the application ID.
    "signInEventTypes/any(x:x eq 'interactiveUser')",  # Filter for interactive user sign-ins.
    "signInEventTypes/any(x:x eq 'nonInteractiveUser')",  # Filter for non-interactive user sign-ins.
    "signInEventTypes/any(x:x eq 'servicePrincipal')",  # Filter for service principal sign-ins.
    "signInEventTypes/any(x:x eq 'managedIdentity')"  # Filter for managed identity sign-ins.
)

# Enumerate the list of properties to be exported to the CSV files.
$columnList = @{ 
    Property = "SignInEventTypes1", "AppDisplayName", "AppId", "createdDateTime", "CorrelationId", "AuthenticationProcessingdetails1", "ipAddress"
}

# Set the export path for the CSV file.
$exportPath = $pathForExport + "SignIns $tId $appId.csv"

# Get all sign-ins based on filtering clauses.
write-host "Getting sign-ins for App ID: $appId" -ForegroundColor Green
write-host "Filtering sign-ins for the last $agoDays days `n" -ForegroundColor Green

####### Get the interactive user sign-ins.
write-host "Getting interactive user sign-ins" -ForegroundColor Green
$signIns = Get-MgBetaAuditLogSignIn -Filter ($clauses[0,1,2] -Join " and ") -All
if ($signIns.Count -eq 0) {  # Check if there are no sign-ins to export.
    Write-Host "No interactive user sign-ins found `n" -ForegroundColor Magenta
} else {
    Write-Host "Total interactive sign-ins found: $($signIns.Count) `n" -ForegroundColor Green
    Export-SignInsToCsv -SignIns $signIns -ExportPath $exportPath -ColumnList $columnList
}

####### Get the noninteractive user sign-ins.
write-host "Getting noninteractive user sign-ins" -ForegroundColor Green
$signIns = Get-MgBetaAuditLogSignIn -Filter ($clauses[0,1,3] -Join " and ") -All
if ($signIns.Count -eq 0) {  # Check if there are no sign-ins to export.
    Write-Host "No noninteractive user sign-ins found `n" -ForegroundColor Magenta
} else {
    Write-Host "Total noninteractive sign-ins found: $($signIns.Count) `n" -ForegroundColor Green
    Export-SignInsToCsv -SignIns $signIns -ExportPath $exportPath -ColumnList $columnList
}

####### Get the servicePrincipal sign-ins.
Write-Host "Getting servicePrincipal sign-ins" -ForegroundColor Green
$signIns = Get-MgBetaAuditLogSignIn -Filter ($clauses[0,1,4] -Join " and ") -All
if ($signIns.Count -eq 0) {  # Check if there are no sign-ins to export.
    Write-Host "No servicePrincipal sign-ins found `n" -ForegroundColor Magenta
} else {
    Write-Host "Total servicePrincipal sign-ins found: $($signIns.Count) `n" -ForegroundColor Green
    Export-SignInsToCsv -SignIns $signIns -ExportPath $exportPath -ColumnList $columnList
}

####### Get the managedIdentity sign-ins.
Write-Host "Getting managedIdentity sign-ins" -ForegroundColor Green
$signIns = Get-MgBetaAuditLogSignIn -Filter ($clauses[0,1,5] -Join " and ") -All
if ($signIns.Count -eq 0) {  # Check if there are no sign-ins to export.
    Write-Host "No managedIdentity sign-ins found `n" -ForegroundColor Magenta
} else {
    Write-Host "Total managedIdentity sign-ins found: $($signIns.Count) `n" -ForegroundColor Green
    Export-SignInsToCsv -SignIns $signIns -ExportPath $exportPath -ColumnList $columnList
}

Write-Host "Exported sign-ins to CSV file: $pathForExport" -ForegroundColor Green