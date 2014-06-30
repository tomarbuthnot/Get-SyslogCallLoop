
Import-Module C:\PowerShell\Get-SyslogCallLoop -Force

# $EndDate = Get-Date

# $StartDate = $EndDate.AddDays(-1)


[datetime]$StartDate = "6/25/2014 9:00"

[datetime]$EndDate = "6/25/2014 17:00"

# clear matches
$matches = $null

$matches = Get-SyslogCallLoop -SyslogDirectory D:\KiwiSyslog -StartDate $StartDate -EndDate $EndDate -CopyMatchingSyslogsToDirectory D:\PossibleLoops -Verbose

# Write Matches to host
$matches | select-object UniqueInviteCount,SIPString,LogFile | format-table -autosize


