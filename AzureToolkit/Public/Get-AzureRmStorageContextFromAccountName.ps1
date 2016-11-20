function Get-AzureRmStorageContextFromAccountName {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("StorageAccount", "Name")]
        [string]$StorageAccountName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("Secondary")]
        [switch]$SecondaryEndpoints = $false
    )

    process {
        Write-Verbose "Finding storage account resource named '$StorageAccountName'"
        $account = Find-AzureRmResource -ResourceType "Microsoft.Storage/storageAccounts" -ResourceNameContains $StorageAccountName | ? ResourceName -eq $StorageAccountName
        if ($account -eq $null) {
            Write-Error -Message "Cannot find a storage account named '$StorageAccountName'"
            return $null
        }

        if ($SecondaryEndpoints -and ($account.Sku.name -ne "Standard_RAGRS")) {
            throw "The storage account '$StorageAccountName' has the Sku '$($account.Sku.name)' and so does not have secondary endpoints"
        }

        Write-Verbose "Getting storage account key for storage account '$StorageAccountName'"
        $key = Get-AzureRmStorageAccountKey -ResourceGroupName $account.ResourceGroupName -Name $StorageAccountName

        $secondary = ""
        if ($SecondaryEndpoints) {
            Write-Verbose "Using secondary endpoints for storage account '$StorageAccountName'"
            $secondary = "-secondary"
        }
        $connectionString = "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($key.Value[0]);BlobEndpoint=https://$StorageAccountName$secondary.blob.core.windows.net;FileEndpoint=https://$StorageAccountName$secondary.file.core.windows.net;QueueEndpoint=https://$StorageAccountName$secondary.queue.core.windows.net;TableEndpoint=https://$StorageAccountName$secondary.table.core.windows.net;"
        return New-AzureStorageContext -ConnectionString $connectionString
    }
}