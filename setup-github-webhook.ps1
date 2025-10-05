# PowerShell script to create CodeBuild project with GitHub webhook integration
# Run this script to set up automatic builds on GitHub commits

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepoUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "coworking-build"
)

Write-Host "Setting up CodeBuild project with GitHub webhook integration..." -ForegroundColor Green

# Step 1: Create the CodeBuild project
Write-Host "Creating CodeBuild project: $ProjectName" -ForegroundColor Yellow

$projectConfig = @{
    name = $ProjectName
    description = "Build and deploy coworking analytics application to ECR with GitHub webhook integration"
    source = @{
        type = "GITHUB"
        location = $GitHubRepoUrl
        buildspec = "deployments/buildspec-with-health-check.yaml"
        gitCloneDepth = 1
        insecureSsl = $false
        reportBuildStatus = $true
    }
    artifacts = @{
        type = "NO_ARTIFACTS"
    }
    environment = @{
        type = "LINUX_CONTAINER"
        image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
        computeType = "BUILD_GENERAL1_MEDIUM"
        privilegedMode = $true
        environmentVariables = @(
            @{
                name = "AWS_ACCOUNT_ID"
                value = "767398149973"
            },
            @{
                name = "AWS_DEFAULT_REGION"
                value = "us-east-1"
            },
            @{
                name = "IMAGE_REPO_NAME"
                value = "coworking-analytics"
            }
        )
    }
    serviceRole = "arn:aws:iam::767398149973:role/CoworkingAnalyticsCodeBuildRole"
    timeoutInMinutes = 60
    logsConfig = @{
        cloudWatchLogs = @{
            status = "ENABLED"
            groupName = "/aws/codebuild/$ProjectName"
            streamName = "build-logs"
        }
    }
    webhook = @{
        filterGroups = @(
            @(
                @{
                    type = "EVENT"
                    pattern = "PUSH"
                },
                @{
                    type = "HEAD_REF"
                    pattern = "^refs/heads/main$"
                }
            )
        )
    }
}

# Convert to JSON and save to file
$projectConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "codebuild-project-github.json" -Encoding UTF8

Write-Host "Project configuration saved to codebuild-project-github.json" -ForegroundColor Green

# Step 2: Create the CodeBuild project using AWS CLI
Write-Host "Creating CodeBuild project using AWS CLI..." -ForegroundColor Yellow

try {
    aws codebuild create-project --cli-input-json file://codebuild-project-github.json --region us-east-1
    Write-Host "CodeBuild project created successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error creating CodeBuild project: $_" -ForegroundColor Red
    Write-Host "You may need to update the project if it already exists." -ForegroundColor Yellow
}

# Step 3: Create webhook
Write-Host "Creating GitHub webhook..." -ForegroundColor Yellow

try {
    $webhookResult = aws codebuild create-webhook --project-name $ProjectName --filter-groups '[{"filters":[{"type":"EVENT","pattern":"PUSH"},{"type":"HEAD_REF","pattern":"^refs/heads/main$"}]}]' --region us-east-1
    Write-Host "GitHub webhook created successfully!" -ForegroundColor Green
    Write-Host "Webhook URL: $($webhookResult.webhook.url)" -ForegroundColor Cyan
} catch {
    Write-Host "Error creating webhook: $_" -ForegroundColor Red
}

# Step 4: Verify CloudWatch logging
Write-Host "Verifying CloudWatch log group..." -ForegroundColor Yellow

try {
    aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild/$ProjectName" --region us-east-1
    Write-Host "CloudWatch log group verified!" -ForegroundColor Green
} catch {
    Write-Host "CloudWatch log group will be created automatically on first build." -ForegroundColor Yellow
}

Write-Host "`nSetup completed! Next steps:" -ForegroundColor Green
Write-Host "1. Add the webhook URL to your GitHub repository settings" -ForegroundColor White
Write-Host "2. Make a test commit to the main branch" -ForegroundColor White
Write-Host "3. Check the CodeBuild console to verify the build was triggered by 'GitHub-Hookshot'" -ForegroundColor White
Write-Host "4. Monitor build logs in CloudWatch Logs under /aws/codebuild/$ProjectName" -ForegroundColor White
