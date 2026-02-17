<# 
.SYNOPSIS
  SQL Server CU checker/installer (silent) with optional midnight scheduling + single-file i18n + interactive menu.

.DESCRIPTION
  - Detects installed SQL Server instances and build versions.
  - Fetches "Latest" CU info from Microsoft Learn build-versions pages and resolves the CU download URL.
  - Can install silently now or schedule a silent install at next midnight (runs as SYSTEM).
  - Includes a simple interactive menu when run without action switches.

.PARAMETER InstallNow
  Installs latest detected CU immediately (silent).

.PARAMETER InstallAtMidnight
  Downloads latest detected CU now and schedules silent install at next midnight.

.PARAMETER Force
  Skips interactive confirmation.

.PARAMETER Language
  auto / cs-CZ / en-US / ...

.PARAMETER LogPath
  Path to log file.

.NOTES
  Run as Administrator.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [switch]$InstallNow,
  [switch]$InstallAtMidnight,
  [switch]$Force,
  [string]$Language = "auto",
  [string]$LogPath = "$env:ProgramData\SqlCuPatcher\SqlCuPatcher.log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ===================== i18n (single-file) =====================

$script:I18N = @{
  "cs-CZ" = @{
    Start              = "Start. InstallNow={0} InstallAtMidnight={1} Force={2} Language={3}"
    NeedAdmin          = "Spusť PowerShell jako Administrátor."
    NoInstances        = "Nenašel jsem žádné SQL Server instance v registru."
    FoundInstances     = "Nalezené instance: {0}"
    InstanceLine       = "- {0} | Year={1} | PatchLevel={2} | Edition={3}"
    WUFoundHeader      = "Čekající Windows Update položky (SQL-related):"
    WUNone             = "Ve Windows Update jsem nenašel nic zjevně SQL-related (nebo je to vypnuté/WSUS to nedodává)."
    WULine             = "  * {0} (KBs: {1})"
    CheckingLatest     = "Z webu zjišťuju Latest CU pro SQL Server {0} ..."
    LatestLine         = "SQL {0}: Latest CU{1} | Build {2} | {3}"
    ParseFail          = "Nepodařilo se vyparsovat potřebné údaje z webu (MS Learn/Download Center)."
    NeedsUpdateHeader  = "Instance, které vypadají, že potřebují CU:"
    NeedsUpdateLine    = "- {0} (SQL {1}) {2} -> {3} | {4}"
    UpToDate           = "Vypadá to, že všechny nalezené SQL instance jsou na Latest CU (nebo se nepodařilo porovnat buildy)."
    DoneCheck          = "Kontrola hotová. Pro instalaci použij: -InstallNow nebo -InstallAtMidnight"
    Downloading        = "Stahuju: {0} -> {1}"
    InstallerExists    = "Installer už existuje: {0}"
    SchedulePlanned    = "Naplánováno: {0} na {1} (běží jako SYSTEM, skrytě)."
    InstallStart       = "Spouštím tichou instalaci: ""{0}"" {1}"
    InstallExit        = "Instalátor skončil s ExitCode={0}"
    InstallWarn        = "Instalace vrátila ExitCode={0} (mrkni do SQL setup logů v %ProgramFiles%\Microsoft SQL Server\*\Setup Bootstrap\Log\ )."
    Skipped            = "Přeskočeno."
    Finished           = "Hotovo."
    CompareFail        = "Nepodařilo se porovnat verze pro {0}: {1}"
    WUApiFail          = "Windows Update API dotaz selhal: {0}"
    DownloadFail       = "Stažení selhalo: {0}"
    ScheduleQuestion   = "Naplánovat tichou instalaci pro SQL {0} ({1}) o půlnoci? [A/N]"
    InstallQuestion    = "Spustit tichou instalaci hned pro SQL {0} ({1})? [A/N]"
    MenuTitle          = "SQL Server CU Updater - Menu"
    MenuPrompt         = "Vyber volbu"
    Menu1              = "1) Kontrola (detekce instancí + latest CU)"
    Menu2              = "2) Tichá instalace hned"
    Menu3              = "3) Naplánovat instalaci na půlnoc"
    Menu4              = "4) Změnit jazyk"
    Menu5              = "5) Zobrazit cesty (log/downloads)"
    Menu0              = "0) Konec"
    MenuLangPrompt     = "Zadej jazyk (auto/cs-CZ/en-US nebo vlastní)"
    PathsLine1         = "Log: {0}"
    PathsLine2         = "Downloads: {0}"
    PressEnter         = "Stiskni Enter pro pokračování..."
  }

  "en-US" = @{
    Start              = "Start. InstallNow={0} InstallAtMidnight={1} Force={2} Language={3}"
    NeedAdmin          = "Run PowerShell as Administrator."
    NoInstances        = "No SQL Server instances found in registry."
    FoundInstances     = "Found instances: {0}"
    InstanceLine       = "- {0} | Year={1} | PatchLevel={2} | Edition={3}"
    WUFoundHeader      = "Pending Windows Update items (SQL-related):"
    WUNone             = "No obvious SQL-related updates found in Windows Update (or it is disabled/WSUS does not provide them)."
    WULine             = "  * {0} (KBs: {1})"
    CheckingLatest     = "Checking latest CU for SQL Server {0} ..."
    LatestLine         = "SQL {0}: Latest CU{1} | Build {2} | {3}"
    ParseFail          = "Failed to parse required data from the web (MS Learn/Download Center)."
    NeedsUpdateHeader  = "Instances that appear to need an update:"
    NeedsUpdateLine    = "- {0} (SQL {1}) {2} -> {3} | {4}"
    UpToDate           = "All detected instances appear up-to-date (or build comparison failed)."
    DoneCheck          = "Check finished. To install, use: -InstallNow or -InstallAtMidnight"
    Downloading        = "Downloading: {0} -> {1}"
    InstallerExists    = "Installer already exists: {0}"
    SchedulePlanned    = "Scheduled: {0} at {1} (runs as SYSTEM, hidden)."
    InstallStart       = "Starting silent install: ""{0}"" {1}"
    InstallExit        = "Installer finished with ExitCode={0}"
    InstallWarn        = "Installer returned ExitCode={0} (check SQL setup logs in %ProgramFiles%\Microsoft SQL Server\*\Setup Bootstrap\Log\ )."
    Skipped            = "Skipped."
    Finished           = "Done."
    CompareFail        = "Failed to compare versions for {0}: {1}"
    WUApiFail          = "Windows Update API query failed: {0}"
    DownloadFail       = "Download failed: {0}"
    ScheduleQuestion   = "Schedule silent install for SQL {0} ({1}) at midnight? [Y/N]"
    InstallQuestion    = "Run silent install now for SQL {0} ({1})? [Y/N]"
    MenuTitle          = "SQL Server CU Updater - Menu"
    MenuPrompt         = "Choose an option"
    Menu1              = "1) Check (detect instances + latest CU)"
    Menu2              = "2) Silent install now"
    Menu3              = "3) Schedule install at midnight"
    Menu4              = "4) Change language"
    Menu5              = "5) Show paths (log/downloads)"
    Menu0              = "0) Exit"
    MenuLangPrompt     = "Enter language (auto/cs-CZ/en-US or custom)"
    PathsLine1         = "Log: {0}"
    PathsLine2         = "Downloads: {0}"
    PressEnter         = "Press Enter to continue..."
  }
}

function Resolve-Language {
  param([string]$Language)
  if ($Language -and $Language -ne "auto") { return $Language }
  try { return [System.Globalization.CultureInfo]::CurrentUICulture.Name } catch { return "en-US" }
}

$script:Lang = Resolve-Language -Language $Language

function L {
  param(
    [Parameter(Mandatory)][string]$Key,
    [object[]]$Args
  )

  $dict = $script:I18N[$script:Lang]

  if (-not $dict) {
    $neutral = ($script:Lang -split "-")[0]
    $match = $script:I18N.Keys | Where-Object { $_ -like "$neutral-*" } | Select-Object -First 1
    if ($match) { $dict = $script:I18N[$match] }
  }
  if (-not $dict) { $dict = $script:I18N["en-US"] }

  $template = $dict[$Key]
  if (-not $template) { $template = $Key }

  if ($Args) { return [string]::Format($template, $Args) }
  return $template
}

# ===================== logging =====================

function Write-Log {
  param([string]$Message, [string]$Level="INFO")
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "[$ts][$Level] $Message"
  $dir = Split-Path -Parent $LogPath
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Add-Content -Path $LogPath -Value $line
  Write-Host $line
}

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw (L "NeedAdmin")
  }
}

# ===================== SQL detection =====================

function Get-SqlInstances {
  $paths = @(
    "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\Instance Names\SQL"
  )

  $instances = @()
  foreach ($p in $paths) {
    if (Test-Path $p) {
      $props = Get-ItemProperty -Path $p
      foreach ($name in $props.PSObject.Properties.Name) {
        if ($name -in "PSPath","PSParentPath","PSChildName","PSDrive","PSProvider") { continue }
        $instanceId = $props.$name
        $instances += [pscustomobject]@{
          InstanceName = $name
          InstanceId   = $instanceId
        }
      }
    }
  }

  $instances | Sort-Object InstanceId -Unique
}

function Get-SqlInstanceInfo {
  param([Parameter(Mandatory)]$Instance)

  $setupKeyCandidates = @(
    "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($Instance.InstanceId)\Setup",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\$($Instance.InstanceId)\Setup"
  )

  foreach ($k in $setupKeyCandidates) {
    if (Test-Path $k) {
      $setup = Get-ItemProperty -Path $k

      $get = {
        param($obj, [string]$name)
        if ($obj.PSObject.Properties.Match($name).Count -gt 0) { return $obj.$name }
        return $null
      }

      $patch   = & $get $setup "PatchLevel"
      if (-not $patch) { $patch = & $get $setup "Version" }

      $edition = & $get $setup "Edition"
      $product = & $get $setup "ProductName"

      if (-not $product) {
        $ver = & $get $setup "Version"
        if ($ver) { $product = "Microsoft SQL Server ($ver)" } else { $product = "Microsoft SQL Server" }
      }

      $instId = $Instance.InstanceId
      $major = $null
      if ($instId -match "^MSSQL(\d+)\.") { $major = [int]$Matches[1] }

      $year = switch ($major) {
        11 { 2012 }
        12 { 2014 }
        13 { 2016 }
        14 { 2017 }
        15 { 2019 }
        16 { 2022 }
        17 { 2025 }
        default { $null }
      }

      return [pscustomobject]@{
        InstanceName = $Instance.InstanceName
        InstanceId   = $Instance.InstanceId
        Major        = $major
        Year         = $year
        PatchLevel   = $patch
        Edition      = $edition
        ProductName  = $product
        SetupKey     = $k
      }
    }
  }

  return $null
}

# ===================== web parsing =====================

function Get-WebText {
  param([Parameter(Mandatory)][string]$Url)
  $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing
  return $resp.Content
}

function Get-LatestCuFromBuildVersionsPage {
  param([Parameter(Mandatory)][int]$Year)

  $buildPage = switch ($Year) {
    2012 { "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/sqlserver-2012/build-versions" }
    2014 { "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/sqlserver-2014/build-versions" }
    2016 { "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/sqlserver-2016/build-versions" }
    2017 { "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/sqlserver-2017/build-versions" }
    2019 { "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/sqlserver-2019/build-versions" }
    2022 { "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/sqlserver-2022/build-versions" }
    2025 { "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/sqlserver-2025/build-versions" }
    default { throw "Unsupported SQL Server Year: $Year" }
  }

  $html = Get-WebText -Url $buildPage
  $plain = ($html -replace "<[^>]+>", " ") -replace "\s+", " "

  $m = [regex]::Match(
    $plain,
    "CU\s*(\d+)\s*\(Latest\)\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*?(KB\d{7})",
    "IgnoreCase"
  )

  if (-not $m.Success) {
    throw (L "ParseFail")
  }

  $cuNum  = [int]$m.Groups[1].Value
  $build  = $m.Groups[2].Value
  $kb     = $m.Groups[3].Value

  $slugYear = "sqlserver-$Year"
  $cuArticle = "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/$slugYear/cumulativeupdate$cuNum"

  return [pscustomobject]@{
    Year          = $Year
    LatestCu      = $cuNum
    LatestBuild   = $build
    LatestKB      = $kb
    BuildPageUrl  = $buildPage
    CuArticleUrl  = $cuArticle
  }
}

function Get-DownloadDetailsUrlFromCuArticle {
  param([Parameter(Mandatory)][string]$CuArticleUrl)

  $html = Get-WebText -Url $CuArticleUrl

  $m = [regex]::Match($html, 'https://www\.microsoft\.com/[^"]+/download/details\.aspx\?id=\d+', "IgnoreCase")
  if (-not $m.Success) {
    $m2 = [regex]::Match($html, 'https://www\.microsoft\.com/download/details\.aspx\?id=\d+', "IgnoreCase")
    if ($m2.Success) { return $m2.Value }
    throw (L "ParseFail")
  }
  return $m.Value
}

function Get-DirectDownloadUrlFromMsDownloadDetails {
  param([Parameter(Mandatory)][string]$DetailsUrl)

  $html = Get-WebText -Url $DetailsUrl

  $m = [regex]::Match($html, 'https://download\.microsoft\.com/[^"]+\.exe', "IgnoreCase")
  if ($m.Success) { return $m.Value }

  $m2 = [regex]::Match($html, 'download\.microsoft\.com/[^"]+\.exe', "IgnoreCase")
  if ($m2.Success) { return ("https://" + $m2.Value) }

  throw (L "ParseFail")
}

# ===================== Windows Update (optional info) =====================

function Get-PendingWindowsUpdatesSqlRelated {
  try {
    $session = New-Object -ComObject "Microsoft.Update.Session"
    $searcher = $session.CreateUpdateSearcher()
    $res = $searcher.Search("IsInstalled=0 and Type='Software'")
    $updates = @()
    for ($i=0; $i -lt $res.Updates.Count; $i++) {
      $u = $res.Updates.Item($i)
      if ($u.Title -match "SQL Server|MSSQL|KB\d{7}") {
        $kbs = @()
        try { $kbs = $u.KBArticleIDs } catch {}
        $updates += [pscustomobject]@{
          Title = $u.Title
          KBs   = ($kbs -join ",")
        }
      }
    }
    return $updates
  } catch {
    Write-Log (L "WUApiFail" @($_.Exception.Message)) "WARN"
    return @()
  }
}

# ===================== install helpers =====================

function Download-File {
  param(
    [Parameter(Mandatory)][string]$Url,
    [Parameter(Mandatory)][string]$OutFile
  )

  $dir = Split-Path -Parent $OutFile
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

  Write-Log (L "Downloading" @($Url, $OutFile))
  try {
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
  } catch {
    throw (L "DownloadFail" @($_.Exception.Message))
  }
}

function Install-SqlCuSilent {
  param([Parameter(Mandatory)][string]$InstallerPath)

  if (!(Test-Path $InstallerPath)) { throw "File not found: $InstallerPath" }

  $args = @(
    "/quiet",
    "/IAcceptSQLServerLicenseTerms",
    "/Action=Patch",
    "/AllInstances",
    "/UpdateEnabled=0"
  ) -join " "

  Write-Log (L "InstallStart" @($InstallerPath, $args))
  $p = Start-Process -FilePath $InstallerPath -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
  Write-Log (L "InstallExit" @($p.ExitCode))
  return $p.ExitCode
}

function Schedule-InstallAtMidnight {
  param([Parameter(Mandatory)][string]$InstallerPath)

  $taskName = "SQLServer-CU-Patch"
  $midnight = (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(1)

  # Build a SINGLE argument string for powershell.exe (ScheduledTasks expects a string, not string[])
  $psArgs = @(
    "-NoProfile",
    "-ExecutionPolicy Bypass",
    "-WindowStyle Hidden",
    "-Command",
    "& { `"$InstallerPath`" /quiet /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances /UpdateEnabled=0 }"
  ) -join " "

  $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs
  $trigger = New-ScheduledTaskTrigger -Once -At $midnight
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

  try { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}

  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  Write-Log (L "SchedulePlanned" @($taskName, $midnight.ToString("yyyy-MM-dd HH:mm:ss")))
}

# ===================== core actions =====================


function Invoke-SqlCuCheck {
  Assert-Admin
  Write-Log (L "Start" @($InstallNow, $InstallAtMidnight, $Force, $script:Lang))

  $instances = Get-SqlInstances
  if (-not $instances -or $instances.Count -eq 0) {
    Write-Log (L "NoInstances") "WARN"
    return [pscustomobject]@{ Info=@(); NeedsUpdate=@(); LatestByYear=@{} }
  }

  $info = foreach ($i in $instances) {
    $x = Get-SqlInstanceInfo -Instance $i
    if ($null -ne $x) { $x }
  }

  Write-Log (L "FoundInstances" @($info.Count))
  $info | ForEach-Object {
    Write-Log (L "InstanceLine" @($_.InstanceName, $_.Year, $_.PatchLevel, $_.Edition))
  }

  $wu = Get-PendingWindowsUpdatesSqlRelated
  if ($wu.Count -gt 0) {
    Write-Log (L "WUFoundHeader")
    $wu | ForEach-Object { Write-Log (L "WULine" @($_.Title, $_.KBs)) }
  } else {
    Write-Log (L "WUNone")
  }

  $years = $info.Year | Where-Object { $_ } | Sort-Object -Unique
  $latestByYear = @{}

  foreach ($y in $years) {
    Write-Log (L "CheckingLatest" @($y))
    $cu = Get-LatestCuFromBuildVersionsPage -Year $y
    $detailsUrl = Get-DownloadDetailsUrlFromCuArticle -CuArticleUrl $cu.CuArticleUrl
    $directUrl = Get-DirectDownloadUrlFromMsDownloadDetails -DetailsUrl $detailsUrl

    $latestByYear[$y] = [pscustomobject]@{
      Year         = $y
      CuNum        = $cu.LatestCu
      LatestBuild  = $cu.LatestBuild
      KB           = $cu.LatestKB
      CuArticleUrl = $cu.CuArticleUrl
      DetailsUrl   = $detailsUrl
      DownloadUrl  = $directUrl
    }

    Write-Log (L "LatestLine" @($y, $latestByYear[$y].CuNum, $latestByYear[$y].LatestBuild, $latestByYear[$y].KB))
  }

  $needsUpdate = @()
  foreach ($inst in $info) {
    if (-not $inst.Year) { continue }
    $latest = $latestByYear[$inst.Year]
    try {
      $curV = [version]$inst.PatchLevel
      $latV = [version]$latest.LatestBuild
      if ($curV -lt $latV) {
        $needsUpdate += [pscustomobject]@{
          InstanceName = $inst.InstanceName
          Year         = $inst.Year
          CurrentBuild = $inst.PatchLevel
          LatestBuild  = $latest.LatestBuild
          KB           = $latest.KB
          DownloadUrl  = $latest.DownloadUrl
        }
      }
    } catch {
      Write-Log (L "CompareFail" @($inst.InstanceName, $_.Exception.Message)) "WARN"
    }
  }

  if ($needsUpdate.Count -eq 0) {
    Write-Log (L "UpToDate")
  } else {
    Write-Log (L "NeedsUpdateHeader")
    $needsUpdate | ForEach-Object {
      Write-Log (L "NeedsUpdateLine" @($_.InstanceName, $_.Year, $_.CurrentBuild, $_.LatestBuild, $_.KB))
    }
  }

  return [pscustomobject]@{
    Info        = $info
    NeedsUpdate = $needsUpdate
    LatestByYear= $latestByYear
  }
}

function Invoke-SqlCuInstall {
  param(
    [Parameter(Mandatory)][ValidateSet("Now","Midnight")]
    [string]$Mode
  )

  $result = Invoke-SqlCuCheck
  if (-not $result.NeedsUpdate -or $result.NeedsUpdate.Count -eq 0) {
    return
  }

  $targets = $result.NeedsUpdate | Sort-Object Year -Descending -Unique

  foreach ($t in $targets) {
    $outDir = "$env:ProgramData\SqlCuPatcher\Downloads\SQL$($t.Year)"
    $fileName = "SQL$($t.Year)-$($t.KB)-CU.exe"
    $installer = Join-Path $outDir $fileName

    if (!(Test-Path $installer)) {
      if ($PSCmdlet.ShouldProcess("Download $($t.DownloadUrl)", "Download")) {
        Download-File -Url $t.DownloadUrl -OutFile $installer
      }
    } else {
      Write-Log (L "InstallerExists" @($installer))
    }

    if ($Mode -eq "Midnight") {
      if (-not $Force) {
        $ans = Read-Host (L "ScheduleQuestion" @($t.Year, $t.KB))
        if ($ans -notin @("A","a","Y","y")) { Write-Log (L "Skipped") "WARN"; continue }
      }
      if ($PSCmdlet.ShouldProcess("Schedule midnight install", "Schedule")) {
        Schedule-InstallAtMidnight -InstallerPath $installer
      }
    }

    if ($Mode -eq "Now") {
      if (-not $Force) {
        $ans = Read-Host (L "InstallQuestion" @($t.Year, $t.KB))
        if ($ans -notin @("A","a","Y","y")) { Write-Log (L "Skipped") "WARN"; continue }
      }
      if ($PSCmdlet.ShouldProcess("Install CU now", "Install")) {
        $code = Install-SqlCuSilent -InstallerPath $installer
        if ($code -ne 0) {
          Write-Log (L "InstallWarn" @($code)) "WARN"
        }
      }
    }
  }

  Write-Log (L "Finished")
}

# ===================== menu =====================

function Show-Menu {
  Clear-Host
  Write-Host "========================================"
  Write-Host (L "MenuTitle")
  Write-Host "========================================"
  Write-Host (L "Menu1")
  Write-Host (L "Menu2")
  Write-Host (L "Menu3")
  Write-Host (L "Menu4")
  Write-Host (L "Menu5")
  Write-Host (L "Menu0")
  Write-Host ""
}

function Pause-Menu {
  [void](Read-Host (L "PressEnter"))
}

function Set-LanguageInteractive {
  $newLang = Read-Host (L "MenuLangPrompt")
  if ([string]::IsNullOrWhiteSpace($newLang)) { return }
  $script:Lang = Resolve-Language -Language $newLang
}

# ===================== MAIN =====================

# If action switches provided, run non-interactive mode
if ($InstallNow -or $InstallAtMidnight) {
  Assert-Admin
  if ($InstallAtMidnight) { Invoke-SqlCuInstall -Mode "Midnight"; exit 0 }
  if ($InstallNow) { Invoke-SqlCuInstall -Mode "Now"; exit 0 }
}

# Otherwise interactive menu
while ($true) {
  Show-Menu
  $choice = Read-Host (L "MenuPrompt")
  switch ($choice) {
    "1" {
      Invoke-SqlCuCheck | Out-Null
      Pause-Menu
    }
    "2" {
      $script:Lang = $script:Lang  # keep current
      $global:InstallNow = $true
      $global:InstallAtMidnight = $false
      Invoke-SqlCuInstall -Mode "Now"
      $global:InstallNow = $false
      Pause-Menu
    }
    "3" {
      $global:InstallNow = $false
      $global:InstallAtMidnight = $true
      Invoke-SqlCuInstall -Mode "Midnight"
      $global:InstallAtMidnight = $false
      Pause-Menu
    }
    "4" {
      Set-LanguageInteractive
      Pause-Menu
    }
    "5" {
      $downloads = "$env:ProgramData\SqlCuPatcher\Downloads\"
      Write-Host (L "PathsLine1" @($LogPath))
      Write-Host (L "PathsLine2" @($downloads))
      Pause-Menu
    }
    "0" { break }
    default {
      Pause-Menu
    }
  }
}
