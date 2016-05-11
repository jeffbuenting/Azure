$Port = 80 

# ----- Get Website info and write it to a file to save the info
$WebSites = get-website 
$Websites | export-csv c:\temp\WebsiteSettingsBackup.csv -NoTypeInformation

# ----- Change bindings
$Websites | foreach { 
    
    $Binding = Get-WebBinding -Name $_.Name
    New-WebBinding -Name $_.Name -IPAddress * -Port $Port
    $Binding | Remove-WebBinding

    $Port++
}