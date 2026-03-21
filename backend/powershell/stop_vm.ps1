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
    if ($vm.State -eq "Off") {
        $result = @{
            success = $true
            message = "VM '$Name' is already stopped"
        }
        $result | ConvertTo-Json
        exit 0
    }
    
    # Stop VM (force stop if needed)
    Stop-VM -VM $vm -Force -ErrorAction Stop
    
    $result = @{
        success = $true
        message = "VM '$Name' stopped successfully"
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

