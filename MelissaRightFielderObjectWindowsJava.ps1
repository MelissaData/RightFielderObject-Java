# Name:    MelissaRightFielderObjectWindowsJava
# Purpose: Use the Melissa Updater to make the MelissaRightFielderObjectWindowsJava code usable

######################### Parameters ##########################

param($rfinput = '', $dataPath = '', $license = '', [switch]$quiet = $false )

######################### Classes ##########################

class FileConfig {
  [string] $FileName;
  [string] $ReleaseVersion;
  [string] $OS;
  [string] $Compiler;
  [string] $Architecture;
  [string] $Type;
}

######################### Config ###########################

$RELEASE_VERSION = '2024.Q4'
$ProductName = "RF_DATA"

# Uses the location of the .ps1 file 
$CurrentPath = $PSScriptRoot
Set-Location $CurrentPath
$ProjectPath = "$CurrentPath\MelissaRightFielderObjectWindowsJava"

if ([string]::IsNullOrEmpty($dataPath)) {
  $DataPath = "$ProjectPath\Data" 
}

if (!(Test-Path $DataPath) -and ($DataPath -eq "$ProjectPath\Data")) {
  New-Item -Path $ProjectPath -Name 'Data' -ItemType "directory"
}
elseif (!(Test-Path $DataPath) -and ($DataPath -ne "$ProjectPath\Data")) {
  Write-Host "`nData file path does not exist. Please check that your file path is correct."
  Write-Host "`nAborting program, see above.  Press any button to exit.`n"
  $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") > $null
  exit
}

$DLLs = @(
  [FileConfig]@{
    FileName       = "mdRightFielder.dll";
    ReleaseVersion = $RELEASE_VERSION;
    OS             = "WINDOWS";
    Compiler       = "DLL";
    Architecture   = "64BIT";
    Type           = "BINARY";
  }
)

$WrapperCom = @(
  [FileConfig]@{
    FileName       = "mdRightFielderJavaWrapper.dll";
    ReleaseVersion = $RELEASE_VERSION;
    OS             = "WINDOWS";
    Compiler       = "JAVA";
    Architecture   = "64BIT";
    Type           = "INTERFACE";
  },
  [FileConfig]@{
    FileName       = "mdRightFielder_JavaCode.zip";
    ReleaseVersion = $RELEASE_VERSION;
    OS             = "ANY";
    Compiler       = "JAVA";
    Architecture   = "ANY";
    Type           = "INTERFACE";
  }
)

######################## Functions #########################

function DownloadDataFiles([string] $license) {
  $DataProg = 0
  Write-Host "============================== MELISSA UPDATER ============================="
  Write-Host "MELISSA UPDATER IS DOWNLOADING DATA FILE(S)..."
  
  .\MelissaUpdater\MelissaUpdater.exe manifest -p $ProductName -r $RELEASE_VERSION -l $license -t $DataPath 
  if ($? -eq $False ) {
    Write-Host "`nCannot run Melissa Updater. Please check your license string!"
    Exit
  }     
  Write-Host "Melissa Updater finished downloading data file(s)!"
  
}
  
function DownloadDLLs() {
  Write-Host "MELISSA UPDATER IS DOWNLOADING DLL(S)..."
  $DLLProg = 0
  foreach ($DLL in $DLLs) {
    Write-Progress -Activity "Downloading DLL(S)" -Status "$([math]::round($DLLProg / $DLLs.Count * 100, 2))% Complete:"  -PercentComplete ($DLLProg / $DLLs.Count * 100)
  
    # Check for quiet mode
    if ($quiet) {
      .\MelissaUpdater\MelissaUpdater.exe file --filename $DLL.FileName --release_version $DLL.ReleaseVersion --license $LICENSE --os $DLL.OS --compiler $DLL.Compiler --architecture $DLL.Architecture --type $DLL.Type --target_directory $ProjectPath > $null
      if (($?) -eq $False) {
        Write-Host "`nCannot run Melissa Updater. Please check your license string!"
        Exit
      }
    }
    else {
      .\MelissaUpdater\MelissaUpdater.exe file --filename $DLL.FileName --release_version $DLL.ReleaseVersion --license $LICENSE --os $DLL.OS --compiler $DLL.Compiler --architecture $DLL.Architecture --type $DLL.Type --target_directory $ProjectPath 
      if (($?) -eq $False) {
        Write-Host "`nCannot run Melissa Updater. Please check your license string!"
        Exit
      }
    }
      
    Write-Host "Melissa Updater finished downloading " $DLL.FileName "!"
    $DLLProg++
  }
}

function DownloadWrappers() {
  foreach ($File in $WrapperCom) {
    # Check for quiet mode
    if ($quiet) {
      .\MelissaUpdater\MelissaUpdater.exe file --filename $File.FileName --release_version $File.ReleaseVersion --license $LICENSE --os $File.OS --compiler $File.Compiler --architecture $File.Architecture --type $File.Type --target_directory $ProjectPath > $null
      if (($?) -eq $False) {
        Write-Host "`nCannot run Melissa Updater. Please check your license string!"
        Exit
      }
    }
    else {
      .\MelissaUpdater\MelissaUpdater.exe file --filename $File.FileName --release_version $File.ReleaseVersion --license $LICENSE --os $File.OS --compiler $File.Compiler --architecture $File.Architecture --type $File.Type --target_directory $ProjectPath 
      if (($?) -eq $False) {
        Write-Host "`nCannot run Melissa Updater. Please check your license string!"
        Exit
      }
    }
      
    Write-Host "Melissa Updater finished downloading " $File.FileName "!"

    # Check for the zip folder and extract from the zip folder if it was downloaded
    if ($File.FileName -eq "mdRightFielder_JavaCode.zip") {
      if (!(Test-Path ("$ProjectPath\mdRightFielder_JavaCode.zip"))) {
        Write-Host "mdRightFielder_JavaCode.zip not found." 
        
        Write-Host "`nAborting program, see above.  Press any button to exit."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
      }
      else {
        if (!(Test-Path ("$ProjectPath/com"))) {
        Expand-Archive -Path "$ProjectPath\mdRightFielder_JavaCode.zip" -DestinationPath $ProjectPath
        }
        else {
          # Remove the com folder before extracting
          Remove-Item -Path "$ProjectPath/com" -Recurse -Force

          Expand-Archive -Path "$ProjectPath\mdRightFielder_JavaCode.zip" -DestinationPath $ProjectPath
        }
      }
    }
  }
}
  
function CheckDLLs() {
  Write-Host "`nDouble checking dll(s) were downloaded...`n"
  $FileMissing = $false 
  if (!(Test-Path ("$ProjectPath\mdRightFielder.dll"))) {
    Write-Host "mdRightFielder.dll not found." 
    $FileMissing = $true
  }
  if ($FileMissing) {
    Write-Host "`nMissing the above data file(s).  Please check that your license string and directory are correct."
    return $false
  }
  else {
    return $true
  }
}
  
########################## Main ############################
  
Write-Host "`n======================= Melissa Right Fielder Object =======================`n                         [ Java | Windows | 64BIT ]`n"
  
# Get license (either from parameters or user input)
if ([string]::IsNullOrEmpty($license) ) {
  $License = Read-Host "Please enter your license string"
}
  
# Check for License from Environment Variables 
if ([string]::IsNullOrEmpty($License) ) {
  $License = $env:MD_LICENSE 
}
  
if ([string]::IsNullOrEmpty($License)) {
  Write-Host "`nLicense String is invalid!"
  Exit
}

# Get data file path (either from parameters or user input)
if ($DataPath -eq "$ProjectPath\Data") {
  $dataPathInput = Read-Host "Please enter your data files path directory if you have already downloaded the release zip.`nOtherwise, the data files will be downloaded using the Melissa Updater (Enter to skip)"

  if (![string]::IsNullOrEmpty($dataPathInput)) {
    if (!(Test-Path $dataPathInput)) {
      Write-Host "`nData file path does not exist. Please check that your file path is correct."
      Write-Host "`nAborting program, see above.  Press any button to exit.`n"
      $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") > $null
      exit
    }
    else {
      $DataPath = $dataPathInput
    }
  }
}

# Use Melissa Updater to download data file(s) 
# Download data file(s) 
DownloadDataFiles -license $License # Comment out this line if using own release
  
# Download dll(s)
DownloadDlls -license $License

# Download wrapper and com folder
DownloadWrappers -license $License
  
# Check if all dll(s) have been downloaded. Exit script if missing
$DLLsAreDownloaded = CheckDLLs
  
if (!$DLLsAreDownloaded) {
  Write-Host "`nAborting program, see above.  Press any button to exit."
  $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
  exit
}
  
Write-Host "All file(s) have been downloaded/updated! "
  
# Start
# Build project
Set-Location $ProjectPath
Write-Host "`n=============================== BUILD PROJECT =============================="
javac MelissaRightFielderObjectWindowsJava.java
jar cvfm MelissaRightFielderObjectWindowsJava.jar manifest.txt *.class *.dll com\melissadata\*.class

# Run project
if ([string]::IsNullOrEmpty($rfinput)) {
  java -jar MelissaRightFielderObjectWindowsJava.jar --license $License --dataPath $DataPath
}
else {
  java -jar MelissaRightFielderObjectWindowsJava.jar --license $License --dataPath $DataPath --rfinput $rfinput
}
Set-Location ..
