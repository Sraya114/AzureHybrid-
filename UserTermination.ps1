#function to Save Credentials to a file
Function Save-Credential([string]$UserName, [string]$KeyPath)
{
    #Create directory for Key file
    If (!(Test-Path $KeyPath)) {       
        Try {
            New-Item -ItemType Directory -Path $KeyPath -ErrorAction STOP | Out-Null
        }
        Catch {
            Throw $_.Exception.Message
        }
    }
    #store password encrypted in file
    $Credential = Get-Credential -Message "Enter the Credentials:" -UserName $UserName
    $Credential.Password | ConvertFrom-SecureString | Out-File "$($KeyPath)\$($Credential.Username).cred" -Force
}

$UserAdmin = Read-Host -Prompt "Please enter the email address of the Admin User"

#Get credentials and create an encrypted password file
Save-Credential -UserName $UserAdmin -KeyPath "C:\MyData\Scripts"



#function to get credentials from a Saved file
Function Get-SavedCredential([string]$UserName,[string]$KeyPath)
{
    If(Test-Path "$($KeyPath)\$($Username).cred") {
        $SecureString = Get-Content "$($KeyPath)\$($Username).cred" | ConvertTo-SecureString
        $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecureString
    }
    Else {
        Throw "Unable to locate a credential for $($Username)"
    }
    Return $Credential
}
 
#Get encrypted password from the file
$Cred = Get-SavedCredential -UserName $UserAdmin -KeyPath "C:\MyData\Scripts"
 



#Connect to Microsoft 365
Connect-MsolService -Credential $Cred

#Aquire variables
$TargetUPN = Read-Host -Prompt "Please enter the email address of the user to be deleted."


#PowerShell to add a user to office 365 group
#Add-DistributionGroupMember -Identity "<disabled_employee@blabla.com>" -LinkType "Members" -Links $TargetUPN

#PowerShell to remove from all groups user member of


#Block user sign in
Set-MsolUser -UserPrincipalName $TargetUPN -BlockCredential $true

#Connect to Exchange Online
Connect-ExchangeOnline -Credential $Cred -ShowProgress $true

#Change the user mailbox to a Shared mailbox
Set-Mailbox $TargetUPN -Type Shared

#Connect to Azure AD
Connect-AzureAd -Credential $Cred

#Remove all user licenses
$userUPN=$TargetUPN
$userList = Get-AzureADUser -ObjectID $userUPN
$Skus = $userList | Select -ExpandProperty AssignedLicenses | Select SkuID
if($userList.Count -ne 0) {
    if($Skus -is [array])
    {
        $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
        for ($i=0; $i -lt $Skus.Count; $i++) {
            $licenses.RemoveLicenses +=  (Get-AzureADSubscribedSku | Where-Object -Property SkuID -Value $Skus[$i].SkuId -EQ).SkuID   
        }
        Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $licenses
    } else {
        $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
        $licenses.RemoveLicenses =  (Get-AzureADSubscribedSku | Where-Object -Property SkuID -Value $Skus.SkuId -EQ).SkuID
        Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $licenses
    }
}
#Disconnect from All Services
Disconnect-AzureAD
Disconnect-ExchangeOnline










