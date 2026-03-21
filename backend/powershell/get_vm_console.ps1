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
    
    # Get VM console information using Hyper-V COM APIs
    # Note: Hyper-V doesn't provide direct web streaming, but we can get console access info
    
    # Get VM GUID for console connection
    $vmId = $vm.Id
    
    # Get VM state
    $vmState = $vm.State.ToString()
    
    # Get VM console settings
    $consoleSettings = $vm | Get-VMVideo
    
    $result = @{
        success = $true
        vmName = $Name
        vmId = $vmId.ToString()
        state = $vmState
        canConnect = ($vmState -eq "Running")
        consoleInfo = @{
            resolutionX = if ($consoleSettings) { $consoleSettings.HorizontalResolution } else { $null }
            resolutionY = if ($consoleSettings) { $consoleSettings.VerticalResolution } else { $null }
        }
    }
    
    $result | ConvertTo-Json -Depth 10
}
catch {
    $errorResult = @{
        success = $false
        error = $_.Exception.Message
    }
    
    $errorResult | ConvertTo-Json
    exit 1
}

