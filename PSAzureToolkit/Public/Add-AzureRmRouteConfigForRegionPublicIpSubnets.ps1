function Add-AzureRmRouteConfigForRegionPublicIpSubnets {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Microsoft.Azure.Commands.Network.Models.PSRouteTable]$RouteTable,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        [switch]$RefreshCache = $false,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RouteNamePrefix,

        [Parameter(Mandatory)]
        [ValidateSet("Internet", "VirtualAppliance")]
        [string]$NextHopType,

        [string]$NextHopIpAddress
    )

    begin {
        Write-Verbose "Getting the list of Azure public IP subnets per region"
        $ranges = Get-AzureRegionPublicIpSubnets -RefreshCache:$RefreshCache.IsPresent

        if (-not ($Region -in ($ranges | Select-Object -ExpandProperty Region))) {
            throw "The region $Region was not found in the Azure region public IP subnets"
        }
    }

    process {
        Write-Verbose "Adding rules for region $Region to route table $($RouteTable.Id)"
        [Microsoft.Azure.Commands.Network.Models.PSRoute[]]$newRoutes = @()
        $ranges | ? Region -eq $Region | Select-Object -ExpandProperty Subnets | %{ $index = 0 } {
            $route = New-Object -TypeName Microsoft.Azure.Commands.Network.Models.PSRoute
            $route.Name = "$RouteNamePrefix$Region-$index";
            $route.AddressPrefix = $_
            $route.NextHopType = $NextHopType
            if ($NextHopType -eq "VirtualAppliance") {
                $route.NextHopIpAddress = $NextHopIpAddress
            }
            $newRoutes += $route
            $index++
        }
        $RouteTable.Routes.AddRange($newRoutes)
        return $RouteTable
    }
}