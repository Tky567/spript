$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host "[!] Dang yeu cau quyen Administrator (UAC)..." -ForegroundColor Yellow

    $ScriptUrl = "https://raw.githubusercontent.com/Tky567/script/refs/heads/tikicodon/notlua/fixriskdownload.ps1"

    if ([string]::IsNullOrWhiteSpace($ScriptUrl)) {
        if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
            try {
                Start-Process -FilePath "powershell.exe" `
                    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
                    -Verb RunAs `
                    -Wait
                exit $LASTEXITCODE
            }
            catch {
                Write-Error "Khong the yeu cau quyen Administrator: $($_.Exception.Message)"
                exit 1
            }
        }

        Write-Error "Khong xac dinh duoc URL cua script khi chay qua irm | iex. Hay dat `$env:SCRIPT_URL truoc khi chay."
        exit 1
    }

    try {
        $command = "irm '$ScriptUrl' | iex"

        Start-Process -FilePath "powershell.exe" `
            -ArgumentList @(
                "-NoProfile"
                "-ExecutionPolicy", "Bypass"
                "-Command", $command
            ) `
            -Verb RunAs `
            -Wait

        exit $LASTEXITCODE
    }
    catch {
        Write-Error "Khong the yeu cau quyen Administrator: $($_.Exception.Message)"
        exit 1
    }
}

Write-Host "[+] Da co quyen Administrator." -ForegroundColor Green

$DevExtensions = @(
    'js', 'mjs', 'cjs', 'ts', 'jsx', 'tsx', 'vbs', 'vbe', 'jse', 'ps1', 'psm1', 'psd1',
    'bat', 'cmd', 'sh', 'bash', 'zsh', 'py', 'pyw', 'rb', 'pl', 'php', 'lua', 'reg', 'scr',
    'hta', 'wsf', 'wsc', 'exe', 'msi', 'app', 'dmg', 'pkg', 'deb', 'rpm', 'apk', 'crx',
    'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'iso', 'img', 'dll', 'sys', 'jar', 'war', 'ear'
)

$TargetRegistryPaths = @(
    "HKCU:\Software\Policies\Google\Chrome",
    "HKCU:\Software\Policies\Microsoft\Edge",
    "HKCU:\Software\Policies\BraveSoftware\Brave",
    "HKLM:\SOFTWARE\Policies\Google\Chrome",
    "HKLM:\SOFTWARE\Policies\Microsoft\Edge",
    "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"
)

foreach ($path in $TargetRegistryPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name 'DownloadRestrictions' -Value 0 -Type DWord -ErrorAction SilentlyContinue
}
Write-Host "[+] Da gop bo DownloadRestrictions cho Chrome, Edge, Brave." -ForegroundColor Green

$ExemptPaths = @(
    "HKCU:\Software\Policies\Google\Chrome\ExemptDomainFileTypePairsFromFileTypeDownloadWarnings",
    "HKCU:\Software\Policies\Microsoft\Edge\ExemptDomainFileTypePairsFromFileTypeDownloadWarnings",
    "HKLM:\SOFTWARE\Policies\Google\Chrome\ExemptDomainFileTypePairsFromFileTypeDownloadWarnings",
    "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExemptDomainFileTypePairsFromFileTypeDownloadWarnings"
)

foreach ($exemptPath in $ExemptPaths) {
    if (-not (Test-Path $exemptPath)) {
        New-Item -Path $exemptPath -Force | Out-Null
    }
    $index = 1
    foreach ($ext in $DevExtensions) {
        $jsonVal = "{`"file_extension`": `"$ext`", `"domains`": [`"*`"]}"
        Set-ItemProperty -Path $exemptPath -Name "$index" -Value $jsonVal -Type String -ErrorAction SilentlyContinue
        $index++
    }
}
Write-Host "[+] Da nhap $($DevExtensions.Count) dinh dang file Dev vao danh sach ngoai le dinh dang nguy hiem." -ForegroundColor Green

$AttachPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments"
)

foreach ($attPath in $AttachPaths) {
    if (-not (Test-Path $attPath)) {
        New-Item -Path $attPath -Force | Out-Null
    }
    Set-ItemProperty -Path $attPath -Name 'SaveZoneInformation' -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $attPath -Name 'HideZoneCheck' -Value 1 -Type DWord -ErrorAction SilentlyContinue
}
Write-Host "[+] Da tat tinh nang Windows MOTW (Zone.Identifier) - File tai ve se khong bi dong dau chan." -ForegroundColor Green

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction SilentlyContinue
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force -ErrorAction SilentlyContinue
Write-Host "[+] Da mo khoa quyen chay Script PowerShell (ExecutionPolicy = Bypass)." -ForegroundColor Green

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   HOAN TAT FIX! DE TRINH DUYET CAP NHAT POLICY MOI, HAY TAT MOT   " -ForegroundColor Yellow
Write-Host "   HOAN TOAN CAC TRINH DUYET (CHROME / EDGE / BRAVE) ROI MO LAI.  " -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Cyan
