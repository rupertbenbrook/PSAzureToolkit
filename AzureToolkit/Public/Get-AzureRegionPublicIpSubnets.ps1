function Get-AzureRegionPublicIpSubnets {

    [CmdletBinding()]
    param (
    )

    Write-Verbose "Downloading the Azure Datacenter IP ranges download confirmation page to find the latest XML file download"
    $downloadPage = Invoke-WebRequest -Uri "https://www.microsoft.com/download/confirmation.aspx?id=41653" -UseBasicParsing
    $xmlUriFound = $downloadPage.RawContent -cmatch "https://[\w\n-/]+/PublicIPs_\d+\.xml"
    if (-not $xmlFileUri) {
        throw "Cannot find the Azure Public IP ranges XML download Uri in the download confirmation page"
    }

    Write-Verbose "Downloading the Azure Public IP ranges XML from '$xmlFileUri'"
    $xmlFileUri = [string]$matches.Values[0]
    $response = Invoke-WebRequest -Uri $xmlFileUri -UseBasicParsing
    [xml]$xmlResponse = [System.Text.Encoding]::UTF8.GetString($response.Content)
    $xmlResponse.AzurePublicIpAddresses.Region | %{
        New-Object -TypeName PSObject -Property @{Region=$_.Name; Subnets=$_.IpRange.Subnet }
    }
}