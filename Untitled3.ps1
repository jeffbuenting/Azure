WorkFlow Failover-VMs {
    
    Param (
        [Object]$RecoveryPlanContext
    )

    $Cred = Get-AutomationPSCredential -Name "SL Automation Account"



    # ----- Create Endpoint for HTTP port 80
    Add-AzureEndpoint
}