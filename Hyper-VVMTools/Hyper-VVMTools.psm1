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

        Write-Verbose "Creating the $Template VM."

        $VM = Import-VM -Path $vmcxName.FullName -GenerateNewID -Copy -SnapshotFilePath $SnapFilePath -SmartPagingFilePath $SmartPagePath -VhdDestinationPath $VHDPath -Verbose

        $Splitpoint = $($VM.HardDrives.Path).lastIndexOf('\')

        $VHDName = "$(($VM.HardDrives.Path).Substring(0,$Splitpoint))\$Name.vhdx"

        Write-Verbose "Renaming VM and VHD to $Name."

        Rename-VM $($VM.Name) -NewName $Name -Verbose

        Rename-Item -Path "$($VM.HardDrives.Path)" -NewName $VHDName -Verbose

        Get-VMHardDiskDrive -VMName $($VM.Name) | Set-VMHardDiskDrive -Path $VHDName -Verbose 

    }
}

function Remove-VMAll {
    [CmdletBinding()]
    param (
        [String[]]$VMName
    )
    foreach ($Name in $VMName){

    $VMInfo= Get-VM -VMName $Name

    try {

        if ($VMInfo.Status -eq  "On"){

            Stop-VM -VM $VMInfo -AsJob | Wait-Job -Timeout 30
    
        }

        Write-Host "Deleting VM harddrive at ($VMInfo.HardDrives).Path"

        remove-Item -Path ($VMInfo.HardDrives).Path

        Write-Host "Deleting $Name checkpoints"

        Remove-VMCheckpoint -Name $Name

        Write-Host "Deleteing $Name..."

        Remove-VM -Name $VMInfo.Name -Force
        
    }

    catch {

        Write-Host "An error occurred:"

        Write-Host $_.ScriptStackTrace

        }
        
    }

}