function Get-AzureRegionPublicIpSubnets {

    [CmdletBinding()]
    param (
        [switch]$RefreshCache = $false
    )

    $timeout = 10
    $now = Get-Date
    $regionSubnetsCache = $global:regionSubnetsCache
    $regionSubnetsCacheTime = $global:regionSubnetsCacheTime
    Write-Verbose "Last cached result was cached at $regionSubnetsCacheTime - refresh cache: $RefreshCache"
    if (($RefreshCache -eq $false) -and
        ($regionSubnetsCacheTime -ne $null) -and
        ($regionSubnetsCache -ne $null) -and
        ($now.Subtract($regionSubnetsCacheTime).TotalMinutes -lt 60)) {
        
        Write-Verbose "Returning result from cache"
        return $regionSubnetsCache
    }

    Write-Verbose "Downloading the Azure Datacenter IP ranges download confirmation page to find the latest XML file download"
    $downloadPage = Invoke-WebRequest -Uri "https://www.microsoft.com/download/confirmation.aspx?id=41653" -UseBasicParsing -TimeoutSec $timeout
    $xmlUriFound = $downloadPage.Content -cmatch "https://[\w\n-/]+/PublicIPs_\d+\.xml"
    if (-not $xmlUriFound) {
        throw "Cannot find the Azure Public IP ranges XML download Uri in the download confirmation page"
    }
    $xmlFileUri = [string]$matches.Values[0]

    Write-Verbose "Downloading the Azure Public IP ranges XML from $xmlFileUri"
    $response = Invoke-WebRequest -Uri $xmlFileUri -UseBasicParsing -TimeoutSec $timeout
    [xml]$xmlResponse = [System.Text.Encoding]::UTF8.GetString($response.Content)
    $regionSubnets = $xmlResponse.AzurePublicIpAddresses.Region | %{
        New-Object -TypeName PSObject -Property @{Region=$_.Name; Subnets=$_.IpRange.Subnet }
    }

    Set-Variable -Name "regionSubnetsCache" -Scope Global -Visibility Private -Value $regionSubnets
    Set-Variable -Name "regionSubnetsCacheTime" -Scope Global -Visibility Private -Value $now
    return $regionSubnets
}