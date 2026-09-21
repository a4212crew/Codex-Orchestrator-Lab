param(
    [string]$Repo = "a4212crew/Codex-Orchestrator-Lab",
    [string]$Label = "codex-task",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "Checking for open Codex tasks..."

$issueJson = gh issue list `
    --repo $Repo `
    --label $Label `
    --state open `
    --limit 1 `
    --json number,title,body,url

$issues = $issueJson | ConvertFrom-Json

if (-not $issues -or $issues.Count -eq 0) {
    Write-Host "No open Codex tasks found."
    exit 0
}

$issue = $issues[0]

Write-Host "Found issue #$($issue.number): $($issue.title)"

$prompt = @"
Follow AGENTS.md.

GitHub task:
$($issue.title)

$($issue.body)

Requirements:
- Work only in this repository.
- Do not commit or push.
- Do not modify unrelated files.
- Run relevant tests when possible.
- Report files changed, test results, and any issues encountered.
"@

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN MODE"
    Write-Host "Codex will NOT be executed."
    Write-Host ""
    Write-Host "Prompt that would be sent to Codex:"
    Write-Host "--------------------------------"
    Write-Host $prompt
    Write-Host "--------------------------------"
    Write-Host ""
    Write-Host "Dry run completed successfully."
    exit 0
}

Write-Host "Starting Codex..."
Write-Host ""

$tempFile = Join-Path $env:TEMP "codex-output-$($issue.number).txt"

if (Test-Path $tempFile) {
    Remove-Item $tempFile -Force
}

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"

& codex exec $prompt 2>&1 | Tee-Object -FilePath $tempFile

$codexExitCode = $LASTEXITCODE

$ErrorActionPreference = $previousErrorActionPreference

if (Test-Path $tempFile) {
    $codexOutput = Get-Content $tempFile -Raw
}
else {
    $codexOutput = ""
}

if ($codexExitCode -ne 0) {
    Write-Host ""
    Write-Host "Codex exited with code $codexExitCode."
    exit $codexExitCode
}

Write-Host ""
Write-Host "Codex finished successfully."
Write-Host "Collecting repository status..."

$gitStatus = git status --short | Out-String
$gitDiff = git diff | Out-String

$commentLines = @(
    "## Codex Result"
    ""
    "### Codex Output"
    ""
    '```text'
    $codexOutput.TrimEnd()
    '```'
    ""
    "### Git Status"
    ""
    '```text'
    $gitStatus.TrimEnd()
    '```'
    ""
    "### Git Diff"
    ""
    '```diff'
    $gitDiff.TrimEnd()
    '```'
)

$comment = $commentLines -join "`n"

Write-Host "Posting result to GitHub issue #$($issue.number)..."

$comment | gh issue comment $issue.number `
    --repo $Repo `
    --body-file -

Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Result posted successfully."
Write-Host "Issue: $($issue.url)"