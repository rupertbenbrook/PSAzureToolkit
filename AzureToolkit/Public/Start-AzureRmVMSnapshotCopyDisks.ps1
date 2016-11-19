function Start-AzureRmVMSnapshotCopyDisks {

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = "PSVirtualMachine", Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM,

        [Parameter(ParameterSetName = "NamedVM", Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter(ParameterSetName = "NamedVM", Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("Name")]
        [string]$VMName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationStorageAccountName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationContainer
    )

    process {
        Write-Progress -Activity "Snapshotting and Copying the disks for VM $VMName" -Status "Gathering context"
        if ($PSCmdlet.ParameterSetName -eq "NamedVM") {
            $VM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
        }
        $destContext = Get-AzureRmStorageContextFromAccountName -StorageAccountName $DestinationStorageAccountName
        $disks = @([uri]$vm.StorageProfile.OsDisk.Vhd.Uri)
        $disks += $vm.StorageProfile.DataDisks | %{ [uri]$_.Vhd.Uri }
        $disks = $disks | %{
            $disk = @{
                Uri = $_;
                StorageAccountName = $_.Host.Substring(0, $_.Host.IndexOf("."));
                ContainerName = $_.Segments[1].Substring(0, $_.Segments[1].Length - 1);
                BlobPath = $_.AbsolutePath.Substring($_.AbsolutePath.Substring(1).IndexOf("/") + 2)
            }
            $disk += @{
                Context = (Get-AzureRmStorageContextFromAccountName -StorageAccountName $disk.StorageAccountName)
            }
            $disk += @{
                Blob = (Get-AzureStorageBlob -Context $disk.Context -Container $disk.ContainerName -Blob $disk.BlobPath)
            }
            New-Object -TypeName PSObject -Property $disk
        }

        Write-Progress -Activity "Snapshotting and Copying the disks for VM $VMName" -Status "Snapshotting"
        $copyBlobs = $disks | %{
            $snapshot = ([Microsoft.WindowsAzure.Storage.Blob.CloudPageBlob]$_.Blob.ICloudBlob).CreateSnapshot()
            $destBlob = ($_.BlobPath + ".copy")
            Stop-AzureStorageBlobCopy -Context $destContext -Container $DestinationContainer -Blob $destBlob -Force -ErrorAction SilentlyContinue
            $copyBlob = Start-AzureStorageBlobCopy -SrcContext $_.Context -SrcContainer $_.ContainerName -SrcBlob $_.BlobPath -DestContext $destContext -DestContainer $DestinationContainer -DestBlob $destBlob -Force
            $_ |
                Add-Member @{ SnapshotBlob=$snapshot; CopyBlob=$copyBlob; DestBlob = $destBlob } -PassThru
        }

        Write-Progress -Activity "Snapshotting and Copying the disks for VM $VMName" -Status "Copying"
        $copyFails = $copyBlobs | Select -ExpandProperty CopyBlob | Get-AzureStorageBlobCopyState -WaitForComplete | ? Status -ne "Success"
        $failed = $copyFails.Count -gt 0

        Write-Progress -Activity "Snapshotting and Copying the disks for VM $VMName" -Status "Deleting snapshots"
        $copyBlobs | %{
            $_.SnapshotBlob.Delete()
        }

        Write-Progress -Activity "Snapshotting and Copying the disks for VM $VMName" -Status "Renaming"
        $copyBlobs | %{
            if (-not $failed) {
                Start-AzureStorageBlobCopy -SrcContext $destContext -SrcContainer $DestinationContainer -SrcBlob $_.DestBlob -DestContext $destContext -DestContainer $DestinationContainer -DestBlob $_.BlobPath -Force |
                    Get-AzureStorageBlobCopyState -WaitForComplete
            }
            Remove-AzureStorageBlob -Context $destContext -Container $DestinationContainer -Blob $_.DestBlob -Force
        }


        if ($failed) {
            $copyFails | %{
                Write-Error -TargetObject $_ -Message "Copy failed. [Status]: $($_.StatusDescription) [Source]: $($_.Source)"
            }
        }

        return $copyBlobs
    }
}