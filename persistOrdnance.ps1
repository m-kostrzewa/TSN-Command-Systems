#
# README
#
# This is a companion script (and .exe file) to the PersistentOrdnance.xml module.
# The .xml module, when activate via TSN-Command-Systems, will periodically record ship ordnance to mission log file, and
# executes a program that updates the MISS_TSN-Command.xml file with the ordnance information from the log file.
#
#
# SETUP
#
# 1. Artemis server must be ran as administrator so that it can write to the log file
# (log file is wiped at mission start)
# 2. Place ./persistOrdnance.exe next to MISS_TSN-Command.xml
#
#
# DEVELOPMENT
#
# We need an .exe, because Artemis doesn't want to spawn a powershell process.
# Thankfully, it's easy to convert a powershell script into an exe
# $ Install-Module ps2exe
# $ Invoke-PS2EXE .\persistOrdnance.ps1 ./persistOrdnance.exe
#

$scriptLog = "./dat/Missions/MISS_TSN-Command/persistOrdnanceLog.txt"

$StartTime = Get-Date
echo((Get-Date).GetDateTimeFormats()[40] + "persistOrdnance.ps1 starting") >> $scriptLog

$xmlPath = "./dat/Missions/MISS_TSN-Command/MISS_TSN-Command.xml"
$logPath = "./dat/Missions/MISS_TSN-Command/MISS_TSN-Command_LOG.txt"

# hardcoded paths for now
[xml]$xmlDoc = Get-Content $xmlPath
$log = Get-Content $logPath


# For every player slot
for ($i = 0; $i -lt 8; $i++) {

    # Parse log line

    # Example log looks like this (see PersistentOrdnance.xml for details).
# *** mission time: 20 sec ***
# ship 0: 8.0, 2.0, 6.0, 4.0, 4.0, 5.0, 5.0, 5.0
# ship 1: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 2: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 3: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 4: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 5: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 6: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 7: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# *** mission time: 30 sec ***
# ship 0: 6.0, 2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 5.0
# ship 1: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 2: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 3: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 4: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 5: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 6: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
# ship 7: 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

    $shipLogLine = $log | Select-String "ship $i" | Select-Object -Last 1

    if (!$shipLogLine) {
        echo("no data, return early")  > log.txt
        return
    }

    $ordnance = ([string]$shipLogLine).Split(":")[1].Split(",")

    # Find the "ShipX Configuration" node in the XML
    $shipConfigNode = $xmlDoc.mission_data.event | Where-Object { $_.name -eq "Ship" + ($i+1) + " Configuration" }

    # Substitute ordnance counts.
    # |nHoming|, |nNuke|, |nMine|, |nEMP|, |nShk|, |nBea|, |nPro|, |nTag|
    # The reason we cast to int and then to string is because XML wants string, but we remove the decimal point first.
    ($shipConfigNode.set_object_property | Where-Object {$_.property -eq "countHoming"}).value =[string]([int]($ordnance[0]))
    ($shipConfigNode.set_object_property | Where-Object {$_.property -eq "countNuke"}).value =  [string]([int]($ordnance[1]))
    ($shipConfigNode.set_object_property | Where-Object {$_.property -eq "countMine"}).value =  [string]([int]($ordnance[2]))
    ($shipConfigNode.set_object_property | Where-Object {$_.property -eq "countEMP"}).value =   [string]([int]($ordnance[3]))
    ($shipConfigNode.set_object_property | Where-Object {$_.property -eq "countShk"}).value =   [string]([int]($ordnance[4]))
    ($shipConfigNode.set_object_property | Where-Object {$_.property -eq "countBea"}).value =   [string]([int]($ordnance[5]))
    ($shipConfigNode.set_object_property | Where-Object {$_.property -eq "countPro"}).value =   [string]([int]($ordnance[6]))
    ($shipConfigNode.set_object_property | Where-Object {$_.property -eq "countTag"}).value =   [string]([int]($ordnance[7]))
}

# Save method needs absolute path for some reason
$absPath = Resolve-Path -Path $xmlPath
$xmlDoc.Save($absPath.Path)

$RunTime = New-TimeSpan -Start $StartTime -End (Get-Date) 
echo((Get-Date).GetDateTimeFormats()[40] + "- MISS_TSN-Command.xml (" + $absPath.Path + ") updated, took " +  $RunTime.Seconds + " seconds + " + $RunTime.Milliseconds + " miliseconds") >> $scriptLog
