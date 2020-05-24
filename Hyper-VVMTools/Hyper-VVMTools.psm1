function New-VMFromTemplate {

    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("WIN16TEMPLATE", "WIN16CORESVR_TEMPLATE", "CENTOS_TEMPLATE")]
        $Template,
        [string]$SnapFilePath = "B:\Hyper-V\Virtual Machines\",
        [string]$SmartPagePath = "B:\Hyper-V\Virtual Machines\",
        [string]$VHDPath = "B:\Hyper-V\virtual hard disks\",
        [string][Parameter(Mandatory=$true)]$VMName
    )

    if ($VHDPath -contains "$Template.vhdx") {

        Write-Host "Removing Unnammed VM..."

        Remove-VMAll -VMName $Template

    }

    else{
        

        $vmcxName= Get-ChildItem -File -Path  "A:\Hyper-V\$Template\Virtual Machines\*.vmcx"

        $VM = Import-VM -Path $vmcxName.FullName -GenerateNewID -Copy -SnapshotFilePath $SnapFilePath -SmartPagingFilePath $SmartPagePath -VhdDestinationPath $VHDPath

        $Splitpoint = $($VM.HardDrives.Path).lastIndexOf('\')

        $VHDName = "$(($VM.HardDrives.Path).Substring(0,$Splitpoint))\$VMName.vhdx"

        Rename-VM $($VM.Name) -NewName $VMName

        Rename-Item -Path "$($VM.HardDrives.Path)" -NewName $VHDName

        Get-VMHardDiskDrive -VMName $($VM.Name) | Set-VMHardDiskDrive -Path $VHDName 

        

    
    }
}

function Export-VMTemplate {
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

        Remove-VMCheckpoint -VMName $VMName -IncludeAllChildSnapshots

        Write-Host "Deleteing $VMName... at $VMName"

        Remove-VM -Name $VMInfo.Name -Force
        
    }

    catch {

        Write-Host "An error occurred:"

        Write-Host $_.ScriptStackTrace

    }
    
}

