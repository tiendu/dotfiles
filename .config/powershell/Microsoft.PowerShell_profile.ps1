# PowerShell 7: native PSReadLine, optional CLI tools, no framework.
foreach ($candidate in 'nvim', 'vim', 'vi') {
    if (Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue) {
        $env:EDITOR = $candidate
        $env:VISUAL = $candidate
        if ($candidate -eq 'nvim') {
            Set-Alias vi nvim -Scope Global -Force
            Set-Alias vim nvim -Scope Global -Force
        }
        break
    }
}

function config {
    & git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" @args
}

function .. { Set-Location -LiteralPath '..' }
function ... { Set-Location -LiteralPath '../..' }
function .... { Set-Location -LiteralPath '../../..' }
function ..... { Set-Location -LiteralPath '../../../..' }

function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    $dir = New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop
    Set-Location -LiteralPath $dir.FullName
}

function extract {
    param([Parameter(Mandatory)][string]$Path)
    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($file.PSIsContainer) { throw 'Expected an archive file' }
    if ($file.Name -like '*.zip') {
        Expand-Archive -LiteralPath $file.FullName -DestinationPath .
    }
    elseif ($file.Name -match '\.(tar|tar\.gz|tgz|tar\.bz2|tar\.xz)$') {
        & tar -xf $file.FullName
        if ($LASTEXITCODE -ne 0) { throw "tar failed: $LASTEXITCODE" }
    } else { throw "Unsupported archive: $Path" }
}

# Do not shadow the built-in copy alias (Copy-Item).
function clipcopy {
    param([Parameter(ValueFromPipeline)][AllowEmptyString()][string]$Text, [string]$Path)
    begin { $lines = [System.Collections.Generic.List[string]]::new() }
    process { if ($null -ne $Text) { $lines.Add($Text) } }
    end {
        if ($Path) {
            Get-Content -LiteralPath $Path -Raw -ErrorAction Stop |
                Set-Clipboard -ErrorAction Stop
        } else {
            Set-Clipboard -Value ($lines -join [Environment]::NewLine) -ErrorAction Stop
        }
    }
}

function clippaste {
    Get-Clipboard -Raw -ErrorAction Stop
}

function watch {
    param(
        [Parameter(Mandatory,Position=0)][scriptblock]$Command,
        [ValidateRange(0.1,86400)][double]$Interval = 2
    )
    while ($true) {
        Clear-Host
        Get-Date
        & $Command | Out-Host
        Start-Sleep -Milliseconds ([int]($Interval * 1000))
    }
}

function path_entries {
    $env:PATH -split [IO.Path]::PathSeparator
}

function which {
    param([Parameter(Mandatory)][string]$Name)
    Get-Command $Name -All
}

function ports {
    if ($IsWindows) {
        Get-NetTCPConnection -State Listen
    }
    elseif (Get-Command ss -ErrorAction SilentlyContinue) {
        & ss -lntup
    }
    elseif (Get-Command lsof -ErrorAction SilentlyContinue) {
        & lsof -nP -iTCP -sTCP:LISTEN
    }
    else {
        throw 'No supported port inspection command available'
    }
}

function ff {
    param([string]$Root = '.')
    if (-not (Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue)) {
        Get-ChildItem -LiteralPath $Root -File -Recurse
        return
    }
    if (Get-Command fd -CommandType Application -ErrorAction SilentlyContinue) {
        $file = & fd -t f . $Root | & fzf
    } else {
        $file = Get-ChildItem -LiteralPath $Root -File -Recurse |
            ForEach-Object FullName | & fzf
    }
    if ($file -and $env:EDITOR) {
        & $env:EDITOR -- $file
    }
}

if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) {
    $init = & zoxide init powershell | Out-String
    if ($LASTEXITCODE -eq 0) { Invoke-Expression $init }
}

if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
    function ll { & eza -l @args }
    function la { & eza -la @args }
} else {
    function ll { Get-ChildItem @args }
    function la { Get-ChildItem -Force @args }
}

# Preserve command status and cached directory statistics when repainting.
$global:PromptState = @{
    Mode = 'INS'
    Repaint = $false
    Failed = $false
    LastJ = $null
    DirectoryPath = $null
    DirectoryTime = 0L
    DirectoryInfo = '≡ ? · □ ? · ?'
    PromptRows = 1
}

function Get-PromptDirectoryInfo {
    param([string]$Path)
    $files = 0; $dirs = 0; $seen = 0
    $bytes = 0L; $complete = $true; $valid = $true
    $entries = $null
    try {
        $options = [IO.EnumerationOptions]::new()
        $options.AttributesToSkip = 0
        $options.IgnoreInaccessible = $false
        $options.RecurseSubdirectories = $false
        $entries = [IO.DirectoryInfo]::new($Path).EnumerateFileSystemInfos('*', $options).GetEnumerator()
        while ($entries.MoveNext()) {
            if ($seen -ge 512) { $complete = $false; break }
            $seen++
            $entry = $entries.Current
            try {
                if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
                if ($entry -is [IO.DirectoryInfo]) { $dirs++ }
                elseif ($entry -is [IO.FileInfo]) {
                    $files++
                    $bytes += $entry.Length
                }
            } catch { $valid = $false; $complete = $false }
        }
    } catch {
        if ($seen -eq 0) { return '≡ ? · □ ? · ?' }
        $complete = $false
    } finally {
        if ($null -ne $entries) { $entries.Dispose() }
    }
    $size = '?'
    if ($valid) {
        $unit = 1L
        foreach ($label in 'B', 'KiB', 'MiB', 'GiB', 'TiB') {
            if ($bytes / $unit -lt 1024 -or $label -eq 'TiB') { break }
            $unit *= 1024
        }
        if ($unit -eq 1) { $size = "$bytes B" }
        else {
            $value = [math]::Floor(($bytes / $unit) * 10) / 10
            $size = $value.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture) + " $label"
        }
    }
    $suffix = if ($complete) { '' } else { ' …' }
    "≡ $files · □ $dirs · $size$suffix"
}

function Get-TextCells {
    param([string]$Text)
    try { $Host.UI.RawUI.LengthInBufferCells($Text) }
    catch { [Text.Encoding]::UTF8.GetByteCount($Text.Replace('…', '.').Replace('≡', '=').Replace('□', '+').Replace('·', '.')) }
}

# Use text-element boundaries so we do not split surrogate pairs or graphemes.
function Get-FitText {
    param([string]$Text, [int]$Budget, [switch]$End, [switch]$Tail)
    if ((Get-TextCells $Text) -le $Budget) { return $Text }
    if ($Budget -le 0) { return '' }
    $offsets = [Globalization.StringInfo]::ParseCombiningCharacters($Text)
    for ($n = [math]::Min($Budget - 1, $offsets.Length - 1); $n -gt 0; $n--) {
        if ($End) { $piece = $Text.Substring(0, $offsets[$n]) + '…' }
        else {
            $left = [int][math]::Ceiling($n / 2)
            if ($Tail -and $n -gt 2) { $left = [int][math]::Floor($n * 2 / 5) }
            $right = $n - $left
            $piece = $Text.Substring(0, $offsets[$left]) + '…'
            if ($right -gt 0) { $piece += $Text.Substring($offsets[$offsets.Length - $right]) }
        }
        if ((Get-TextCells $piece) -le $Budget) { return $piece }
    }
    '…'
}

function global:prompt {
    $ok = $?
    $nativeExit = $global:LASTEXITCODE
    $state = $global:PromptState
    $location = $executionContext.SessionState.Path.CurrentLocation

    try {
        if (-not $state.Repaint) {
            $state.Failed = -not $ok
            $state.LastJ = $null
            $state.Mode = 'INS'
            if ($location.Provider.Name -eq 'FileSystem') {
                $directory = $location.ProviderPath
                $now = [Environment]::TickCount64
                if ($state.DirectoryPath -cne $directory -or $now - $state.DirectoryTime -ge 30000) {
                    $state.DirectoryInfo = Get-PromptDirectoryInfo $directory
                    $state.DirectoryPath = $directory
                    $state.DirectoryTime = [Environment]::TickCount64
                }
            } else {
                $state.DirectoryPath = $null
                $state.DirectoryInfo = '≡ ? · □ ? · ?'
            }
        }

        $p = $location.Path
        $sep = [IO.Path]::DirectorySeparatorChar

        if ($p -eq $HOME) {
            $p = '~'
        }
        elseif ($p.StartsWith($HOME.TrimEnd($sep) + $sep, $(if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }))) {
            $p = '~' + $p.Substring($HOME.TrimEnd($sep).Length)
        }

        $p = $p -replace '[\x00-\x1f\x7f]', '?'
        $fail = if ($state.Failed) { ' ✗' } else { '' }

        $modeColor = if ($state.Mode -eq 'NOR') {
            $PSStyle.Foreground.Yellow
        } else {
            $PSStyle.Foreground.Green
        }

        $reset = $PSStyle.Reset

        $width = 80
        try { $width = $Host.UI.RawUI.WindowSize.Width } catch {}
        if ($width -le 0) { $width = 80 }
        $rail = $PSStyle.Bold + $PSStyle.Foreground.Blue
        $cyan = $PSStyle.Foreground.Cyan
        $red = $PSStyle.Foreground.Red
        $compact = $width -lt 20 -or $env:TERM -eq 'dumb'
        $rows = 0
        $first = ''
        if (-not $compact) {
            $symbol = if ($state.Mode -eq 'NOR') { '■' } else { '●' }
            $label = "$symbol $($state.Mode)"
            $machine = Get-FitText ([Environment]::MachineName) ($width - 16 - $fail.Length)
            $meta = [DateTime]::Now.ToString('HH:mm:ss')
            if ($machine) { $meta = "$machine · $meta" }
            $first = "${rail}┏━━┫ $reset$modeColor$label$reset${rail} ┣━━$reset"
            if (15 + (Get-TextCells $meta) + $fail.Length -lt $width) {
                $first += " $meta$red$fail$reset`n"
                $rows = 1
            } else {
                $first += "`n${rail}┣━━ $reset$meta$red$fail$reset`n"
                $rows = 2
            }
            $p = Get-FitText $p ([math]::Min(40, $width - 5)) -Tail
            $first += "${rail}┣━━ $reset$cyan$p$reset"
            if (4 + (Get-TextCells $p) + 4 + (Get-TextCells $state.DirectoryInfo) -lt $width) {
                $first += "${rail} ━━ $reset$($state.DirectoryInfo)`n"
                $rows++
            } else {
                $stats = Get-FitText $state.DirectoryInfo ($width - 5) -End
                $first += "`n${rail}┣━━ $reset$stats`n"
                $rows += 2
            }
        }
        # PSReadLine needs the number of metadata lines above input.
        if ($state.PromptRows -ne $rows -and (Get-Module PSReadLine)) {
            Set-PSReadLineOption -ExtraPromptLineCount $rows
            $state.PromptRows = $rows
        }
        if ($compact) { return '> ' }
        $first + "${rail}┗━━$reset${modeColor}❯$reset "
    }
    finally {
        $global:LASTEXITCODE = $nativeExit
    }
}

# PSReadLine
if ($Host.Name -eq 'ConsoleHost' -and
    -not [Console]::IsInputRedirected -and
    (Get-Module -ListAvailable -Name PSReadLine)) {

    Import-Module PSReadLine

    Set-PSReadLineOption `
        -EditMode Vi `
        -HistorySaveStyle SaveIncrementally `
        -HistoryNoDuplicates `
        -MaximumHistoryCount 10000 `
        -ExtraPromptLineCount 1

    if ((Get-Module PSReadLine).Version -ge [version]'2.1.0') {
        Set-PSReadLineOption -PredictionSource History

        if ((Get-Module PSReadLine).Version -ge [version]'2.2.0') {
            Set-PSReadLineOption -PredictionViewStyle InlineView
        }
    }

    $bindings = @{
        Tab             = 'MenuComplete'
        'Ctrl+Spacebar' = 'MenuComplete'
        UpArrow         = 'HistorySearchBackward'
        DownArrow       = 'HistorySearchForward'
        'Ctrl+r'        = 'ReverseSearchHistory'
        RightArrow      = 'ForwardChar'
        'Ctrl+f'        = 'ForwardChar'
        'Ctrl+b'        = 'BackwardChar'
        'Ctrl+p'        = 'HistorySearchBackward'
        'Ctrl+n'        = 'HistorySearchForward'
        'Ctrl+a'        = 'BeginningOfLine'
        'Ctrl+e'        = 'EndOfLine'
        'Shift+Tab'     = 'TabCompletePrevious'
        Enter           = 'ValidateAndAcceptLine'
        F1              = 'ShowCommandHelp'
        'Alt+e'         = 'ViEditVisually'
        Backspace       = 'BackwardDeleteChar'
    }

    $available = (Get-PSReadLineKeyHandler -Bound -Unbound).Function

    foreach ($key in $bindings.Keys) {
        if ($bindings[$key] -in $available) {
            Set-PSReadLineKeyHandler -ViMode Insert -Chord $key -Function $bindings[$key]
        }
    }

    # jk escapes Insert mode.
    Set-PSReadLineKeyHandler -ViMode Insert -Chord j -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('j')

        $line = ''
        $cursor = 0

        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$line, [ref]$cursor
        )

        $global:PromptState.LastJ = @{
            Line = $line
            Cursor = $cursor
            Time = [Environment]::TickCount64
        }
    }

    Set-PSReadLineKeyHandler -ViMode Insert -Chord k -ScriptBlock {
        $line = ''
        $cursor = 0

        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$line, [ref]$cursor
        )

        $j = $global:PromptState.LastJ
        $global:PromptState.LastJ = $null

        if ($j -and
            $cursor -gt 0 -and
            $cursor -eq $j.Cursor -and
            $line -ceq $j.Line -and
            ([Environment]::TickCount64 - $j.Time) -le 250) {

            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                $cursor - 1, 1, ''
            )

            [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode(
                $null, $null
            )
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert('k')
        }
    }

    Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
        param($mode)

        $state = $global:PromptState
        $state.Mode = if ($mode -eq 'Command') { 'NOR' } else { 'INS' }
        $state.LastJ = $null
        $state.Repaint = $true

        try {
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt(
                $null, $null
            )
        }
        finally {
            $state.Repaint = $false
        }
    }
}

# Native .NET CLI completion.
if (Get-Command dotnet -CommandType Application -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)

        & dotnet complete --position $cursorPosition $commandAst.ToString() 2>$null |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    $_, $_, 'ParameterValue', $_
                )
            }
    }
}
