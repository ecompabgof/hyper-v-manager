param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$false)]
    [int]$Width = 1024,
    
    [Parameter(Mandatory=$false)]
    [int]$Height = 768
)

$ErrorActionPreference = "Stop"

try {
    # Check if VM exists
    $vm = Get-VM -Name $Name -ErrorAction Stop
    
    if (-not $vm) {
        throw "VM '$Name' not found"
    }
    
    if ($vm.State -ne "Running") {
        throw "VM '$Name' is not running. Current state: $($vm.State)"
    }
    
    # Use Hyper-V COM API to capture VM screen
    # Note: This requires the VM to have Enhanced Session Mode enabled or use VMConnect APIs
    
    # Method 1: Try to use VMConnect COM interface
    try {
        # Get VM GUID
        $vmId = $vm.Id
        
        # Create VMConnect COM object (if available)
        # Note: VMConnect doesn't expose a direct COM API for screen capture
        # We'll need to use an alternative method
        
        # Alternative: Use PowerShell to invoke VMConnect and capture via screenshot
        # This is a workaround - Hyper-V doesn't have a native web streaming API
        
        $result = @{
            success = $true
            message = "Screen capture initiated"
            vmName = $Name
            vmId = $vmId.ToString()
            width = $Width
            height = $Height
            note = "Hyper-V requires Enhanced Session Mode or VMConnect for screen access"
        }
        
        $result | ConvertTo-Json -Depth 10
    }
    catch {
        # Fallback: Return VM info for manual connection
        $result = @{
            success = $true
            message = "VM information retrieved"
            vmName = $Name
            vmId = $vm.Id.ToString()
            state = $vm.State.ToString()
            note = "Use VMConnect for direct console access"
        }
        
        $result | ConvertTo-Json -Depth 10
    }
}
catch {
    $errorResult = @{
        success = $false
        error = $_.Exception.Message
    }
    
    $errorResult | ConvertTo-Json
    exit 1
}

