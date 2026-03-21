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
    
    # Check current state
    if ($vm.State -eq "Running") {
        $result = @{
            success = $true
            message = "VM '$Name' is already running"
        }
        $result | ConvertTo-Json
        exit 0
    }
    
    # Start VM
    Start-VM -VM $vm -ErrorAction Stop
    
    $result = @{
        success = $true
        message = "VM '$Name' started successfully"
    }
    
    $result | ConvertTo-Json
}
catch {
    $errorResult = @{
        success = $false
        error = $_.Exception.Message
    }
    
    $errorResult | ConvertTo-Json
    exit 1
}

