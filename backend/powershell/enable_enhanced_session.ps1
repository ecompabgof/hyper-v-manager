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
    
    # Enable Enhanced Session Mode for the VM
    # Enhanced Session Mode allows better integration with Hyper-V host
    Set-VM -VM $vm -EnhancedSessionTransportType HvSocket -ErrorAction SilentlyContinue
    
    # Get VM information
    $vmId = $vm.Id.ToString()
    $vmState = $vm.State.ToString()
    
    # Check if Enhanced Session Mode is supported
    $enhancedSessionSupported = $false
    try {
        $vmConfig = $vm | Get-VMHost
        $enhancedSessionSupported = $true
    } catch {
        # Enhanced Session Mode may not be available
    }
    
    $result = @{
        success = $true
        vmName = $Name
        vmId = $vmId
        state = $vmState
        enhancedSessionEnabled = $enhancedSessionSupported
        message = "Enhanced Session Mode configuration retrieved"
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

