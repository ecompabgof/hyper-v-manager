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
    
    # Launch VMConnect
    # VMConnect.exe is located in System32 or can be launched via vmconnect command
    $vmconnectPath = "$env:SystemRoot\System32\vmconnect.exe"
    
    if (Test-Path $vmconnectPath) {
        # Get the local computer name (Hyper-V host)
        $hostName = $env:COMPUTERNAME
        
        # Launch VMConnect with the VM name
        Start-Process -FilePath $vmconnectPath -ArgumentList $hostName, $Name -ErrorAction Stop
        
        $result = @{
            success = $true
            message = "VMConnect launched for VM '$Name'"
        }
    } else {
        # Try using vmconnect command directly
        Start-Process -FilePath "vmconnect" -ArgumentList $env:COMPUTERNAME, $Name -ErrorAction Stop
        
        $result = @{
            success = $true
            message = "VMConnect launched for VM '$Name'"
        }
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

