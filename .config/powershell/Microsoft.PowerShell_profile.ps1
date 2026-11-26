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

# Preserve command status and Git state when repainting.
$global:PromptState = @{
    Mode = 'INS'
    Repaint = $false
    Branch = ''
    Failed = $false
    LastJ = $null
}

function global:prompt {
    $ok = $?
    $nativeExit = $global:LASTEXITCODE
    $state = $global:PromptState
    $PSNativeCommandUseErrorActionPreference = $false

    try {
        if (-not $state.Repaint) {
            $state.Failed = -not $ok
            $state.Branch = ''
            $state.LastJ = $null
            $state.Mode = 'INS'

            if ($executionContext.SessionState.Path.CurrentLocation.Provider.Name -eq 'FileSystem' -and
                (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {

                $branch = & git symbolic-ref --quiet --short HEAD 2>$null

                if ($LASTEXITCODE -ne 0) {
                    $branch = & git rev-parse --short HEAD 2>$null
                }

                if ($LASTEXITCODE -eq 0 -and $branch) {
                    $dirty = & git --no-optional-locks status --porcelain --untracked-files=normal 2>$null
                    $state.Branch = ' ' + ($branch -join '') + $(
                        if ($LASTEXITCODE -eq 0 -and $dirty) { '*' }
                    )
                }
            }
        }

        $p = $executionContext.SessionState.Path.CurrentLocation.Path
        $sep = [IO.Path]::DirectorySeparatorChar

        if ($p -eq $HOME) {
            $p = '~'
        }
        elseif ($p.StartsWith($HOME.TrimEnd($sep) + $sep, [StringComparison]::Ordinal)) {
            $p = '~' + $p.Substring($HOME.TrimEnd($sep).Length)
        }

        $p = $p -replace '[\x00-\x1f\x7f]', '?'
        $branchText = $state.Branch -replace '[\x00-\x1f\x7f]', '?'
        $fail = if ($state.Failed) { ' failed' } else { '' }

        $modeColor = if ($state.Mode -eq 'NOR') {
            $PSStyle.Foreground.Yellow
        } else {
            $PSStyle.Foreground.Green
        }

        $reset = $PSStyle.Reset

        "$($PSStyle.Foreground.Blue)╭─ $(Get-Date -Format HH:mm:ss) ── $([Environment]::MachineName)$reset`n" +
        "${modeColor}╰─ [$($state.Mode)]$reset $($PSStyle.Foreground.Cyan)$p$reset$($PSStyle.Foreground.Magenta)$branchText$reset$($PSStyle.Foreground.Red)$fail$reset > "
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
