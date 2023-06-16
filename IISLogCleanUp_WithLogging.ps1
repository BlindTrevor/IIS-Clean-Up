# #############################################################################
# GET UPDATE COUNTS - POWERSHELL
# NAME: IISLogCleanUp_WithLogging.ps1
# 
# AUTHOR:  Andrew Samuel
# DATE:  12/07/2019
# 
# COMMENT:  This script will check the IIS Log Files and remove any log files
#           that are older than the specified number of days within the script.
#           It also shows a progress bar and logs results to the Application
#           Log in Windows Event Viewer under the specified EventID. Once the
#           script has run, it will output a table showing the results.
#
# VERSION HISTORY
# 1.0 2019.07.12 Initial Version.
#
# #############################################################################

### Set Custom Variables ###
	$logfileMaxAge = 28 #Maximum age of log files in days to keep
	$eventId = 49500 #Event ID to log events under
	
### Set Fixed Variables ###
	$website_i = 0
	$returnObj = @()

### Create Nexus Application Source, if required ###
	New-EventLog -LogName Application -Source "IIS Log Cleanup Script" -ErrorAction SilentlyContinue

### Check for excess IIS Log Files and Delete if Necessary ###
	Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Removing Old IIS Log Files"
	Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Checking IIS Is Installed"
	if ((Get-WindowsFeature Web-Server).InstallState -eq "Installed") {
		Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "IIS Is Installed"
		Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Import WebAdministration Module"
		Import-Module WebAdministration
		Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "WebAdministration Module Imported Succesfuly"
		$websiteArray = $(Get-Website)
		Write-Progress -id 1 -activity "Clearing IIS Log Files - Retaining Last $($logfileMaxAge) Days . . ." -status "Completed: $website_i of $($websiteArray.Count)" -percentComplete (($website_i / $websiteArray.Count)  * 100)
		Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Iterate through all websites"
		foreach($website in $websiteArray){
			Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Checking logs for $($website.name) (ID: $($website.id))"
			$folder="$($website.logFile.directory)\W3SVC$($website.id)".replace("%SystemDrive%",$env:SystemDrive)
			Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Checking logs exist for $($website.name) (ID: $($website.id))"
			$files_i = 0
            if (Test-Path $folder) {
			    Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Logs exist for $($website.name) (ID: $($website.id)) - clearning logs older than $($logfileMaxAge)"
                $files = Get-ChildItem $folder -Filter *.log
				Write-Progress -ParentId 1 -activity "Removing Old Log Files . . ." -status "Deleted: $files_i of $($files.Count) for: $($website.name) (ID: $($website.id))" -percentComplete (($files_i / $files.Count)  * 100)
			    foreach($file in $files){
				    if($file.LastWriteTime -lt (Get-Date).AddDays(-1*$logfileMaxAge)){
				    	Remove-Item $file.FullName
					    $files_i++
						Write-Progress -ParentId 1 -activity "Removing Old Log Files . . ." -status "Deleted: $files_i of $($files.Count) for: $($website.name) (ID: $($website.id))" -percentComplete (($files_i / $files.Count)  * 100)
				    }
			    }
            }else{
			    Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "No logs exist for $($website.name) (ID: $($website.id)) - Skipping website logs"
            }
			Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Removed $($files_i) logs for $($website.name) (ID: $($website.id))"
			$obj = New-Object psobject -Property @{"WebsiteName" = $website.name;"WebsiteID" = $website.id;"DeletedCount" = $files_i}
			$returnObj += $obj | select WebsiteName,WebsiteID,DeletedCount
			$website_i++
			Write-Progress -id 1 -activity "Clearing IIS Log Files - Retaining Last $($logfileMaxAge) Days . . ." -status "Completed: $website_i of $($websiteArray.Count)" -percentComplete (($website_i / $websiteArray.Count)  * 100)
		}
		Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "Finished Removing Old IIS Log Files"
	}else{
		Write-EventLog -LogName "Application" -Source "IIS Log Cleanup Script" -EventID $eventId -EntryType Information -Message "IIS Is Not Installed"
	}
	$returnObj
