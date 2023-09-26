# Input bindings are passed in via param block.
param($Timer)
$ProgressPreference = 'SilentlyContinue'; #Sets this value to suppresses the progress bar and continues with the operation.
$Global:ProgressPreference = 'SilentlyContinue'; 
Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true' -WhatIf:$false; #Supress warnings/prompts to run "quiet"

#Variables
$TenantId = $env:B2C_TenantID 
$TargetSubscriptionId = $env:TARGET_SubID 
$AppReg_ClientID = $env:AppReg_ClientID 
$AppReg_ClientSecret = $env:AppReg_ClientSecret 
$TargetStorageAccountName =  $env:STORAGE_StorageAcc 
$blobContainer = $env:STORAGE_StorageContainer 
$blobdirectory = $env:STORAGE_BlobDirectoryFolder 
$fileName = $env:STORAGE_FileName 

# Create access token with keyvault secret and appclient ID
function Get-MsalAccessToken {
    param (
        [Parameter(Mandatory=$true)][string]$TId,
        [Parameter(Mandatory=$true)][string]$AR_CID,
        [Parameter(Mandatory=$true)][string]$AR_CS
    )
    $secureSecret = $AR_CS | ConvertTo-SecureString -AsPlainText -Force
    $token = Get-MsalToken -TenantId $TId -ClientId $AR_CID -ClientSecret $secureSecret
    Connect-MgGraph -AccessToken $token.AccessToken
}

Get-MsalAccessToken -TId $TenantId -AR_CID $AppReg_ClientID -AR_CS $AppReg_ClientSecret
Set-AzContext -TenantId $TenantId -SubscriptionId $TargetSubscriptionId

#Try to query for B2C users
function Get-B2CUsers {
    try {
        return Get-MgUser -All | Select-Object DisplayName, Id, UserPrincipalName, Mail
    } catch {
        Write-Error "Error retrieving B2C users: $_"
        return $null
    }
}

#Store to CSV format
$b2cUser = Get-B2CUsers
$csvString = $b2cUser | ConvertTo-Csv -NoTypeInformation

#If the file does not exist, create it, and write content to it.
if (-not(Test-Path -Path ./$fileName -PathType Leaf)) {
    try {
        $null = New-Item -ItemType File -Path ./$fileName -Force -ErrorAction Stop
        Set-Content -Path ./$fileName -Value $csvString -Encoding utf8
    }
    catch {
        throw $_.Exception.Message
    }
}
# If the file already exists, overwrite content.
else {
    try {
        Set-Content -Path ./$fileName -Value $csvString -Encoding utf8
    } catch {
        Write-Host "Error: $_"
    }
}

#Upload local file to storage account, overwrites existing file in path.
Connect-AzAccount -Identity
$storagecontext = New-AzStorageContext -UseConnectedAccount -BlobEndpoint  "https://$TargetStorageAccountName.blob.core.windows.net/"

#Set storage/blob to correct path, force confirm prompts
$result = Set-AzStorageBlobContent -Context $storagecontext -Container $blobContainer -Blob "$blobdirectory/$($fileName)" -File "./$fileName" -Confirm:$false -Force

#Write output and result
Write-Host "$filename uploaded to storage account"
$result | Select-Object -Property Name, BlobType, Length, ContentType, LastModified, AccessTier

