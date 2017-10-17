#=========================================================================================================
# Version: 0.0.5
#=========================================================================================================

# Config / Global vars
$duplicacyMasterDir="D:\DuplicacyMasterDir"	                      # Logfiles will go here, subdir /Logs
$repoLocations=@("D:\DuplicacyTest", "D:\DuplicacyTest2")         # All repos to backup
$duplicacyExe="D:\DuplicacyMasterDir\duplicacy_win_x64_2.0.9.exe" # Path to .exe
$duplicacyGlobalOptions="-log"                                    # Global options to add to duplicacy commands
$backupCmd="backup -stats"                                        # Backup command. TODO: Needs improvement, we should use some sort of backup-class instead to have per-repo specifics here...

# Pushover, leave empty for none
$sendPushoverOnSuccess=$true
$pushoverUserKey=""
$pushoverToken=""
