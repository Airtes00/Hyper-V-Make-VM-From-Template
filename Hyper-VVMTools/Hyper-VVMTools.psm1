function New-VMFromTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("WIN16TEMPLATE", "WIN16CORESVR_TEMPLATE", "CENTOS_TEMPLATE")]
        $Template,
        [string]$SnapFilePath = "A:\Hyper-V\Virtual Machines\",
        [string]$SmartPagePath = "A:\Hyper-V\Virtual Machines\",
        [string]$VHDPath = "A:\Hyper-V\virtual hard disks\",
        [string[]][Parameter(Mandatory=$true)]$VMName
    )

    foreach ($Name in $VMName){

        $vmcxName= Get-ChildItem -File -Path  "B:\Hyper-V\$Template\Virtual Machines\*.vmcx"

        $VM = Import-VM -Path $vmcxName.FullName -GenerateNewID -Copy -SnapshotFilePath $SnapFilePath -SmartPagingFilePath $SmartPagePath -VhdDestinationPath $VHDPath

        $Splitpoint = $($VM.HardDrives.Path).lastIndexOf('\')

        $VHDName = "$(($VM.HardDrives.Path).Substring(0,$Splitpoint))\$Name.vhdx"

        Rename-VM $($VM.Name) -NewName $Name -Verbose

        Rename-Item -Path "$($VM.HardDrives.Path)" -NewName $VHDName -Verbose

        Get-VMHardDiskDrive -VMName $($VM.Name) | Set-VMHardDiskDrive -Path $VHDName -Verbose 

    }
}

function Export-VMTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$VMName,
        [string]$Destination = "A:\Hyper-V\"
    )
    
    try {
        $VMInfo = Get-VM $VMName

        if ($VMInfo.Status -eq  "On"){

            Stop-VM -VM $VMInfo -AsJob | Wait-Job -Timeout 30

        }

        Remove-VMDvdDrive $VMInfo.DVDDrives

        Remove-VMCheckpoint $VMInfo

        Export-VM -Name $VMName -Path $Destination
        
    }
    catch {

        Write-Host "An error occurred:"

        Write-Host $_.ScriptStackTrace  

    }
    
}

function Remove-VMAll {
    [CmdletBinding()]
    param (
        [String]$VMName
    )

    $VMInfo= Get-VM -VMName $VMName
    
    try {

        if ($VMInfo.Status -eq  "On"){

            Stop-VM -VM $VMInfo -AsJob | Wait-Job -Timeout 30
    
        }

        Write-Host "Deleting VM harddrive at ($VMInfo.HardDrives).Path"

        remove-Item -Path ($VMInfo.HardDrives).Path

        Write-Host "Deleting $VMName checkpoints"

        Remove-VMCheckpoint -VMName $VMName 

        Write-Host "Deleteing $VMName... at $VMName"

        Remove-VM -Name $VMInfo.Name -Force
        
    }

    catch {

        Write-Host "An error occurred:"

        Write-Host $_.ScriptStackTrace

    }
    
}

