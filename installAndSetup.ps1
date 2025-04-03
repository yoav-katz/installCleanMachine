$CHROME_INSTALL_URL = "ENTER_URL"
$MOBA_INSTALL_URL = "ENTER_URL"
$VPN_INSTALL_URL = "ENTER_URL"
$KEYS_REMOTE_DIR = "ENTER_DIR"
$ISOLATED_IP = "ENTER_IP"
# Get the user's Downloads folder
$downloadsFolder = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
$keysLocalFolder = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop", "keys")

# Function to log messages to the console
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp - $message"
}

# Start logging
Write-Log "=== Script started ==="

# Function to download applications
function Download-App {
    param (
        [string]$url,
        [string]$installerPath
    )
    try {
        Write-Log "Downloading: $url -> $installerPath"
        Invoke-WebRequest -Uri $url -OutFile $installerPath
        Write-Log "Download completed: $installerPath"
    }
    catch {
        Write-Log "Error downloading from $url : $_"
        exit 1
    }
}

# Function to install applications (without silent mode)
function Install-App {
    param (
        [string]$installerPath
    )
    try {
        Write-Log "Running installer: $installerPath"
        Start-Process -FilePath $installerPath -Wait
        Write-Log "Installation completed for: $installerPath"
    }
    catch {
        Write-Log "Error installing $installerPath : $_"
        exit 1
    }
}

# Download Chrome
$chromeInstaller = "$downloadsFolder\chrome_installer.exe"
Download-App -url $CHROME_INSTALL_URL -installerPath $chromeInstaller
Install-App -installerPath $chromeInstaller

# Download MobaXterm
$mobaInstaller = "$downloadsFolder\moba_installer.exe"
Download-App -url $MOBA_INSTALL_URL -installerPath $mobaInstaller
Install-App -installerPath $mobaInstaller

# Download VPN
$vpnInstaller = "$downloadsFolder\vpn_installer.exe"
Download-App -url $VPN_INSTALL_URL -installerPath $vpnInstaller
Install-App -installerPath $vpnInstaller

# Copy files from shared directory
Write-Log "Copying files from $KEYS_REMOTE_DIR to $keysLocalFolder"
try {
    if (-Not (Test-Path $keysLocalFolder)) {
        New-Item -ItemType Directory -Path $keysLocalFolder | Out-Null
    } else {
        Write-Log "Clearing existing files in $keysLocalFolder"
        Remove-Item -Path "$keysLocalFolder\*" -Recurse -Force
    }
    Copy-Item -Path "$KEYS_REMOTE_DIR\*" -Destination $keysLocalFolder -Recurse -Force
    Write-Log "Files copied successfully."
}
catch {
    Write-Log "Error copying files: $_"
    exit 1
}

# Start MobaXterm session
Write-Log "Starting MobaXterm session: $SESSION_NAME"
try {
    $mobaPath = "C:\Program Files (x86)\Mobatek\MobaXterm\MobaXterm.exe"
    if (-Not (Test-Path $mobaPath)) {
        Write-Log "MobaXterm not found!"
        exit 1
    }

    # Open the MobaXterm session
    Start-Process -FilePath $mobaPath -ArgumentList "-newtab", "`"[ssh $ISOLATED_IP]`""
    Write-Log "MobaXterm session started."
}
catch {
    Write-Log "Error starting MobaXterm session: $_"
    exit 1
}

# Check if SSH session was successful
Write-Log "Checking SSH connection..."
Start-Sleep -Seconds 5  # Wait to ensure session starts
$sshSuccess = $false

# Assuming success if MobaXterm is running (you may improve this)
$processes = Get-Process | Where-Object { $_.ProcessName -like "*MobaXterm*" }
if ($processes) {
    Write-Log "SSH session is active."
    $sshSuccess = $true
}
else {
    Write-Log "SSH session failed."
}

# Cleanup and Logout
if ($sshSuccess) {
    Write-Log "Deleting copied directory: $keysLocalFolder"
    # Remove-Item -Path $keysLocalFolder -Recurse -Force
    # Write-Log "Copied directory deleted."

    # Write-Log "Logging out..."
    # Stop-Process -Name "MobaXterm" -Force
}
else {
    Write-Log "SSH session unsuccessful. Keeping copied directory for debugging."
}

Write-Log "=== Script finished ==="
