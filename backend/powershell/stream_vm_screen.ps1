param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$ErrorActionPreference = "Continue"

try {
    # Check if VM exists and is running
    $vm = Get-VM -Name $Name -ErrorAction Stop
    
    if (-not $vm) {
        Write-Output "ERROR: VM '$Name' not found"
        exit 1
    }
    
    if ($vm.State -ne "Running") {
        Write-Output "ERROR: VM '$Name' is not running. Current state: $($vm.State)"
        exit 1
    }
    
    # Get VM information
    $vmId = $vm.Id.ToString()
    $vmState = $vm.State.ToString()
    
    # Hyper-V doesn't have a direct screen capture API via PowerShell
    # We need to use Enhanced Session Mode or VMConnect APIs
    # For a web-based solution, we'll use a workaround:
    # 1. Check if Enhanced Session Mode is available
    # 2. Use VMConnect COM interface if possible
    # 3. Fallback to RDP/VNC if configured
    
    # Output JSON with connection info
    $output = @{
        vmName = $Name
        vmId = $vmId
        state = $vmState
        connectionType = "Hyper-V Enhanced Session"
        note = "Hyper-V native screen streaming requires Enhanced Session Mode"
    }
    
    Write-Output ($output | ConvertTo-Json -Compress)
}
catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}

