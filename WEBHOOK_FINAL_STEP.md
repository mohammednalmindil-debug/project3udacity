# Final Step: Enable GitHub Webhook

## Current Status ✅

Your AWS CodeBuild project `coworking-build` has been successfully created with:

- ✅ GitHub repository connected: https://github.com/mohammednalmindil-debug/project3udacity.git
- ✅ CloudWatch logging enabled: `/aws/codebuild/coworking-build`
- ✅ Environment variables configured
- ✅ Health check buildspec: `deployments/buildspec-with-health-check.yaml`

## What's Missing

The webhook requires GitHub OAuth authorization, which can only be done through the AWS Console.

## Complete the Setup (5 minutes)

### Step 1: Open AWS CodeBuild Console

1. Go to: https://console.aws.amazon.com/codesuite/codebuild/projects/coworking-build/edit/source?region=us-east-1
2. Or navigate to: AWS Console → CodeBuild → Build projects → `coworking-build` → Edit → Source

### Step 2: Connect to GitHub

1. In the **Source** section, you'll see your GitHub repository is already configured
2. Scroll down to **Primary source webhook events**
3. Check the box: **"Rebuild every time a code change is pushed to this repository"**
4. Click **"Connect to GitHub"** (this will open a popup)
5. Authorize AWS CodeBuild to access your GitHub account
6. Close the popup once authorized

### Step 3: Configure Webhook Filters

1. Under **Event type**, select: **PUSH**
2. Click **"Add filter group"**
3. Set:
   - **Filter type**: HEAD_REF
   - **Pattern**: `^refs/heads/main$`
4. This ensures only pushes to the main branch trigger builds

### Step 4: Save Changes

1. Scroll to the bottom and click **"Update source"**
2. AWS will automatically create the webhook in your GitHub repository

### Step 5: Verify Setup

Run this command to verify the webhook was created:

```powershell
aws codebuild batch-get-projects --names coworking-build --region us-east-1 --query "projects[0].webhook"
```

You should see webhook details including the URL.

## Test the Automation

### Make a Test Commit

```bash
# Make a small change
echo "# Test webhook" >> README.md

# Commit and push
git add README.md
git commit -m "Test: Trigger CodeBuild webhook"
git push origin main
```

### Verify the Build

1. Go to: https://console.aws.amazon.com/codesuite/codebuild/projects/coworking-build/history?region=us-east-1
2. You should see a new build starting
3. Check the **Initiator** column - it should show: **"GitHub-Hookshot"**
4. Click on the build to see real-time logs

### Monitor in CloudWatch

```powershell
# View recent logs
aws logs tail /aws/codebuild/coworking-build --follow --region us-east-1
```

## Troubleshooting

### Webhook Not Creating

- Make sure you clicked "Connect to GitHub" and authorized AWS
- Check that you're logged into the correct GitHub account
- Try disconnecting and reconnecting GitHub

### Build Not Triggering

- Verify webhook exists in GitHub: Settings → Webhooks
- Check webhook is active (green checkmark)
- Ensure you're pushing to the `main` branch
- Check webhook delivery history in GitHub

### Build Failing

- Check CloudWatch logs for error details
- Verify ECR permissions
- Ensure buildspec file exists at `deployments/buildspec-with-health-check.yaml`

## What Happens Next

Once the webhook is enabled:

1. **Every push to main branch** → Triggers CodeBuild automatically
2. **CodeBuild runs** → Builds Docker image, runs health check
3. **Pushes to ECR** → Image available at `767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest`
4. **Logs to CloudWatch** → Full build logs available for monitoring
5. **GitHub status** → Build status reported back to GitHub commit

## Quick Links

- **CodeBuild Project**: https://console.aws.amazon.com/codesuite/codebuild/projects/coworking-build?region=us-east-1
- **Build History**: https://console.aws.amazon.com/codesuite/codebuild/projects/coworking-build/history?region=us-east-1
- **CloudWatch Logs**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Fcodebuild$252Fcoworking-build
- **ECR Repository**: https://console.aws.amazon.com/ecr/repositories/private/767398149973/coworking-analytics?region=us-east-1
- **GitHub Repository**: https://github.com/mohammednalmindil-debug/project3udacity

---

**Estimated Time**: 5 minutes
**Difficulty**: Easy
**Required**: AWS Console access + GitHub account access
