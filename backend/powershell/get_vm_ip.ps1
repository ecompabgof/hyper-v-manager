param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$ErrorActionPreference = "Stop"

try {
    # Check if VM exists
    $vm = Get-VM -Name $Name -ErrorAction Stop
    
    if (-not $vm) {
        throw "VM '$Name' not found"
    }
    
    # Get VM network adapters
    $networkAdapters = $vm | Get-VMNetworkAdapter -ErrorAction SilentlyContinue
    
    $ipAddresses = @()
    
    if ($networkAdapters) {
        foreach ($adapter in $networkAdapters) {
            # Try to get IP address from the VM
            # Note: This requires the VM to be running and have integration services
            if ($adapter.IPAddresses) {
                foreach ($ip in $adapter.IPAddresses) {
                    # Filter IPv4 addresses
                    if ($ip -match '^\d+\.\d+\.\d+\.\d+$') {
                        $ipAddresses += $ip
                    }
                }
            }
        }
    }
    
    # If no IP found and VM is running, try alternative methods
    if ($ipAddresses.Count -eq 0 -and $vm.State -eq "Running") {
        # Try to get IP via WMI (requires VM Integration Services)
        try {
            $vmComputer = Get-WmiObject -Namespace "root\virtualization\v2" -Class "Msvm_ComputerSystem" -Filter "ElementName='$Name'" -ErrorAction SilentlyContinue
            if ($vmComputer) {
                $vmSettings = Get-WmiObject -Namespace "root\virtualization\v2" -Query "ASSOCIATORS OF {$vmComputer} WHERE AssocClass=Msvm_SystemDevice ResultClass=Msvm_SyntheticEthernetPortSettingData" -ErrorAction SilentlyContinue
                # This method is complex and may not always work
            }
        } catch {
            # Ignore errors
        }
    }
    
    $result = @{
        success = $true
        vmName = $Name
        ipAddresses = $ipAddresses
        state = $vm.State.ToString()
        hasNetworkAdapter = ($networkAdapters -ne $null)
    }
    
    $result | ConvertTo-Json
}
catch {
    $errorResult = @{
        success = $false
        error = $_.Exception.Message
        ipAddresses = @()
    }
    
    $errorResult | ConvertTo-Json
    exit 1
}

