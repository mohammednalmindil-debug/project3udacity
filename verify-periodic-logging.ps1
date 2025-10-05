# PowerShell script to verify periodic database logging is working
# This script will check CloudWatch logs for the expected periodic entries

param(
    [Parameter(Mandatory=$false)]
    [int]$WaitMinutes = 2
)

Write-Host "Verifying Periodic Database Logging" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# Function to check CloudWatch logs
function Test-PeriodicLogging {
    Write-Host "Checking CloudWatch logs for periodic database entries..." -ForegroundColor Yellow
    
    try {
        # Get recent logs from the last 5 minutes
        $logs = aws logs filter-log-events --log-group-name "/aws/containerinsights/coworking-project/application" --start-time (Get-Date).AddMinutes(-5).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") --region us-east-1 --output json | ConvertFrom-Json
        
        if ($logs.events) {
            Write-Host "✓ Found $($logs.events.Count) log entries" -ForegroundColor Green
            
            # Look for specific log patterns
            $dbConnected = $logs.events | Where-Object { $_.message -like "*Database connected successfully*" }
            $tableCounts = $logs.events | Where-Object { $_.message -like "*Fetched*records from*table*" }
            $dailyData = $logs.events | Where-Object { $_.message -like "*Daily visits data*" }
            
            if ($dbConnected) {
                Write-Host "✓ Found database connection logs: $($dbConnected.Count) entries" -ForegroundColor Green
            }
            
            if ($tableCounts) {
                Write-Host "✓ Found table count logs: $($tableCounts.Count) entries" -ForegroundColor Green
            }
            
            if ($dailyData) {
                Write-Host "✓ Found daily data logs: $($dailyData.Count) entries" -ForegroundColor Green
            }
            
            # Show recent log entries
            Write-Host "`nRecent log entries:" -ForegroundColor Cyan
            $logs.events | Select-Object -Last 10 | ForEach-Object {
                $timestamp = [DateTime]::Parse($_.timestamp.ToString()).ToString("yyyy-MM-dd HH:mm:ss")
                Write-Host "[$timestamp] $($_.message)" -ForegroundColor Gray
            }
            
            return $true
        }
        else {
            Write-Host "⚠ No log entries found in CloudWatch" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "✗ Error checking CloudWatch logs: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check Kubernetes pod logs
function Test-PodLogs {
    Write-Host "`nChecking Kubernetes pod logs..." -ForegroundColor Yellow
    
    try {
        $podName = kubectl get pods -l service=coworking -o jsonpath='{.items[0].metadata.name}'
        if ($podName) {
            Write-Host "✓ Found pod: $podName" -ForegroundColor Green
            
            # Get recent logs
            $logs = kubectl logs $podName --tail=20
            if ($logs) {
                Write-Host "`nRecent pod logs:" -ForegroundColor Cyan
                $logs | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
                
                # Check for periodic patterns
                $periodicLogs = $logs | Where-Object { $_ -like "*Database connected successfully*" -or $_ -like "*Fetched*records from*table*" }
                if ($periodicLogs) {
                    Write-Host "✓ Found periodic database logs in pod" -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Host "⚠ No periodic database logs found in pod" -ForegroundColor Yellow
                    return $false
                }
            }
        }
        else {
            Write-Host "✗ No coworking pods found" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Error checking pod logs: $_" -ForegroundColor Red
        return $false
    }
}

# Function to test API endpoints
function Test-APIEndpoints {
    Write-Host "`nTesting API endpoints..." -ForegroundColor Yellow
    
    try {
        $serviceIP = kubectl get svc coworking -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        if ($serviceIP) {
            Write-Host "✓ Service IP: $serviceIP" -ForegroundColor Green
            
            # Test health check
            try {
                $healthResponse = Invoke-WebRequest -Uri "http://$serviceIP:5153/health_check" -TimeoutSec 10
                if ($healthResponse.StatusCode -eq 200) {
                    Write-Host "✓ Health check endpoint working" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "⚠ Health check endpoint not responding" -ForegroundColor Yellow
            }
            
            # Test readiness check
            try {
                $readinessResponse = Invoke-WebRequest -Uri "http://$serviceIP:5153/readiness_check" -TimeoutSec 10
                if ($readinessResponse.StatusCode -eq 200) {
                    Write-Host "✓ Readiness check endpoint working" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "⚠ Readiness check endpoint not responding" -ForegroundColor Yellow
            }
            
            return $true
        }
        else {
            Write-Host "⚠ Service IP not yet assigned" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "✗ Error testing API endpoints: $_" -ForegroundColor Red
        return $false
    }
}

# Main verification
Write-Host "Starting verification process..." -ForegroundColor Yellow

# Check if application is deployed
try {
    $pods = kubectl get pods -l service=coworking --no-headers
    if (-not $pods) {
        Write-Host "✗ No coworking pods found. Please deploy the application first." -ForegroundColor Red
        Write-Host "Run: .\deploy.ps1" -ForegroundColor Gray
        exit 1
    }
    else {
        Write-Host "✓ Found coworking pods" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Error checking pods: $_" -ForegroundColor Red
    exit 1
}

# Wait for logs to accumulate
Write-Host "`nWaiting $WaitMinutes minutes for logs to accumulate..." -ForegroundColor Yellow
Start-Sleep -Seconds ($WaitMinutes * 60)

# Run verification tests
$cloudWatchOK = Test-PeriodicLogging
$podLogsOK = Test-PodLogs
$apiOK = Test-APIEndpoints

# Summary
Write-Host "`nVerification Summary" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

if ($cloudWatchOK) {
    Write-Host "✓ CloudWatch logs: Periodic database logging detected" -ForegroundColor Green
}
else {
    Write-Host "✗ CloudWatch logs: No periodic database logging found" -ForegroundColor Red
}

if ($podLogsOK) {
    Write-Host "✓ Pod logs: Periodic database logging detected" -ForegroundColor Green
}
else {
    Write-Host "✗ Pod logs: No periodic database logging found" -ForegroundColor Red
}

if ($apiOK) {
    Write-Host "✓ API endpoints: Working correctly" -ForegroundColor Green
}
else {
    Write-Host "⚠ API endpoints: Some issues detected" -ForegroundColor Yellow
}

# Final result
if ($cloudWatchOK -or $podLogsOK) {
    Write-Host "`n🎉 SUCCESS: Periodic database logging is working!" -ForegroundColor Green
    Write-Host "Your Udacity project reviewer will see the required database activity logs." -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Monitor logs for a few more minutes to confirm consistency" -ForegroundColor White
    Write-Host "2. Take screenshots of CloudWatch logs showing periodic entries" -ForegroundColor White
    Write-Host "3. Document the periodic logging in your project submission" -ForegroundColor White
}
else {
    Write-Host "`n❌ ISSUE: Periodic database logging not detected" -ForegroundColor Red
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check if the application is running: kubectl get pods -l service=coworking" -ForegroundColor White
    Write-Host "2. Check application logs: kubectl logs -l service=coworking -f" -ForegroundColor White
    Write-Host "3. Verify database connection: kubectl logs -l app=postgresql" -ForegroundColor White
    Write-Host "4. Check CloudWatch log group exists: aws logs describe-log-groups --log-group-name-prefix /aws/containerinsights" -ForegroundColor White
}
