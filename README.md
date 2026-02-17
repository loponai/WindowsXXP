# WindowsXXP

One-shot Windows debloat, privacy hardening, and performance tuning script. Run once, restart, done.

## What It Does

| Category | Details |
|----------|---------|
| **Bloatware** | Removes 80+ pre-installed apps (Candy Crush, TikTok, Clipchamp, etc.) |
| **Telemetry** | Registry, hosts file (60+ domains), and firewall rules block Microsoft tracking |
| **Privacy** | Disables advertising ID, location, activity history, clipboard sync, speech recognition |
| **Performance** | Animations off, fast shutdown, startup delay removed, mouse acceleration off |
| **Power** | Activates Ultimate/High Performance power plan, disables hibernation |
| **Network** | Nagle's algorithm off (lower latency), TCP tuned, SMBv1/NetBIOS/LLMNR disabled |
| **Services** | Disables 20+ unnecessary services (Superfetch, Search Indexer, Fax, etc.) |
| **Tasks** | Disables telemetry scheduled tasks (Compatibility Appraiser, CEIP, etc.) |
| **Explorer** | Show file extensions, hidden files, This PC as default, classic context menu |
| **Windows 11** | Disables Copilot, Recall (AI), Widgets, restores classic right-click menu |
| **Edge** | Disables startup boost, background mode, sidebar, Copilot, shopping, telemetry |
| **Defender** | Keeps protection active, reduces telemetry (SpyNet, sample submission) |
| **Updates** | No auto-restart, no driver updates via WU, local-only delivery optimization |
| **Cleanup** | Clears temp files, prefetch, update cache, runs disk cleanup |

## What It Preserves

- Xbox, Game Bar, Gaming services (configurable)
- Dolby Audio/Access (configurable)
- Windows Store, Calculator, Photos, Snipping Tool, Terminal
- Windows Defender (protection stays active)
- OneDrive (optional removal)

## Usage

### Option 1: Double-click
Download and double-click `Run.bat` — it handles admin elevation automatically.

### Option 2: PowerShell
```powershell
# Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\WindowsXXP.ps1
```

### Option 3: One-liner
```powershell
irm https://raw.githubusercontent.com/loponai/WindowsXXP/main/WindowsXXP.ps1 | iex
```

## Interactive Options

The script asks before running:

| Prompt | Default | Description |
|--------|---------|-------------|
| Keep Xbox apps & Game Bar? | **Yes** | Preserves Xbox, Game Bar, gaming services |
| Keep Dolby Audio/Access? | **Yes** | Preserves Dolby apps |
| Remove OneDrive completely? | **No** | Full uninstall + Explorer cleanup |
| Harden Microsoft Edge? | **Yes** | Disables Edge bloat via Group Policy |

## Safety

- Creates a **System Restore Point** before making any changes
- Logs all actions to `Desktop\WindowsXXP-Log_*.txt`
- Does **not** disable Windows Defender protection
- Does **not** disable Windows Update (just tunes it)
- Does **not** touch GPU drivers or gaming peripherals

## Requirements

- Windows 10 / 11
- Administrator privileges
- PowerShell 5.1+

## License

MIT
