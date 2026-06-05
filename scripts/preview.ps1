param(
  [Parameter(Mandatory=$true)][string]$Sample,
  [Parameter(Mandatory=$true)][string]$Out
)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$workspace = Join-Path $repo "samples"
$code = "C:\Users\LTY\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd"
# 隔離 profile:獨立的 user-data-dir / extensions-dir → 全新且獨立的 VSCode 實例,
# 與使用者正在用的 VSCode 完全不共用進程,可安全鎖定與清理。
$udd = Join-Path $env:TEMP "tp-devhost-udd"
$edd = Join-Path $env:TEMP "tp-devhost-ext"

# Win32 API:PrintWindow 可截背景視窗,不需搶前景
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Cap {
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT r);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int n);
  public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
Add-Type -AssemblyName System.Drawing

# 0. Seed 隔離 profile 的全域 settings,關閉首次體驗 / AI 登入彈窗 / 遙測 / 更新提示
$userDir = Join-Path $udd "User"
New-Item -ItemType Directory -Force -Path $userDir | Out-Null
@'
{
    "chat.disableAIFeatures": true,
    "workbench.startupEditor": "none",
    "workbench.welcomePage.walkthroughs.openOnInstall": false,
    "workbench.tips.enabled": false,
    "telemetry.telemetryLevel": "off",
    "update.mode": "none",
    "extensions.ignoreRecommendations": true,
    "window.commandCenter": false,
    "git.openRepositoryInParentFolders": "never"
}
'@ | Set-Content -Path (Join-Path $userDir "settings.json") -Encoding UTF8

# 1. 記錄啟動前既有的 Code 進程(使用者自己的 VSCode)
$before = @(Get-Process Code -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)

# 2. 啟動隔離的 dev host 實例(extensions-dir 為空 → 無其他擴充雜訊;停用工作區信任提示)
& $code --user-data-dir="$udd" --extensions-dir="$edd" --disable-workspace-trust `
        --extensionDevelopmentPath="$repo" --new-window "$workspace" -g "${Sample}:1" | Out-Null

# 3. 等待「新實例」的視窗出現(新 PID + 有可見視窗)
$proc = $null
for ($i=0; $i -lt 80; $i++) {
  Start-Sleep -Milliseconds 750
  $proc = Get-Process Code -ErrorAction SilentlyContinue |
    Where-Object { $before -notcontains $_.Id -and $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -ne '' } |
    Sort-Object StartTime -Descending | Select-Object -First 1
  if ($proc) { break }
}
if (-not $proc) { throw "dev host window not found" }

# 4. maximize,留時間給 tokenizer
$h = $proc.MainWindowHandle
[Cap]::ShowWindow($h, 3) | Out-Null
Start-Sleep -Seconds 4

# 5. PrintWindow 截圖(PW_RENDERFULLCONTENT = 2)
$r = New-Object Cap+RECT
[Cap]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left; $ht = $r.Bottom - $r.Top
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[Cap]::PrintWindow($h, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "window: $($proc.MainWindowTitle)"

# 6. 清理:kill 這個隔離實例啟動後新增的所有進程(絕不動 $before 裡使用者的視窗)
Get-Process Code -ErrorAction SilentlyContinue |
  Where-Object { $before -notcontains $_.Id } |
  ForEach-Object { try { $_.Kill() } catch {} }
Write-Output "saved $Out"
