function Get-AzureRegionPublicIpSubnets {

    [CmdletBinding()]
    param (
        [switch]$RefreshCache = $false
    )

    $cacheName = "regionSubnetsCache"
    $cacheTimeName = "regionSubnetsCacheTime"

    $now = Get-Date
    $regionSubnetsCache = $PSCmdlet.SessionState.PSVariable.Get($cacheName).Value
    $regionSubnetsCacheTime = $PSCmdlet.SessionState.PSVariable.Get($cacheTimeName).Value
    Write-Verbose "Last cached result was cached at $regionSubnetsCacheTime"
    if (($RefreshCache -eq $false) -and
        ($regionSubnetsCacheTime -ne $null) -and
        ($regionSubnetsCache -ne $null) -and
        ($now.Subtract($regionSubnetsCacheTime).TotalMinutes -lt 60)) {
        
        Write-Verbose "Returning result from cache"
        return $regionSubnetsCache
    }

    Write-Verbose "Downloading the Azure Datacenter IP ranges download confirmation page to find the latest XML file download"
    $downloadPage = Invoke-WebRequest -Uri "https://www.microsoft.com/download/confirmation.aspx?id=41653" -UseBasicParsing
    $xmlUriFound = $downloadPage.Content -cmatch "https://[\w\n-/]+/PublicIPs_\d+\.xml"
    if (-not $xmlUriFound) {
        throw "Cannot find the Azure Public IP ranges XML download Uri in the download confirmation page"
    }
    $xmlFileUri = [string]$matches.Values[0]

    Write-Verbose "Downloading the Azure Public IP ranges XML from $xmlFileUri"
    $response = Invoke-WebRequest -Uri $xmlFileUri -UseBasicParsing
    [xml]$xmlResponse = [System.Text.Encoding]::UTF8.GetString($response.Content)
    $regionSubnets = $xmlResponse.AzurePublicIpAddresses.Region | %{
        New-Object -TypeName PSObject -Property @{Region=$_.Name; Subnets=$_.IpRange.Subnet }
    }

    $PSCmdlet.SessionState.PSVariable.Set($cacheName, $regionSubnets)
    $PSCmdlet.SessionState.PSVariable.Set($cacheTimeName, $now)
    return $regionSubnets
}