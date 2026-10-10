# audit-slowness-readonly.ps1
# Read-only slowness / health audit for a Windows target. Prints a sectioned report and
# changes NOTHING. Works on PowerShell 5.1 or pwsh 7 (prefer pwsh on trimmed images).
#
# Run it over SSH with the report redirected onto a drive the driving machine can read:
#   cp audit-slowness-readonly.ps1 /y/audit-readonly.ps1
#   ssh -i <key> -o BatchMode=yes user@<ip> "C:\pwsh\pwsh.exe -NoProfile -ExecutionPolicy Bypass -File D:\audit-readonly.ps1 > D:\audit.txt 2>&1"
#   # then read Y:\audit.txt
#
# Interpretation rules live in the skill body: difference the cumulative CPU reads, check the
# login session for idle footprint, distrust Win32_DisplayConfiguration, and report free space
# with drive type.

$ErrorActionPreference = 'Continue'
function Section($t) { "`n===== $t =====" }

Section "A. MESIN, BIOS, OS, BEBAN SEKARANG"
try {
    $cs = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    "  $($cs.Manufacturer) | $($cs.Model) | $($cs.SystemType)"
    Get-CimInstance Win32_BaseBoard | ForEach-Object { "  Mainboard: $($_.Manufacturer) $($_.Product)" }
    Get-CimInstance Win32_BIOS | ForEach-Object { "  BIOS: $($_.Manufacturer) $($_.SMBIOSBIOSVersion) ($($_.ReleaseDate))" }
    "  OS: $($os.Caption) build $($os.BuildNumber) ($($os.Version))"
    "  Boot: $($os.LastBootUpTime)  ->  uptime $([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours,1)) jam"
    "  RAM: $([math]::Round($os.TotalVisibleMemorySize/1MB,1)) GB total, $([math]::Round($os.FreePhysicalMemory/1MB,1)) GB kosong"
    "  Commit: $([math]::Round($os.TotalVirtualMemorySize/1MB,1)) GB (virtual sisa $([math]::Round($os.FreeVirtualMemory/1MB,1)) GB)"
    Get-CimInstance Win32_PageFileUsage | ForEach-Object { "  PAGEFILE: $($_.Name) alokasi $($_.AllocatedBaseSize) MB, terpakai $($_.CurrentUsage) MB, puncak $($_.PeakUsage) MB" }
} catch { "  ERROR: $($_.Exception.Message)" }
try { "  Elevasi: " + ((whoami /groups | Select-String 'S-1-16-').ToString().Trim()) } catch {}
try { "  Power plan: " + (powercfg /getactivescheme) } catch {}

Section "B. CPU"
try {
    Get-CimInstance Win32_Processor | ForEach-Object {
        "  $($_.Name)"
        "  Core/Thread: $($_.NumberOfCores)/$($_.NumberOfLogicalProcessors)  MaxClock: $($_.MaxClockSpeed) MHz  Load: $($_.LoadPercentage)%"
    }
} catch { "  ERROR: $($_.Exception.Message)" }

Section "C. DISK: FISIK, VOLUME, SMART"
try { Get-PhysicalDisk | ForEach-Object { "  FISIK: $($_.FriendlyName) | $([math]::Round($_.Size/1GB,1)) GB | Media=$($_.MediaType) | Bus=$($_.BusType) | Health=$($_.HealthStatus)" } } catch { "  ERROR fisik: $($_.Exception.Message)" }
try {
    Get-PhysicalDisk | ForEach-Object {
        $d = $_
        try {
            $r = $d | Get-StorageReliabilityCounter
            "  SMART $($d.FriendlyName): suhu=$($r.Temperature)C wear=$($r.Wear) readErr=$($r.ReadErrorsTotal) readErrUncorr=$($r.ReadErrorsUncorrected) jamNyala=$($r.PowerOnHours) startStop=$($r.StartStopCycleCount)"
        } catch { "  SMART $($d.FriendlyName): counter tidak tersedia" }
    }
} catch { "  ERROR SMART: $($_.Exception.Message)" }
try { Get-Volume | Where-Object DriveLetter | ForEach-Object { "  VOLUME $($_.DriveLetter): '$($_.FileSystemLabel)' $($_.FileSystem) | $([math]::Round($_.Size/1GB,1)) GB | sisa $([math]::Round($_.SizeRemaining/1GB,1)) GB | Health=$($_.HealthStatus)" } } catch { "  ERROR volume: $($_.Exception.Message)" }
try { Get-Partition | Where-Object DriveLetter | ForEach-Object { "  $($_.DriveLetter): -> Disk $($_.DiskNumber)" }; Get-Disk | ForEach-Object { "  Disk $($_.Number): $($_.FriendlyName) $([math]::Round($_.Size/1GB,1)) GB Boot=$($_.IsBoot)" } } catch {}

Section "D. SAMPLING CPU (4x jendela 15s) + PROSES TERATAS"
try {
    $before = Get-Process | Select-Object Id, ProcessName, CPU
    for ($i = 1; $i -le 4; $i++) {
        $load = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        $free = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)
        "  sample $i : CPU $load%  |  memori kosong $free GB"
        if ($i -lt 4) { Start-Sleep -Seconds 15 }
    }
    $map = @{}
    foreach ($p in $before) { $map[$p.Id] = $p.CPU }
    "  -- delta CPU tertinggi (indikasi beban SEKARANG, bukan kumulatif) --"
    Get-Process | ForEach-Object {
        $old = $map[$_.Id]
        if ($null -ne $old -and $null -ne $_.CPU) {
            [pscustomobject]@{ Nama = $_.ProcessName; Id = $_.Id; Delta = [math]::Round(($_.CPU - $old), 1); MemMB = [int]($_.WorkingSet64/1MB) }
        }
    } | Sort-Object Delta -Descending | Select-Object -First 12 | ForEach-Object { "   {0,-28} PID {1,-6} CPU +{2}s  MEM {3} MB" -f $_.Nama, $_.Id, $_.Delta, $_.MemMB }
    "  -- memori terbesar --"
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | ForEach-Object { "   {0,-28} PID {1,-6} MEM {2} MB" -f $_.ProcessName, $_.Id, [int]($_.WorkingSet64/1MB) }
} catch { "  ERROR: $($_.Exception.Message)" }

Section "E. STARTUP & TASK BOOT/LOGON"
try {
    $su = Get-CimInstance Win32_StartupCommand
    if ($su) { $su | ForEach-Object { "   [$($_.Location)] $($_.Name)" } } else { "   (tidak ada entri)" }
} catch { "  ERROR: $($_.Exception.Message)" }
try {
    $t = Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' -and $_.Triggers.CimClass.CimClassName -match 'Boot|Logon' }
    "   task boot/logon aktif: $($t.Count)"
    $t | Select-Object -First 15 | ForEach-Object { "   $($_.TaskPath)$($_.TaskName)" }
} catch { "  ERROR: $($_.Exception.Message)" }

Section "F. LAYANAN"
try {
    $s = Get-Service
    "   total $($s.Count) | berjalan $(($s | Where-Object Status -eq 'Running').Count)"
    "   -- otomatis tapi tidak berjalan --"
    $s | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } | ForEach-Object { "   $($_.Name) = $($_.Status)" }
} catch { "  ERROR: $($_.Exception.Message)" }
'WinDefend','WSearch','SysMain','wuauserv','BITS','AppIDSvc','StorSvc' | ForEach-Object {
    $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
    if ($svc) { "   {0,-14} {1,-10} {2}" -f $svc.Name, $svc.Status, $svc.StartType } else { "   {0,-14} (tidak ada)" -f $_ }
}

Section "G. EVENT LOG: HOTSPOT & SINYAL"
try {
    $ev = Get-WinEvent -FilterHashtable @{ LogName = 'System','Application'; Level = 1,2; StartTime = (Get-Date).AddDays(-7) } -MaxEvents 400 -ErrorAction SilentlyContinue
    "   error/critical 7 hari (maks 400): $($ev.Count)"
    $ev | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 12 | ForEach-Object { "   {0,-45} {1}" -f $_.Name, $_.Count }
} catch { "   (tidak terbaca)" }
try {
    $d = Get-WinEvent -FilterHashtable @{ LogName = 'System'; StartTime = (Get-Date).AddDays(-30) } -MaxEvents 600 -ErrorAction SilentlyContinue |
         Where-Object { $_.ProviderName -match 'disk|Ntfs|storahci|volmgr' -and $_.Level -le 3 }
    "   event disk/ntfs 30 hari: $($d.Count)"
    $d | Select-Object -First 6 | ForEach-Object { "   $($_.TimeCreated) [$($_.ProviderName)] $($_.Id): " + (($_.Message -split "`n")[0]) }
} catch {}
try {
    $u = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 41,6008,1001; StartTime = (Get-Date).AddDays(-30) } -ErrorAction SilentlyContinue
    "   shutdown tak terduga / bugcheck: $($u.Count)  (41=power loss, 6008=tidak bersih)"
    $u | Select-Object -First 5 | ForEach-Object { "   $($_.TimeCreated) [$($_.ProviderName)] ID $($_.Id)" }
} catch {}

Section "H. NETBIOS / NAMA JARINGAN"
try {
    Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'NetBT'; StartTime = (Get-Date).AddDays(-3) } -MaxEvents 3 -ErrorAction SilentlyContinue |
        ForEach-Object { "   $($_.TimeCreated) ID $($_.Id): " + (($_.Message -split "`n")[0]) }
} catch { "   (tidak ada event NetBT)" }
try { nbtstat -n | Select-String -Pattern '<..>' | Select-Object -First 8 | ForEach-Object { "   $($_.ToString().Trim())" } } catch {}
try { ipconfig /all | Select-String -Pattern 'NetBIOS' | ForEach-Object { "   $($_.ToString().Trim())" } } catch {}

Section "I. GRAFIS, MONITOR, MODE AKTIF"
try {
    Get-CimInstance Win32_VideoController | ForEach-Object {
        "  $($_.Name) | driver $($_.DriverVersion) ($($_.DriverDate)) | $($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution) @ $($_.CurrentRefreshRate) Hz | Status=$($_.Status) err=$($_.ConfigManagerErrorCode)"
    }
} catch { "  ERROR: $($_.Exception.Message)" }
try {
    "  -- mode AKTIF (registry GraphicsDrivers; Win32_DisplayConfiguration sudah usang) --"
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration' -ErrorAction SilentlyContinue | ForEach-Object {
        $cfg = $_.PSChildName
        Get-ChildItem $_.PSPath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Property -contains 'ActiveSize.cx' } | ForEach-Object {
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            $a = "$($p.'ActiveSize.cx')x$($p.'ActiveSize.cy')"
            if ($a -ne 'x') { "   [$cfg] Active=$a  PrimSurf=$($p.'PrimSurfSize.cx')x$($p.'PrimSurfSize.cy')" }
        }
    }
} catch {}
try {
    Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue | ForEach-Object {
        $nm = -join ([char[]]($_.UserFriendlyName | Where-Object { $_ -ne 0 }))
        $mf = -join ([char[]]($_.ManufacturerName | Where-Object { $_ -ne 0 }))
        "   Monitor: '$nm' buatan=$mf tahun=$($_.YearOfManufacture) aktif=$($_.Active)"
    }
} catch {}
try { Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } | ForEach-Object { "   PERANGKAT BERMASALAH kode $($_.ConfigManagerErrorCode): $($_.Name)" } } catch {}

Section "J. SESI LOGIN & JEJAK IDLE"
try { query user 2>&1 | ForEach-Object { "   $_" } } catch {}
try {
    "   -- proses milik sesi pengguna (footprint idle) --"
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -ne 0 } | Group-Object ProcessName |
        Sort-Object Count -Descending | Select-Object -First 12 | ForEach-Object { "   $($_.Name) x$($_.Count)" }
} catch {}
try {
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        "   $k : $(if (Test-Path $k) { 'ADA -> reboot tertunda' } else { 'tidak ada' })"
    }
    Get-CimInstance Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 4 | ForEach-Object { "   update terakhir: $($_.HotFixID) $($_.InstalledOn)" }
} catch {}

Section "SELESAI $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
