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
    
    # Get the local computer name (Hyper-V host)
    $hostName = $env:COMPUTERNAME
    
    # VMConnect.exe path
    $vmconnectPath = "$env:SystemRoot\System32\vmconnect.exe"
    
    if (-not (Test-Path $vmconnectPath)) {
        throw "VMConnect.exe not found at $vmconnectPath"
    }
    
    # Launch VMConnect with VM name
    # VMConnect syntax: vmconnect.exe <hostname> <vmname>
    Start-Process -FilePath $vmconnectPath -ArgumentList $hostName, $Name -ErrorAction Stop
    
    $result = @{
        success = $true
        message = "VMConnect launched for VM '$Name'"
        vmName = $Name
        hostName = $hostName
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

