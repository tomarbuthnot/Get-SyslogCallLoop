
Import-Module C:\PowerShell\Get-SyslogCallLoop -Force

$EndDate = Get-Date

$StartDate = $EndDate.AddDays(-1)


# [datetime]$StartDate = "6/24/2014 9:00"

# [datetime]$EndDate = "6/24/2014 10:00"

# clear matches
$matches = $null

$matches = Get-SyslogCallLoop -SyslogDirectory D:\KiwiSyslog -StartDate $StartDate -EndDate $EndDate -CopyMatchingSyslogsToDirectory D:\PossibleLoops -Verbose

# Write Matches to host
$matches | select-object UniqueInviteCount,SIPString,LogFile | format-table -autosize


$smtp = 'smtp.domain.com'
$emailFrom = 'LoopChecker-lon0618@domain.com'
$emailTo = @('bob.smith@domain.com','jon.smith@domain.com','alex.smith@domain.com','Sam.Smith@domain.com')
$emailCC = @('Sarah.Smith@domain.com')
$subject = 'Possible call loops found in last 24 hours in Sonus syslog files: lon0618'


# HTML styling for output. credit http://exchangeserverpro.com/powershell-html-email-formatting/
$style = '<style>BODY{font-family: Arial; font-size: 10pt;}'
$style = $style + 'TABLE{border: 1px solid black; border-collapse: collapse;}'
$style = $style + 'TH{border: 1px solid black; background: #dddddd; padding: 5px; }'
$style = $style + 'TD{border: 1px solid black; padding: 5px; }'
$style = $style + '</style>'

If ($matches -ne $null)
    {

    # build html body for email
    [string]$bodyhtml = $matches | select-object UniqueInviteCount,SIPString,LogFile | ConvertTo-Html -Head $style

    Send-MailMessage -From $emailFrom -To $emailTo -cc $emailCC -Subject $subject -BodyAsHtml $bodyhtml -SmtpServer $smtp -Verbose -ErrorVariable $emailerrror
    
    If ($emailerrror -ne $null)
        {
        $emailerrror | Out-File D:\PossibleLoops\Send_email_error.txt
        }

   } # close email loop 

