﻿<#
.SYNOPSIS 
    Creates a simple new Stand-Alone Azure Endpoint for a specified Virtual Machine based on the following input parameters:
        "Service Name", "VM Name", "Azure Endpoint Name",
        "Azure Endpoint Protocol", "Azure Endpoint Public Port", "Azure Endpoint Local Port"

.DESCRIPTION
    This runbook sample leverages organization id credential based authentication (Azure AD;
    instead of the Connect-Azure Runbook). Before using this runbook, you must create an Azure
    Active Directory user and allow that user to manage the Azure subscription you want to
    work against. You must also place this user's username / password in an Azure Automation
    credential asset. 
    
    You can find more information on configuring Azure so that Azure Automation can manage your 
    Azure subscription(s) here: http://aka.ms/Sspv1l 
 
    It does leverage an Automation Asset for the required Azure AD Credential. This example uses the
    following call to get this credential from the Asset store:
        
        Get-AutomationPSCredential -Name 'Azure AD Automation Account'

    IMPORTANT Usage of the Select-AzureSubscription command (not included in this example) will be needed
              as well right after connection if multiple Azure Subscriptions are associated with the provided
              organization id credential.
    
    In addition, there may be some benefit to creating and leveraging Variable Assets to store some of
    the more static Azure Endpoint data.

    This example runbook DOES NOT include example script to enable the following options for the Azure Endpoint:
    "Create a Load-Balanced Set", "Enable Direct Server Return".

    This example also leverages InlineScript for the actual command invocation, as the necessary commands for Azure Endpoint
    creation leverages fairly complex pipeline execution, which is even more complex within the PowerShell Workflow context.

.PARAMETER ServiceName
    REQUIRED. Name of the deployed Service for the Virtual Machine which will get the new specified Azure Endpoint.

.PARAMETER VMName
    REQUIRED. Name of the deployed Virtual Machine which will get the new specified Azure Endpoint.

.PARAMETER AEName
   REQUIRED. Name of the Stand-Alone Azure Endpoint to be added to the deployed Virtual Machine. This name can be
   a well known / established name: ("Remote Desktop", "PowerShell", "SSH", "FTP", "SMTP", "DNS", "HTTP", "POP3",
    "IMAP", "LDAP", "HTTPS", "SMTPS", "IMAPS", "POP3S", "MSSQL", "MySQL") or something custom: "My Endpoint"

   This name must be unique for the Virtual Machine, otherwise an error will be thrown and the action will fail.

.PARAMETER AEProtocol
    REQUIRED. Protocol of the Stand-Alone Azure Endpoint to be added to the deployed Virtual Machine.
    Valid Values for this Parameter: "TCP", "UDP"

.PARAMETER AEPublicPort
    REQUIRED. Public Port of the Stand-Alone Azure Endpoint to be added to the deployed Virtual Machine.
    This can be user defined, but Azure offers suggested (based on defaults) values for the respective
    well known Endpoint Names:
        Remote Desktop   3389
        PowerShell	     5986
        SSH              22
        FTP	             21
        SMTP	         25
        DNS	             53
        HTTP		     80
        POP3		     110
        IMAP		     143
        LDAP		     389
        HTTPS		     443
        SMTPS		     587
        IMAPS		     993
        POP3S		     995
        MSSQL		     1433
        MySQL		     3306

    This port must be unique for the Virtual Machine, otherwise an error will be thrown and the action will fail.

.PARAMETER AELocalPort
    REQUIRED. Private Port of the Stand-Alone Azure Endpoint to be added to the deployed Virtual Machine.
    This can be user defined, but Azure offers suggested (based on defaults) values for the respective
    well known Endpoint Names:
        Remote Desktop   3389
        PowerShell	     5986
        SSH              22
        FTP	             21
        SMTP	         25
        DNS	             53
        HTTP		     80
        POP3		     110
        IMAP		     143
        LDAP		     389
        HTTPS		     443
        SMTPS		     587
        IMAPS		     993
        POP3S		     995
        MSSQL		     1433
        MySQL		     3306

        This port must be unique for the Virtual Machine, otherwise an error will be thrown and the action will fail.

.EXAMPLE
    New-AzureVMEndpoint -ServiceName "MyService001" -VMName "MyVM001" `
        -AEName "Remote Desktop" -AEProtocol "TCP" -AEPublicPort 50025 -AELocalPort 3389        
        
.EXAMPLE
    New-AzureVMEndpoint -ServiceName "MyService001" -VMName "MyVM001" `
        -AEName "HTTPIn" -AEProtocol "TCP" -AEPublicPort 80 -AELocalPort 8080

.EXAMPLE
    $VMData = (
        @{
            ServiceName = "MyService001";
            VMName = "MyVM001";
            AEName = "My Endpoint";
            AEProtocol = "TCP"
            AEPublicPort = "50025";
            AELocalPort = "3389";
        },
     
        @{
            ServiceName = "MyService001";
            VMName = "MyVM002";
            AEName = "My Endpoint";
            AEProtocol = "TCP"
            AEPublicPort = "52153";
            AELocalPort = "5986";
        }
    )
    
    foreach ($VM in $VMData)
    {
        New-AzureVMEndpoint -ServiceName $VM.ServiceName -VMName $VM.VMName `
            -AEName $VM.AEName -AEProtocol $VM.AEProtocol `
            -AEPublicPort $VM.AEPublicPort -AELocalPort $VM.AELocalPort
    }

.NOTES
    AUTHOR: Charles Joy, EC CAT Team, Microsoft
    BLOG: Building Cloud Blog - http://aka.ms/BuildingClouds
    LAST EDIT: Oct 17, 2014
    
.LINK
    https://gallery.technet.microsoft.com/scriptcenter/Create-New-Azure-VM-4d8b17b7
#>

workflow New-AzureVMEndpoint
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,

        [Parameter(Mandatory=$true)]
        [string]$VMName,

        [Parameter(Mandatory=$true)]
        [string]$AEName,

        [Parameter(Mandatory=$true)]
        [string]$AEProtocol,

        [Parameter(Mandatory=$true)]
        [int]$AEPublicPort,

        [Parameter(Mandatory=$true)]
        [int]$AELocalPort
    )

    ####################################################################################################

    # Get the credential to use for Authentication to Azure.    
    $Cred = Get-AutomationPSCredential -Name 'SL Automation Account'
    
    # Connect to Azure
    $AzureAccount = Add-AzureAccount -Credential $Cred

    ####################################################################################################
    
    # Invoke pipeline commands within an InlineScript
    $EndpointStatus = InlineScript {

    # Invoke the necessary pipeline commands to add a Azure Endpoint to a specified Virtual Machine
    # This set of commands includes: Get-AzureVM | Add-AzureEndpoint | Update-AzureVM (including necessary parameters)

        $Status = Get-AzureVM -ServiceName $Using:ServiceName -Name $Using:VMName | `
        Add-AzureEndpoint -Name $Using:AEName -Protocol $Using:AEProtocol `
            -PublicPort $Using:AEPublicPort -LocalPort $Using:AELocalPort | `
        Update-AzureVM
        
        Write-Output $Status
    }
    
    # Note $Using:Variable is required within the InlineScript to reference variables/parameters external to the InlineScript
    
    # Write Output and Verbose - Success Status Information for Service, VM, Endpoint, Protocol, and Ports
    if ($EndpointStatus.OperationStatus -eq "Succeeded")
    {
        $SuccessMsg = "Service: {0} `nVM: {1} `nEndpoint: {2} `nProtocol: {3} `nPublic Port: {4} `nLocal Port: {5} `nOperation: {6} `nOperation Id: {7} `nOperation Status: {8} `n" `
            -f $ServiceName, $VMName, $AEName, $AEProtocol, $AEPublicPort, $AELocalPort, $EndpointStatus.OperationDescription, $EndpointStatus.OperationId, $EndpointStatus.OperationStatus
        Write-Output $SuccessMsg
        Write-Verbose $SuccessMsg
    }
}