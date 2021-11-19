param(
    [string]$MsixSourceFolder = "",
    [string]$BundleFilePath = "",
    [string]$BundleVersion = "",
    [string]$Architecture = "",
    [string]$SdkVersion = "",
    [string]$IsSigningEnabled = "",
    [string]$PfxPrivateKey = "",
    [string]$PfxFilePath = "",
    [string]$HashAlgo = ""
)

## ************************************ ##
## ********* VALIDATE INPUTS ********** ##
## ************************************ ##
$isSourcePathValid = Test-Path -Path $MsixSourceFolder

if ($isSourcePathValid -eq $false) {
    Write-Ouput "You must have a valid path value for the folder containing the MSIX files."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($BundleFilePath)) {
    Write-Error "Missing file path for the msixbundle."
    Write-Output 'You must enter a value to be used for the msixbundle file. For example C:\MyApp\MyApp_1.0.0.0_x86_x64.msixbundle.'
    exit 1
}

$isBundlePathValid = Test-Path -Path $BundleFilePath -IsValid

if ($isBundlePathValid -eq $false) {
    Write-Error "Invalid file path used for the msixbundle file."
    Write-Ouput 'You must use a valid file path for the msixbundle to be saved to. For example C:\MyApp\MyApp_1.0.0.0_x86_x64.msixbundle.'
    exit 1
}

## ********************************** ##
## ******** STEP 1. BUNDLE ********** ##
## ********************************** ##

Write-Output "Setting correct SDK tools folder (added to PATH)"
$sdkToolsPath = Join-Path -Path 'C:\Program Files (x86)\Windows Kits\10\bin' -ChildPath $SdkVersion -AdditionalChildPath $Architecture
$env:Path += ";$sdkToolsPath"

Write-Output "Input folder (contains only MSIX files) -> $MsixSourceFolder"
Write-Output "Desired File path for msixbundle -> $BundleFilePath"
Write-Output "Desired Version for msixbundle -> $BundleVersion"

Write-Output "Creating bundle with MakeAppx..."
MakeAppx.exe bundle /bv $BundleVersion /d $MsixSourceFolder /p $BundleFilePath

# MakeAppx.exe Docs and Reference 
# https://docs.microsoft.com/en-us/windows/msix/package/create-app-package-with-makeappx-tool
# https://docs.microsoft.com/en-us/windows/msix/packaging-tool/bundle-msix-packages#step-2-bundle-the-packages

## ************************************ ##
## ********** STEP 2. SIGN ************ ##
## ************************************ ##

if ($IsSigningEnabled) {
    Write-Output "Beginning code signing of msixbundle file."

    # With signing enabled, time to validate the required inputs
    $isCertPathValid = Test-Path -Path $PfxFilePath

    if ($isCertPathValid -eq $false) {
        Write-Ouput "You must have a valid path value for the signing certificate."
        exit 1
    }
    
    if ([string]::IsNullOrWhiteSpace($PfxPrivateKey)) {
        Write-Output "You must have a password for the PFX certificate."
        exit 1
    }

    # sign
    try {
        Write-Output "Parameters validated, beginning signing..."

        SignTool.exe sign /fd $HashAlgo /a /f $PfxFilePath /p $PfxPrivateKey $BundleFilePath

        # Reference Docs
        # https://docs.microsoft.com/en-us/windows/msix/packaging-tool/bundle-msix-packages#step-3-sign-the-bundle
    }
    catch { 
        Write-Output "An error occurred:"
        Write-Output $_.ScriptStackTrace
        exit 1
    }

    Write-Output "Signing complete!"

}
else {
    Write-Output "Bundle signing is not enabled, skipping signing."
}

if ([string]::IsNullOrWhiteSpace($BundleFilePath)) {
    Write-Output "The output file path is empty, something went wrong. Please check the build log output for details."
    exit 1
}
