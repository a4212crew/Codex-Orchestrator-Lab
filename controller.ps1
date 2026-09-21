param(
    [string]$Repo = "a4212crew/Codex-Orchestrator-Lab",
    [string]$Label = "codex-task"
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

Write-Host "Starting Codex..."

$codexOutput = codex exec $prompt 2>&1 | Out-String

Write-Host "Collecting git diff..."

$gitStatus = git status --short | Out-String
$gitDiff = git diff | Out-String

$comment = @"
## Codex Result

### Codex Output

````text
$codexOutput