function Get-AzureRmStorageGeoReplicationStats {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("StorageAccount", "Name")]
        [string]$StorageAccountName
    )

    process {
        Write-Verbose "Getting seconary endpoint context for storage account '$StorageAccountName'"
        $secondary = Get-AzureRmStorageContextFromAccountName -StorageAccountName $StorageAccountName -SecondaryEndpoints

        Write-Verbose "Getting blob geo-replication stats for storage account '$StorageAccountName'"
        $client = $secondary.StorageAccount.CreateCloudBlobClient()
        $blobStats = ($client.GetServiceStats()).GeoReplication

        Write-Verbose "Getting table geo-replication stats for storage account '$StorageAccountName'"
        $client = $secondary.StorageAccount.CreateCloudTableClient()
        $tableStats = ($client.GetServiceStats()).GeoReplication

        Write-Verbose "Getting queue geo-replication stats for storage account '$StorageAccountName'"
        $client = $secondary.StorageAccount.CreateCloudQueueClient()
        $queueStats = ($client.GetServiceStats()).GeoReplication

        return (New-Object -TypeName PSObject -Property @{
            Endpoint = "Blob"; Status = $blobStats.Status; LastSyncTime = $blobStats.LastSyncTime
        }), (New-Object -TypeName PSObject -Property @{
            Endpoint = "Table"; Status = $tableStats.Status; LastSyncTime = $tableStats.LastSyncTime
        }), (New-Object -TypeName PSObject -Property @{
            Endpoint = "Queue"; Status = $queueStats.Status; LastSyncTime = $queueStats.LastSyncTime
        })
    }
}