#=========================================================================================================
# TODO: We should not exit upon first fail but instead continue and back up as much as possbile
# TODO: Check if exe is running already: Get-Process | ?{$_.path -eq "C:\Program Files (x86)\Notepad++\notepad++.exe"}
# Version: 0.0.5
#=========================================================================================================

# Import config
. .\DuplicacyConfig.ps1

# Main
function main {
	logToFile
	$startDir=(Get-Item -Path ".\" -Verbose).FullName
	log "Start"
	
	Try{
		$msg = ""
		foreach($repo in $repoLocations){
			log ""
			logDivider "Repo: $repo"
			cd $repo
			log "Running Duplicacy backup ..."

			Invoke-Expression "& '$duplicacyExe' $duplicacyGlobalOptions $backupCmd" | Tee-Object -Variable dupOut
			if($lastexitcode){
				throw "Duplicacy non zero exit code"
			}
			logDivider "Done backing up: $repo"
			$stats = logStats $dupOut
			$msg += "$repo :: $stats `n"
		}
		if($sendPushoverOnSuccess){
			sendPushover "Backup success" $msg
		}
		log "All done."
	}
	Catch
	{
		logDivider "Exception!" true
		log $_.Exception.Message
		sendPushover "Backup exception" "$repo : $_"
		logDivider "Exception!"
		exit 42
	}
	Finally 
	{	
		Stop-Transcript
		cd $startDir
	}
}

# Functions
function logToFile {
	$logdir="$duplicacyMasterDir\Logs"
	if(!(Test-Path -Path $logdir )){
		New-Item -ItemType directory -Path $logdir
	}
	$date=(Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
	$logpath="$logdir\Logfile_$date.txt"
	log "Logging to: $logpath"
	$ErrorActionPreference="SilentlyContinue"
	Stop-Transcript | out-null
	$ErrorActionPreference = "Stop"
	Start-Transcript -path $logpath -append
}

function log($str) {
	$date=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
	Write-Output "$(date): $str"
}

function logDivider($str, $newline = $false){
	if($newline){
		log ""
	}
	log("# == $str ".PadRight(120, '='))
}

function sendPushover($title,$msg){
	if([string]::IsNullOrEmpty($pushoverUserKey)){ return }
	
	$uri = 'https://api.pushover.net/1/messages.json'
	$parameters = @{
		token = $pushoverToken
		user = $pushoverUserKey
		title = $title
		message = $msg
	}
	
	# Uncomment to see post data
	#$str = $parameters | Out-String
    #Write-host $str
	
	$parameters | Invoke-RestMethod -Uri $uri -Method Post | out-null
}

function logStats($dupOutput) {
	try {
		$backupStats = $dupOutput.Split("`n") | Select-String -Pattern 'All chunks'
		$match = ([regex]::Match($backupStats,'(.*)total, (.*) bytes; (.*) new, (.*) bytes, (.*) bytes'))
		$tot = formatData $match.Groups[2].Value
		$new = formatData $match.Groups[4].Value
		$upload = formatData $match.Groups[5].Value
	return "$tot, $new -> upload $upload"
	} Catch {
		return "Could not parse stats"
	}
}

function formatData($str){
	$last = $str[-1]
	$foo =  ($str -replace ".$")/1000
	$bar = [int]$foo
	if($last -eq "K"){
		return "$bar MB"
	} elseif ($last -eq "M"){
		return "$bar GB"
	}
	return $str
	
}

# Entrypoint
main