#Repo-Link
#https://github.com/clumnah/Operationalize-MSSQL-Backups-With-Rubrik-Security-Cloud/tree/main/content
Set-ExecutionPolicy -Scope CurrentUser ByPass
#$sp = Import-csv "\\bos-cifs-lif-nrpl-n18\SQLDB_Decommissions_1$\Harminder\Scripts\Rubrik\shp\Restore196DVRubrikMultiplefiles.csv" 
$sp = Import-csv "\\bos-cifs-lif-nrpl-n18\SQLDB_Decommissions_1$\Harminder\Scripts\Rubrik\shp\SharepointRestore\SharePointRestoreDetails.csv"
$i = 0
$sp | ForEach-Object {

if($sp[$i].flag -eq 'Y'){

Import-Module RubrikSecurityCloud
Connect-RSC
## Getting Cluster Name in object
$ClusterName = "BOSRUBCLS001"
$RscCluster = Get-RscCluster -Name $ClusterName
#$RscCluster
#getting hostname in rubrik object
$HostName = "BOSCLS314PV"
$RscMssqlInstance = Get-RscMssqlInstance -RscCluster $RscCluster -HostName $HostName
#$RscMssqlInstance
#get database details
$DatabaseName = $sp[$i].dbname
$RscMssqlDatabase = Get-RscMssqlDatabase -Name $DatabaseName  -RscMssqlInstance $RscMssqlInstance
#$RscMssqlDatabase
#get latest snapshot
$RecoveryDateTime = Get-RscMssqlDatabaseRecoveryPoint -RscMssqlDatabase $RscMssqlDatabase -LastFull
#$RecoveryDateTime
#Get Target Instance Name
$HostName = "BOSSQL371UV.axisspecialty.net"
$TargetMssqlInstance = Get-RscMssqlInstance -RscCluster $RscCluster -HostName $HostName
#$TargetMssqlInstance
$RscMssqlDatabaseFiles = Get-RscMssqlDatabaseFiles -RscMssqlDatabase $RscMssqlDatabase -RecoveryDateTime $RecoveryDateTime
#Write-Output "Below are the current files of the DB";
#Write-Output "#         #          #        #";
#$RscMssqlDatabaseFiles
$TargetFilePaths = @()
foreach($File in $RscMssqlDatabaseFiles){
    If ($File.FileType -eq 'MSSQL_DATABASE_FILE_TYPE_DATA'){
        If($File.FileId -eq '1'){
           $TargetDataPath = @{
            exportPath = $sp[$i].datapath
            logicalName = $File.LogicalName
            newFilename = $sp[$i].datafile1
        }
        $TargetFilePaths += $TargetDataPath
        
        }
        If($File.FileId -eq '3'){
           $TargetDataPath = @{
            exportPath = $sp[$i].datapath2
            logicalName = $File.LogicalName
            newFilename = $sp[$i].datafile2
        }
        $TargetFilePaths += $TargetDataPath
        
        }
        

    }

    If ($File.FileType -eq 'MSSQL_DATABASE_FILE_TYPE_LOG'){
        $TargetLogPath = @{
            exportPath = $sp[$i].logpath
            logicalName = $File.LogicalName
            newFilename = $sp[$i].logfile
        } 
        $TargetFilePaths += $TargetLogPath
    }
}
#Write-Output "Below are the updated files of the DB";
#Write-Output "#         #          #        #";
#$TargetFilePaths
$NewRscMssqlExport = @{
    RscMssqlDatabase = $RscMssqlDatabase
    RecoveryDateTime = $RecoveryDateTime
    TargetMssqlInstance = $TargetMssqlInstance
    TargetDatabaseName = $sp[$i].restoreas
    TargetFilePaths = $TargetFilePaths
    Overwrite = $true
    FinishRecovery = $true
}

#New-RscMssqlExport @NewRscMssqlExport



}
else {
$outstring = "The Database " +$sp[$i].dbname+" is not flagged for restore."
Write-Output $outstring

}

#if($sp.size -eq 'L'){

#Write-Output "Sleeping for 1 hour as a bigger DB restore is running"
#Start-Sleep 3600

#}

$i= $i + 1

}

#$body = 'SharePoint Restore Completed Check Restore DB count. The Count should match the file we use for restore.'
#
#Send-MailMessage -To axisdba@axiscapital.com,DL-SharePointSupport@axiscapital.com -from axisdba@axiscapital.com -Subject 'SharePoint Weekly Auto Restore UAT SUCCESS' -body $body -SmtpServer smtp.axisspecialty.net
