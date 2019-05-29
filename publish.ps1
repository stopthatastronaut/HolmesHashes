param (
    [string]$NuGetPath = "C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet",
    [string]$NuGetApiKey
)

if (!(Test-Path -Path "$NuGetPath\nuget.exe")) {
    if (!(Test-Path -Path $NuGetPath)) {
        New-Item -ItemType "Directory" -Path $NuGetPath -force -verbose | Out-Null
    }

    Write-Output "Downloading the NuGet Executable..."
    (New-Object System.Net.WebClient).DownloadFile("https://nuget.org/nuget.exe", "$NuGetPath\nuget.exe")
}

# find the current published version
try {
    $pver = [version](Find-Module HolmesHashes | Select-Object -expand version)
}
catch {
    $pver = [version]"0.0.0.0"
}

# find the current manifest version
$mver = (Import-PowerShellDataFile .\HolmesHashes\HolmesHashes.psd1).ModuleVersion

if($mver -gt $pver)
{

    Write-Output "Version has incremented. Publishing to PSGallery"

    Write-Output "Installing the NuGet Package Provider..."
    Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Force -Verbose

    Write-Output "Trusting the PSGallery Repository..."
    Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted" -Verbose

    # TODO: gather release notes, publish with notes

    Write-Output "Publishing the HolmesHashes Module..."
    Publish-Module -Path "./HolmesHashes" -NuGetApiKey $NuGetApiKey -Verbose -force

    git config --global user.email "stopthatastronaut@gmail.com"
    git config --global user.name "Octopus - deploy.d.evops.co"

    git tag -a "$mver" -m "Version $mver release"
    git push --tags

}
else {
    Write-Output "Version not incremented, declining to publish"
}

exit 0   # so Octopus exits correctly
