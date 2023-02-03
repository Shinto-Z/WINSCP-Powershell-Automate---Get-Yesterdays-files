##Created By Shane Wallace based on examples located at https://winscp.net/eng/docs/library_examples##
##
##

## TO/FROM directories as arrays
$directories = @(@("remote/folder/location1","C:\local\folder\location1"),@("remote/folder/location2","C:\local\folder\location2"))

#Get MM/DD/YYYY date
$dateYesterday=(Get-Date).AddDays(-1).ToString("MM/dd/yyyy")

#Add in WinSCP dll
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

 try{

  # Setup session options; You may want to pipe in authentication for security reasons
  $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
   Protocol = [WinSCP.Protocol]::Sftp
   HostName = "sftp.example.com"
   UserName = "User"
   Password = "Password"
   SshHostKeyFingerprint = "ssh-rsa 2048 0a:1b:2c:3d:4e:5f:6a:7b:8c:9d:ae:bf:ca:db:ec:fd"
  }

  $session = New-Object WinSCP.Session
 
  try{
   # Connect
   $session.Open($sessionOptions)

   foreach($directory in $directories){
 
    $fileList=@()

    $remoteDirectory = $session.ListDirectory($($directory[0]))

    Write-Host "Entering directory" + $($directory[0])

    #Get each file date and compare; If from yesterday, add to array
    foreach ($fileInfo in $remoteDirectory.Files){
     $tempFileInfo=$($fileInfo.LastWriteTime).ToString("MM/dd/yyyy")
     if($tempFileInfo -eq $dateYesterday){
      $fileList+=$($fileInfo.Name)
     }
    }

    # Set Download options
    $transferOptions = New-Object WinSCP.TransferOptions
    $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

    #iterate through array
    foreach($downloadFile in $fileList){

     $fileToDL=$($directory[0])+"/"+$downloadFile

     Write-Host "downloading $fileToDL from $($directory[1])"

     #download file
     $transferResult = $session.GetFiles($fileToDL, $($directory[1]),$False, $transferOptions)
 
     # Throw on any error
     $transferResult.Check()
 
     # Print results
     foreach ($transfer in $transferResult.Transfers){
      Write-Host "Download of $($transfer.FileName) succeeded"
     }

    }
   }
  }
  finally{
   # Disconnect, clean up
   $session.Dispose()
  }
 
  exit 0
 }
 catch{
  Write-Host "Error: $($_.Exception.Message)"
  exit 1
 }