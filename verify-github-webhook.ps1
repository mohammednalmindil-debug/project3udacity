# PowerShell script to verify CodeBuild GitHub webhook setup
# Run this script to check if everything is configured correctly

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "coworking-build"
)

Write-Host "Verifying CodeBuild GitHub webhook setup..." -ForegroundColor Green

# Step 1: Check if CodeBuild project exists
Write-Host "`n1. Checking CodeBuild project..." -ForegroundColor Yellow
try {
    $project = aws codebuild batch-get-projects --names $ProjectName --region us-east-1 --output json | ConvertFrom-Json
    if ($project.projects.Count -gt 0) {
        Write-Host "✓ CodeBuild project '$ProjectName' exists" -ForegroundColor Green
        
        $proj = $project.projects[0]
        Write-Host "  - Source: $($proj.source.type)" -ForegroundColor White
        Write-Host "  - Location: $($proj.source.location)" -ForegroundColor White
        Write-Host "  - Buildspec: $($proj.source.buildspec)" -ForegroundColor White
        
        if ($proj.logsConfig.cloudWatchLogs.status -eq "ENABLED") {
            Write-Host "  - CloudWatch Logs: ENABLED" -ForegroundColor Green
        } else {
            Write-Host "  - CloudWatch Logs: DISABLED" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ CodeBuild project '$ProjectName' not found" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error checking CodeBuild project: $_" -ForegroundColor Red
}

# Step 2: Check webhook configuration
Write-Host "`n2. Checking webhook configuration..." -ForegroundColor Yellow
try {
    $webhook = aws codebuild batch-get-projects --names $ProjectName --region us-east-1 --output json | ConvertFrom-Json
    if ($webhook.projects.Count -gt 0 -and $webhook.projects[0].webhook) {
        Write-Host "✓ Webhook is configured" -ForegroundColor Green
        Write-Host "  - URL: $($webhook.projects[0].webhook.url)" -ForegroundColor White
        Write-Host "  - Secret: $($webhook.projects[0].webhook.secret)" -ForegroundColor White
    } else {
        Write-Host "✗ Webhook not configured" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error checking webhook: $_" -ForegroundColor Red
}

# Step 3: Check CloudWatch log group
Write-Host "`n3. Checking CloudWatch log group..." -ForegroundColor Yellow
try {
    $logGroups = aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild/$ProjectName" --region us-east-1 --output json | ConvertFrom-Json
    if ($logGroups.logGroups.Count -gt 0) {
        Write-Host "✓ CloudWatch log group exists" -ForegroundColor Green
        Write-Host "  - Log Group: $($logGroups.logGroups[0].logGroupName)" -ForegroundColor White
    } else {
        Write-Host "⚠ CloudWatch log group will be created on first build" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking CloudWatch logs: $_" -ForegroundColor Red
}

# Step 4: Check recent builds
Write-Host "`n4. Checking recent builds..." -ForegroundColor Yellow
try {
    $builds = aws codebuild list-builds-for-project --project-name $ProjectName --region us-east-1 --output json | ConvertFrom-Json
    if ($builds.ids.Count -gt 0) {
        Write-Host "✓ Found $($builds.ids.Count) recent builds" -ForegroundColor Green
        
        # Get details of the most recent build
        $recentBuild = aws codebuild batch-get-builds --ids $builds.ids[0] --region us-east-1 --output json | ConvertFrom-Json
        if ($recentBuild.builds.Count -gt 0) {
            $build = $recentBuild.builds[0]
            Write-Host "  - Most recent build: $($build.id)" -ForegroundColor White
            Write-Host "  - Status: $($build.buildStatus)" -ForegroundColor White
            Write-Host "  - Initiator: $($build.initiator)" -ForegroundColor White
            
            if ($build.initiator -like "*GitHub-Hookshot*") {
                Write-Host "  ✓ Build was triggered by GitHub webhook!" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ Build was not triggered by GitHub webhook" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "⚠ No builds found yet" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking builds: $_" -ForegroundColor Red
}

# Step 5: Test webhook URL accessibility
Write-Host "`n5. Testing webhook URL..." -ForegroundColor Yellow
try {
    $webhook = aws codebuild batch-get-projects --names $ProjectName --region us-east-1 --output json | ConvertFrom-Json
    if ($webhook.projects.Count -gt 0 -and $webhook.projects[0].webhook) {
        $webhookUrl = $webhook.projects[0].webhook.url
        Write-Host "Webhook URL: $webhookUrl" -ForegroundColor Cyan
        Write-Host "Add this URL to your GitHub repository webhook settings:" -ForegroundColor White
        Write-Host "1. Go to your GitHub repository" -ForegroundColor White
        Write-Host "2. Settings → Webhooks → Add webhook" -ForegroundColor White
        Write-Host "3. Payload URL: $webhookUrl" -ForegroundColor White
        Write-Host "4. Content type: application/json" -ForegroundColor White
        Write-Host "5. Events: Just the push event" -ForegroundColor White
        Write-Host "6. Active: checked" -ForegroundColor White
    }
} catch {
    Write-Host "✗ Error getting webhook URL: $_" -ForegroundColor Red
}

Write-Host "`nVerification completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Add the webhook URL to your GitHub repository" -ForegroundColor White
Write-Host "2. Make a test commit to the main branch" -ForegroundColor White
Write-Host "3. Check the CodeBuild console for the triggered build" -ForegroundColor White
Write-Host "4. Verify the build shows 'Initiator: GitHub-Hookshot'" -ForegroundColor White
