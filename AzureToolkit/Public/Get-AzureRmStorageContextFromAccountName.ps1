function Get-AzureRmStorageContextFromAccountName {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("StorageAccount", "Name")]
        [string]$StorageAccountName
    )

    process {
        Write-Verbose "Finding storage account resource named '$StorageAccountName'"
        $account = Find-AzureRmResource -ResourceType "Microsoft.Storage/storageAccounts" -ResourceNameContains $StorageAccountName | ? ResourceName -eq $StorageAccountName
        if ($account -eq $null) {
            Write-Error -Message "Cannot find a storage account named '$StorageAccountName'"
            return $null
        }


        Write-Verbose "Getting storage account key for storage account '$StorageAccountName'"
        $key = Get-AzureRmStorageAccountKey -ResourceGroupName $account.ResourceGroupName -Name $StorageAccountName

        return New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key.Value[0]
    }
}