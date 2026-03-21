param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$true)]
    [int]$MemoryMB,
    
    [Parameter(Mandatory=$true)]
    [int]$CPUCount,
    
    [Parameter(Mandatory=$true)]
    [int]$DiskGB,
    
    [Parameter(Mandatory=$true)]
    [string]$SwitchName,
    
    [Parameter(Mandatory=$false)]
    [string]$IsoPath
)

# Error handling
$ErrorActionPreference = "Stop"

try {
    # Validate inputs
    if ($MemoryMB -lt 512) {
        throw "Memory must be at least 512 MB"
    }
    
    if ($CPUCount -lt 1) {
        throw "CPU count must be at least 1"
    }
    
    if ($DiskGB -lt 1) {
        throw "Disk size must be at least 1 GB"
    }
    
    # Check if VM already exists
    $existingVM = Get-VM -Name $Name -ErrorAction SilentlyContinue
    if ($existingVM) {
        throw "A VM with the name '$Name' already exists"
    }
    
    # Check if switch exists
    $switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if (-not $switch) {
        throw "Virtual switch '$SwitchName' does not exist"
    }
    
    # Create new VM
    $newVM = New-VM -Name $Name -MemoryStartupBytes ($MemoryMB * 1MB) -Generation 1 -ErrorAction Stop
    
    # Set processor count
    Set-VMProcessor -VM $newVM -Count $CPUCount -ErrorAction Stop
    
    # Create virtual hard disk
    $vhdPath = Join-Path $newVM.Path "$Name.vhdx"
    New-VHD -Path $vhdPath -SizeBytes ($DiskGB * 1GB) -ErrorAction Stop | Out-Null
    
    # Attach VHD to VM
    Add-VMHardDiskDrive -VM $newVM -Path $vhdPath -ErrorAction Stop
    
    # Connect VM to switch
    Connect-VMNetworkAdapter -VM $newVM -SwitchName $SwitchName -ErrorAction Stop
    
    # Mount ISO if provided
    $isoMounted = $false
    if ($IsoPath -and (Test-Path $IsoPath)) {
        Add-VMDvdDrive -VM $newVM -Path $IsoPath -ErrorAction Stop
        $isoMounted = $true
        Write-Host "ISO monté: $IsoPath" -ForegroundColor Green
    }
    
    # Return success message as JSON
    $message = "VM '$Name' created successfully"
    if ($isoMounted) {
        $isoFileName = Split-Path -Leaf $IsoPath
        $message += " with ISO '$isoFileName' mounted"
    }
    
    $result = @{
        success = $true
        message = $message
        vmName = $Name
        isoMounted = $isoMounted
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

