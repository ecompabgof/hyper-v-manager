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
    
    # Stop VM if running
    if ($vm.State -ne "Off") {
        Stop-VM -VM $vm -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
    }
    
    # Remove VM (this will also remove associated VHDs if configured)
    Remove-VM -VM $vm -Force -ErrorAction Stop
    
    $result = @{
        success = $true
        message = "VM '$Name' removed successfully"
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

