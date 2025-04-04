# Get sign in information for a specific application

## Disclaimer
This is a sample script and it can be used with no warranty.

## ⚠️ Warning
It is expected for the script to run for extended time on larger tenants.

## Script Call

To execute the script, use the following command:

```powershell
.\MgGraph-GetSignins-PerApp.ps1 -tId "<tenantID>" -appId "<appId>" -agoDays <days back>
```

## Output

The script will output a CSV file in the folder where it is running.

## Additional Resources

- [Microsoft Graph PowerShell Installation Guide](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0)
- [Microsoft Entra Data Retention Reference](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-reports-data-retention#how-long-does-azure-ad-store-the-data)