Function Map-WSMANCertificates {

<#
    .Description
        Create cert mapping entry if the entry does not already exist

    .Links
        http://blogs.msdn.com/b/wmi/archive/2009/03/23/how-to-use-wsman-config-provider-for-certificate-authentication.aspx
#>

    [CmdletBinding()]
    Param (
        [PSCredential]$Credential
    )

    # -----  find user certificate which has the usage “Client Authentication (1.3.6.1.5.5.7.3.2)” as this is required for subsequent client cert auth
    foreach ($cert in get-childitem cert:\localmachine\My) {
        Write-Verbose "Certificate = $($Cert.FriendlyName)"
        #$Cert.extensions | fl *
        foreach ($ext in $cert.Extensions) {
           # "----"
           # $Ext | fl *
           # $ekey = [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]$ext
            $oids = $ext.EnhancedKeyUsages
            foreach ($oid in $oids) {
               # "++++"
                #$OID
                if ($oid.FriendlyName -eq "Client Authentication") {
                    $usercerts=$cert
                }
            }
        }
    }
    
    # ----- get ISSUER name for the above user certificate,
    if ($usercerts.count -eq 0) {
            Write-Verbose "No Users certs found"
            $issuername = (, $usercerts)[0].Issuer
        } 
        else {
            Write-Verbose "Cert Found"
            $issuername = $UserCerts[0].issuer
    }
    Write-Verbose "Issuer: $issuername"

    # ----- get the ISSUER thumbprint
    $IssuerThumbprint=(get-childitem -path cert:\localmachine\ca | where-object { $_.Subject -eq $issuername }).Thumbprint
    Write-Verbose "Issuer Thumbprint: $IssuerThumbprint"

    # ----- Map cert to Local User
    New-Item -Path WSMan:\localhost\ClientCertificate -URI http://microsoft.test.mig.wsman/* -Subject *.com -Issuer $IssuerThumbprint -Credential $Credential -force


    

}


Map-WSMANCertificates -Credential (Get-Credential -message 'Local user account used for Powershell WSMAN remoting') -verbose