[CmdletBinding()]
Param(
[Parameter()]
[string]$settingsXML
)
Clear-Host;

if($($settingsXML) -ne ""){
 if(Get-Content $settingsXML){

$dateYesterday=(Get-Date).AddDays(-1).ToString("MM/dd/yyyy")

Write-Host "date to process is $dateYesterday";

Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

try{

 [xml]$settingsXML = Get-Content $($settingsXML)

 # START Sites
 $settingsXML.sites.site|ForEach-Object{

  # Set up creds; Base64 encoded passwords aren't the best. Some popular FTP/SFTP programs store creds this way. 
  # May come up with a better way to store creds in production. Out of scope of this exercise
  $server=$_.cred.host
  $user=$_.cred.user
  $pass=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_.cred.pass))
  $key=$_.cred.key

  # Setup session options
  $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
   Protocol = [WinSCP.Protocol]::Sftp
   HostName = $server
   UserName = $user
   Password = $pass
   SshHostKeyFingerprint = $key
  }

  $session = New-Object WinSCP.Session
  try{
   # Connect
   $session.Open($sessionOptions)

   # Download files
   $transferOptions = New-Object WinSCP.TransferOptions
   $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

   Write-Host "START directories"
   # $($_.source) $($_.destination)
   $_.directories.directory|ForEach-Object{

    Write-Host "Entering directory $($_.source)"
    $remoteDirectory = $session.ListDirectory($($_.source))
    foreach ($fileInfo in $remoteDirectory.Files){
     $tempFileInfo=$($fileInfo.LastWriteTime).ToString("MM/dd/yyyy")
     if($tempFileInfo -eq $dateYesterday){
      Write-Host "Matched file $($fileInfo.name) - $($tempFileInfo)"
      Write-Host "Downloading $($fileInfo.Name) to $($_.destination)"

      $transferResult = $session.GetFiles("$($_.source)/$($fileInfo.Name)", "$($_.destination)\$($fileInfo.Name)",$False, $transferOptions)
      # Throw on any error
      $transferResult.Check()

      # Print results
      foreach ($transfer in $transferResult.Transfers){
       Write-Host "Download of $($transfer.FileName) succeeded"
      }
     }
    }
   }
   Write-Host "END directories"

  }
  finally{
   # Disconnect, clean up
   $session.Dispose()
  }
 
 }
 # END Sites

 exit 0

}
catch{
 Write-Host "Error: $($_.Exception.Message)"
 exit 1
}


 }
 else{
  Write-Host "Cannot Read settings XML File."
 }

}
else{
 Write-Host "The settings XML File must be passed as a parameter to the script."
}
