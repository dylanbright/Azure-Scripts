<#
.SYNOPSIS
  Returns a list of IPs or next available subnet of specified size.
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
  Version:        1.0
  Author:         Dylan Bright
  Creation Date:  May 20 2017
  Purpose/Change: Initial script development

  Version:        1.1
  Author:         Dylan Bright
  Creation Date:  June 10 2017
  Purpose/Change: Added valid 4th octet checking and validation
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>


param (
       [Parameter(Mandatory=$True)][string]$vnetName,      #Name of the vnet
       [Parameter(Mandatory=$True)][string]$ResourceGroupName, #Name of vnet Resource Group
       [Parameter(Mandatory=$True)][string]$AddressSpace,  #Address space in CIDR
       [ValidateSet(29,28,27,26,25,24,$null)] [Int32]$NextSub )   #Bits for the size of the subet we want to find.  If This is specified, then we fill find the next available subnet.  If not we will report all IPs in the address space and the subnets consuming them.

#IP Address Functions#########################
function Get-IPrange {
<# 
  .SYNOPSIS  
    Get the IP addresses in a range 
  .EXAMPLE 
   Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.3 -cidr 24 
#> 
 
param 
( 
  [string]$start, 
  [string]$end, 
  [string]$ip, 
  [string]$mask, 
  [int]$cidr 
) 
 
function IP-toINT64 () { 
  param ($ip) 
 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
 
function INT64-toIP() { 
  param ([int64]$int) 

  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
} 
 
if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) } 
if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 
 
if ($ip) { 
  $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
  $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
} else { 
  $startaddr = IP-toINT64 -ip $start 
  $endaddr = IP-toINT64 -ip $end 
} 
 
 
for ($i = $startaddr; $i -le $endaddr; $i++) 
{ 
  INT64-toIP -int $i 
}

}

function IP-toINT64 () { 
  param ($ip) 
 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
#END Ip Address Functions

#IP Discovery functions
function GetIPAddressesHashTable {
    param ([string]$vnetName,
           [string]$ResourceGroupName, 
           [string]$AddressSpace) #Address Space in CIDR format
    #Get the vnet
    
    $vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupName
    #Get IPAddresses in first vNet
    $OutputHT = [ordered]@{}
    $OutputHT.Clear()
    #Get IP Addresses
    $IPs = Get-IPRange -ip $AddressSpace.Split("/")[0] -cidr $AddressSpace.split("/")[1]
     ForEach ($IP in $IPs){
        $OutputHT.Add($IP,"Available")
     }
    #Check all of the subnets in the vnet.  If they contain IPs in our list of IPs, associate them with that IP in our hastable.
    ForEach ($subnet in $vnet.Subnets){
        #Get the IPs for each subnet
        $SubnetIPs=Get-IPrange -ip $subnet.addressPrefix.Split("/")[0] -cidr $subnet.addressPrefix.Split("/")[1]
        #Assign Subnet Names to IPs in the IP Hastable
        ForEach ($SubnetIP in $SubnetIPs){
            #Find the IP address in our array of objects.
            If ($OutputHT.Contains($SubnetIP)){
                $OutputHT[$subnetIP]=$subnet.Name
            }
        }
    }
    return $OutputHT
}

function FindNextAvailableSubnet {
    param ([System.Collections.Specialized.OrderedDictionary]$IPHT, #IP Hashtable returned by GetIPAddressesHashTable
           [int]$cidr) #Bits in subnet mask
    #Get the number of IPs we need
    $numberOfIPs = (Get-IPrange -ip 10.10.0.0 -cidr $cidr).Count  #We use our Get-IP Range function to get a generic list of IPS and then count them.  This feels cheap but it works.
    $AvailableIPCounter = 0
    $StartingIP = ""
    #Get the valid starting 4th octets based on subnet bits
    $ipcounter = $null
    $validStartOctet = $null
    switch ($cidr){
        29{$validStartOctet = 1..32 | %{$ipcounter+=8;$ipcounter };$validStartOctet += 0}
        28{$validStartOctet = 1..16 | %{$ipcounter+=16;$ipcounter };$validStartOctet += 0}
        27{$validStartOctet = 1..8 | %{$ipcounter+=32;$ipcounter };$validStartOctet += 0}
        26{$validStartOctet = 1..4 | %{$ipcounter+=64;$ipcounter };$validStartOctet += 0}
        25{$validStartOctet = 1..2 | %{$ipcounter+=128;$ipcounter };$validStartOctet += 0}
        24{$validStartOctet = 0}
    }

    ForEach ($item in $IPHT.GetEnumerator()){
        If ($AvailableIPCounter -eq 0 -and $item.Value -eq "Available") { #If this condition is true we have found the potential first avaiable IP address.
            $StartingIP = $item.key
            $AvailableIPCounter = 1  #Start the counter at 1 IP
        }
        If ($AvailableIPCounter -gt 0 -and $item.value -eq "Available") { 
            $AvailableIPCounter += 1 #Increment the counter.
            If ($AvailableIPCounter -eq $numberOfIPs){ #Check to see if we have all the contiguous IPs we need.  If so, return the subnet in cidr format
                #Added Valid CIDR Block test.
                If ($validStartOctet -contains $StartingIP.Split(".")[3]) {
                    Return $StartingIP + "/" + $cidr
                }
            }
            
        } Else { #If the next IP was not available and we don't have all the IPs we need, set counter back to 0.
                $AvailableIPCounter = 0
                
        }
    }
    #If we loop through alll the IP Addresses in the subnet and not enough contiguous IPs are found, then there are not enough contiguous IPs for the requested subnet size.
    return "Not enough contiguous IPs available"
}
#End IP Discovery functions

#Main
If ($NextSub){ #If this parameter is used then we find the next subnet
    $ht = GetIPAddressesHashTable -vnetName $vnetName -ResourceGroupName $ResourceGroupName -AddressSpace $AddressSpace
    FindNextAvailableSubnet -IPHT $ht -cidr $NextSub
} Else { #If the param is not used, we return a list of IPs in the Address space.
    GetIPAddressesHashTable -vnetName $vnetName -ResourceGroupName $ResourceGroupName -AddressSpace $AddressSpace
}




