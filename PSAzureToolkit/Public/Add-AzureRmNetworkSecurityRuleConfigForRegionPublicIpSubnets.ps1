function Add-AzureRmNetworkSecurityRuleConfigForRegionPublicIpSubnets {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]$NetworkSecurityGroup,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        [switch]$RefreshCache = $false,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RuleNamePrefix,

        [Parameter(Mandatory)]
        [ValidateRange(100, 4096)]
        [int]$StartingPriority,

        [Parameter(Mandatory)]
        [ValidateSet("Allow", "Deny")]
        [string]$Access,

        [Parameter(Mandatory)]
        [ValidateSet("Inbound", "Outbound")]
        [string]$Direction,

        [Parameter(Mandatory)]
        [ValidateSet("Tcp", "Udp", "*")]
        [string]$Protocol,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Port,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Subnet
    )

    begin {
        Write-Verbose "Getting the list of Azure public IP subnets per region"
        $ranges = Get-AzureRegionPublicIpSubnets -RefreshCache:$RefreshCache.IsPresent

        if (-not ($Region -in ($ranges | Select-Object -ExpandProperty Region))) {
            throw "The region $Region was not found in the Azure region public IP subnets"
        }
    }

    process {
        Write-Verbose "Adding rules for region $Region to network security group $($NetworkSecurityGroup.Id)"
        [Microsoft.Azure.Commands.Network.Models.PSSecurityRule[]]$newRules = @()
        $ranges | ? Region -eq $Region | Select-Object -ExpandProperty Subnets | %{ $index = $StartingPriority } {
            $rule = New-Object -TypeName Microsoft.Azure.Commands.Network.Models.PSSecurityRule
            $rule.Name = "$RuleNamePrefix$Region-$index";
            $rule.Priority = "$index";
            $rule.Access = $Access;
            $rule.Direction = $Direction;
            $rule.Protocol = $Protocol;
            $rule.SourcePortRange = "*";
            $rule.DestinationPortRange = $Port;
            if ($Direction -eq "Inbound") {
                $rule.SourceAddressPrefix = $_;
                $rule.DestinationAddressPrefix = $Subnet;
            }
            if ($Direction -eq "Outbound") {
                $rule.SourceAddressPrefix = $Subnet;
                $rule.DestinationAddressPrefix = $_;
            }
            $newRules += $rule
            $index++
        }
        $NetworkSecurityGroup.SecurityRules.AddRange($newRules)
        return $NetworkSecurityGroup
    }
}