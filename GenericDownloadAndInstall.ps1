#requires -version 2
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
  <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None>
.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development
.EXAMPLE
  <Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------


[CmdletBinding()]  
param (
    [Parameter(Mandatory = $True)]
    [string]$AppName,
        
    [Parameter(Mandatory = $False)]
    [string]$Uri,
        
    [Parameter(Mandatory = $False)]
    [array]$Args
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Import Modules & Snap-ins

<#
$NewAppName = "Google Drive File Stream"
$NewAppURI = "https://dl.google.com/drive-file-stream/GoogleDriveFSSetup.exe"
$NewAppInstaller = "$env:systemdrive\GXA\Software\Google\DriveFileStream\GoogleDriveFSSetup.exe"
$NewAppArguments = " --silent"
$OldAppName = "Google Drive"
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function DownloadFile($url, $targetFile) {

    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength() / 1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer, 0, $buffer.length)
    $downloadedBytes = $count

    while ($count -gt 0) {
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer, 0, $buffer.length)
        $downloadedBytes = $downloadedBytes + $count
        Write-Progress -activity "Downloading file '$($url.split('/') | Select-Object -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes / 1024)) / $totalLength) * 100)
    }

    Write-Progress -activity "Finished downloading file '$($url.split('/') | Select-Object -Last 1)'"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------



$NewApp = Get-WmiObject -Class win32_product -Filter "Name='$NewAppName'"

$NewApp

If (!$NewApp) {
    Write-Host "$NewAppName not installed"
    
    Write-Host "Creating folder paths"
    Test-Paths -pathArray $Paths

    Write-Host "Downloading $NewAppName from $NewAppURI to $NewAppInstaller"
    DownloadFile $NewAppURI $NewAppInstaller

    Write-Host "Running $NewAppInstaller with Arguments: $NewAppArguments"
    $Install = Start-Process -FilePath $NewAppInstaller -ArgumentList $NewAppArguments -Wait
    
    If ($Install.ExitCode -eq 0) {
        Write-Host "Successfully installed $NewAppName"
    }
    Else {
        Write-Host "Installation of $NewAppName failed with Exit Code: $($Install.ExitCode)"
        Write-Host "Killing Script"
        Exit
    }

}
Else {
    Write-Host "$NewAppName already installed"
    Write-Host "Checking for $OldAppName"

    $OldApp = Get-WmiObject -Class win32_product -Filter "Name='$OldAppName'"
    
    If ($OldApp) {
        Write-Host "$($OldApp.Name) does exist"
        Write-Host "Calling Uninstall"

        $Uninstall = $OldApp.Uninstall()

        If (($Uninstall).ReturnValue -ne 0) {
            Write-Host "Uninstall failed with Exit Code: $($Uninstall.ReturnValue)"
        }
        Else {
            Write-Host "Successfully Uninstalled $OldAppName"
        }
    }
    
}