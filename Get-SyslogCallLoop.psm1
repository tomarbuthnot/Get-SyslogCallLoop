

Function Get-SyslogCallLoop {
<#
.SYNOPSIS  
      Searches Syslog files for repeat invite strings with the same telephone number, which may indicate looping calls

.DESCRIPTION  
      Searches Syslog files for repeat invite strings with the same telephone number, which may indicate looping calls
      Uses the regex pattern match 'INVITE sip:\+?([^\n\r@]*)@'

.LINK  
    https://github.com/tomarbuthnot/Get-SyslogCallLoop
                
.NOTES  
	Version:
			0.8
  
	Author/Copyright:	 
			Copyright Tom Arbuthnot - All Rights Reserved
    
	Email/Blog/Twitter:	
			tom@tomarbuthnot.com tomtalks.uk @tomarbuthnot
    
	Disclaimer:   	
			THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
			OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
			While these scripts are tested and working in my environment, it is recommended 
			that you test these scripts in a test environment before using in your production 
			environment. Tom Arbuthnot further disclaims all implied warranties including, 
			without limitation, any implied warranties of merchantability or of fitness for 
			a particular purpose. The entire risk arising out of the use or performance of 
			this script and documentation remains with you. In no event shall Tom Arbuthnot, 
			its authors, or anyone else involved in the creation, production, or delivery of 
			this script/tool be liable for any damages whatsoever (including, without limitation, 
			damages for loss of business profits, business interruption, loss of business 
			information, or other pecuniary loss) arising out of the use of or inability to use 
			the sample scripts or documentation, even if Tom Arbuthnot has been advised of 
			the possibility of such damages.
    
     
	Acknowledgements: 	
    
	Assumptions:	      
			ExecutionPolicy of AllSigned (recommended), RemoteSigned or Unrestricted (not recommended)
    
	Limitations:		  										
    		
	Ideas/Wish list:
			Detects loops based on number of log lines, this can vary, should detect based on timestamp of line 
    
	Rights Required:	

	Known issues:	


.EXAMPLE
		Get-SyslogCallLoop -SyslogDirectory D:\KiwiSyslog -StartDate "6/24/2014 9:00" -EndDate "6/24/2014 10:00" -CopyMatchingSyslogsToDirectory D:\PossibleLoops -Verbose
 
		Description
		-----------
		Get call loops between the two dates, copy relevant logs to D:\PossibleLoops

.EXAMPLE
		 Get-SyslogCallLoop -SyslogDirectory D:\KiwiSyslog -StartDate "6/24/2014 9:00" -EndDate "6/24/2014 10:00" | select-object UniqueInviteCount,SIPString,LogFile | format-table -autosize
 
		Description
		-----------
		Get call loops between two dates and format them as a table

		

#>
  
  
  #############################################################
  # Param Block
  #############################################################
  
  # Sets that -Whatif and -Confirm should be allowed
  [cmdletbinding(SupportsShouldProcess=$true)]
  
  Param 	(
    [Parameter(Mandatory=$true,
    HelpMessage='Directory Syslogs are stored in, will recurse')]
    $SyslogDirectory = 'defaultvalue1',
    
    
    [Parameter(Mandatory=$false,
    HelpMessage='Start date of Files to scan')]
    $StartDate = 'defaultvalue1',
    
    [Parameter(Mandatory=$false,
    HelpMessage='End date of Files to scan')]
    $EndDate = 'defaultvalue1',

    [Parameter(Mandatory=$false,
    HelpMessage='End date of Files to scan')]
    $CopyMatchingSyslogsToDirectory = 'D:\PossibleLoops',

    [Parameter(Mandatory=$false,
    HelpMessage='Number of lines between which the total number of duplicate matches will be counted')]
    $MatchesWithinXLines = '6000',

    [Parameter(Mandatory=$false,
    HelpMessage='Error Log location, default C:\<Command Name>_ErrorLog.txt')]
    [string]$ErrorLog = "c:\$($myinvocation.mycommand)_ErrorLog.txt",
    [switch]$LogErrors
    
  ) #Close Parameters
  
  
  #############################################################
  # Begin Block
  #############################################################
  
  Begin 	{
    Write-Verbose "Starting $($myinvocation.mycommand)"
    Write-Verbose "Error log will be $ErrorLog"
    
    # Script Level Variable to Stop Execution if there is an issue with any stage of the script
    $script:EverythingOK = $true
    
    $files1 = Get-ChildItem -Recurse "$SyslogDirectory" | where-object {$_.lastwritetime -ge $StartDate -and  $_.lastwritetime -lt $Enddate -and ! $_.PSIsContainer}

    $files1count = $($files1.count)

    #Output Object, all output at end of run, not piped per result
    $NumbersAndCounts = @()

    Write-Host "Checking Files from $StartDate to $EndDate, $files1count Files"

 
  } #Close Function Begin Block
  
  #############################################################
  # Process Block
  #############################################################
  
  Process {
    
    # First Code To Run
    If ($script:EverythingOK)
    {
      Try 	
      {
        
        # Code Goes here
    

        $loopcount0 = $null
Foreach ($file in $files1) #Foreach File Checked
{
  $loopcount0 = $loopcount0 + 1
  Write-Host "Log file $loopcount0 of $files1count $($file.fullname)"
  Write-Verbose "File Name $($file.fullname)"
  Write-Verbose "file Last Write time $($file.lastwritetime)"
  
  # Reset all results collections
  $AllNumbers=  @()
  $UniqueNumbers = @()
  $LogOfProcessedNumbers = @()
  
  Write-Verbose "Loading file into Memory $($file.fullname)"
  $content = $null
  
  If (Test-Path "$($file.fullname)")
  {
    # Get-Content, I can't use -readcount to speed it up because I want to process it line by line
    $content = Get-Content "$($file.fullname)"
  }
  elseif ((Test-Path "$($file.fullname)") -eq $false)
  {
    Write-Verbose "File $($file.fullname) not found, Logs may be looping (so file temporarily does not exist), waiting 10 seconds"
    # We potentially miss a file in this scenario
    Start-Sleep -Seconds 10
    $content = Get-Content "$($file.fullname)"
  }
  
  
  # Get all the SIP Suffix (sip: something @) strings
  # $InviteSelectString = $content | Select-String -Pattern 'sip:\+?([^\n\r@]*)@'
  
  $InviteSelectString = $content | Select-String -Pattern 'INVITE sip:\+?([^\n\r@]*)@'
  
  $InviteSelectStringcount = $($InviteSelectString.count)
  
  If ($InviteSelectStringcount -gt 0)
  {
    
    Write-Verbose "Total Match Count is $InviteSelectStringcount"
    
    Write-Verbose 'Filtering For Unique Values'
    
    $InviteSelectStringunique = $InviteSelectString | Select-Object Matches -Unique
    
    Write-Verbose "Unique Match Count is $($InviteSelectStringunique.count)"
    
    ################################################
    
    $Loopcount1 = $null
    Foreach ($match in $InviteSelectStringunique)
    {
      $LoopCount1 = $LoopCount1 +1
      $SIPString = $null
      $SIPString = $match.matches[0].value
      
      Write-Verbose "Procesing Match $LoopCount1 of $($InviteSelectStringunique.count)"
      Write-Verbose "Processing String $($SIPString)"
      
      # Instances gives me the specific instances of that SIPURI coming up in the file
      $Instances = $InviteSelectString | Where-Object {$_.matches[0].value -eq $match.matches[0].value}
      
      
      If ( ($instances.count) -eq $null -and $Instances -ne $null )
      {
        $InstanceCount = 1
      }
      
      If ($($instances.count) -ne $null) 
      {
        $InstanceCount = $($Instances.Count)
      }
      
      # To get the unique lines (so unique calls)
      $UniqueMatchingLine = $null
      $UniqueMatchingLines = $Instances | Select-Object Line -unique           
      
      Write-Verbose "Instances matching that SIP String in file is $InstanceCount"
      
      If ($InstanceCount -gt 5)
      {
        
        # If there are more than 5 matches, check how close they are in lines in the file, closer than 6000
        # between the first and 6th instance usually means a loop
        If ( ( $($instances[5].LineNumber) - $($Instances[0].LineNumber) ) -lt $MatchesWithinXLines)   
        {
          Write-Host "6 matches for $($SIPString) within $MatchesWithinXLines log lines"
          
          # Copy the log file for later review, with SIPString in file name for easy checking
          $InviteWithoutColon = $SIPString.Replace(':','')
          Copy-Item $($file.fullname) -Destination ("$CopyMatchingSyslogsToDirectory" + "\" + "$InviteWithoutColon" + "$($file.Name)")

          #build output object
          $output = New-Object -TypeName PSobject 
          $output | add-member NoteProperty 'UniqueInviteCount' -value $($InstanceCount)
          $output | add-member NoteProperty 'SIPString' -value $($SIPString)
          $output | add-member NoteProperty 'LogFile' -value ("$CopyMatchingSyslogsToDirectory" + "\" + "$InviteWithoutColon" + "$($file.Name)")
          $output | add-member NoteProperty 'LastWritetime' -value $($file.lastwritetime)
          $NumbersAndCounts += $output
        
          
        }
       If ( ( $($instances[5].LineNumber) - $($Instances[0].LineNumber) ) -gt 6000)   
        {
          Write-Verbose "$($SIPString) was matched on 6 invites but they are spread accross more than $MatchesWithinXLines lines so are likely not a loop"
        }
        
        
      }
    }
    
    # write output to pipeline, one object at a time
    # $NumbersAndCounts
    
  }
  else 
  {
    Write-Verbose 'Match Count is not greater than 0. No invites found in file'
  }
} # Close Foreach File

$NumbersAndCounts



        ### Code Ends here


        
      } # Close Try Block
      
      Catch 	{ErrorCatch-Action} # Close Catch Block
      
      
    } # Close If EverthingOK Block 1
    
    #############################################################
    # Next Script Action or Try,Catch Block
    #############################################################
    
    # Second Code To Run
    If ($script:EverythingOK)
    {
      Try 	
      {
        
        # Code Goes here
        
        
      } # Close Try Block
      
      Catch 	{ErrorCatch-Action} # Close Catch Block
      
      
    } # Close If EverthingOK Block 2
    
    
  } #Close Function Process Block 
  
  #############################################################
  # End Block
  #############################################################
  
  End 	{
    Write-Verbose "Ending $($myinvocation.mycommand)"
  } #Close Function End Block
  
} #End Function



# Helper Functions below this line ##########################################


    #############################################################
    # Function to Deal with Error Output to Log file
    #############################################################
    

 Function ErrorCatch-Action 
    {
      Param 	(
        [Parameter(Mandatory=$false,
        HelpMessage='Switch to Allow Errors to be Caught without setting EverythingOK to False, stopping other aspects of the script running')]
        # By default any errors caught will set $EverythingOK to false causing other parts of the script to be skipped
        [switch]$SetEverythingOKVariabletoTrue
    
      ) # Close Parameters
      
      $ErrorLog = "D:\PossibleLoops\Get-SysLogCallLoop_Errors.txt"

      # Set EverythingOK to false to avoid running dependant actions
      If ($SetEverythingOKVariabletoTrue) {$script:EverythingOK = $true}
      else {$script:EverythingOK = $false}
      Write-Verbose "EverythingOK set to $script:EverythingOK"
      
      # Write Errors to Screen
      Write-Error $Error[0]
      # If Error Logging is runnning write to Error Log
      
      
        # Add Date to Error Log File
        Get-Date -format 'dd/MM/yyyy HH:mm' | Out-File $ErrorLog -Append
        $Error | Out-File $ErrorLog -Append
        '## LINE BREAK BETWEEN ERRORS ##' | Out-File $ErrorLog -Append
        Write-Warning "Errors Logged to $ErrorLog"
        # Clear Error Log Variable
        $Error.Clear()
      
    } # Close Error-CatchActons Function