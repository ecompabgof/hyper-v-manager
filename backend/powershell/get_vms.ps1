$ErrorActionPreference = "Stop"

try {
    # Get all VMs
    $vms = Get-VM -ErrorAction Stop
    
    # Build array of VM objects
    $vmList = @()
    
    foreach ($vm in $vms) {
        try {
            # Get VM metrics
            $metrics = $vm | Get-VMProcessor | Select-Object -First 1
            $memory = $vm | Get-VMMemory
            
            # Calculate uptime
            $uptime = $null
            if ($vm.State -eq "Running") {
                $uptime = (Get-Date) - $vm.Uptime
                $uptimeString = "{0:D2}:{1:D2}:{2:D2}" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
            } else {
                $uptimeString = "N/A"
            }
            
            $vmObj = @{
                Name = $vm.Name
                State = $vm.State.ToString()
                CPUUsage = "N/A"  # CPU usage requires performance counters
                MemoryAssigned = [math]::Round($memory.Assigned / 1MB, 2)
                Uptime = $uptimeString
            }
            
            $vmList += $vmObj
        }
        catch {
            # If we can't get details for a VM, still include it with basic info
            $vmObj = @{
                Name = $vm.Name
                State = $vm.State.ToString()
                CPUUsage = "N/A"
                MemoryAssigned = "N/A"
                Uptime = "N/A"
            }
            
            $vmList += $vmObj
        }
    }
    
    # Return as JSON
    $result = @{
        success = $true
        vms = $vmList
    }
    
    $result | ConvertTo-Json -Depth 10
}
catch {
    $errorResult = @{
        success = $false
        error = $_.Exception.Message
        vms = @()
    }
    
    $errorResult | ConvertTo-Json
    exit 1
}

