function Add-AzureRmNetworkSecurityRuleConfigForRegionPublicIpSubnets {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Microsoft.Azure.Commands.Network.Models.PSEffectiveNetworkSecurityGroup]$NetworkSecurityGroup,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        [switch]$RefreshCache = $false,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RuleNamePrefix,

        [Parameter(Mandatory)]
        [int]$StartingPriority,

        [Parameter(Mandatory)]
        [string]$Access,

        [Parameter(Mandatory)]
        [string]$Direction,

        [Parameter(Mandatory)]
        [string]$Protocol,

        [Parameter(Mandatory)]
        [string]$Port,

        [Parameter(Mandatory)]
        [string]$Subnet
    )

    $ranges = Get-AzureRegionPublicIpSubnets -RefreshCache $RefreshCache

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
    $_.SecurityRules.AddRange($newRules)
}