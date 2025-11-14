# OpenSplitTime Environment Check Script for Windows
# Run with: .\check_environment.ps1

Write-Host "======================================"
Write-Host "OpenSplitTime Environment Check (Windows)"
Write-Host "======================================"
Write-Host ""

$ErrorCount = 0

function Test-CommandExists {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Write-Success {
    param($Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Failure {
    param($Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    $script:ErrorCount++
}

function Write-Info {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

Write-Host "Checking System Dependencies..."
Write-Host "================================"
Write-Host ""

# Check Ruby
Write-Host -NoNewline "Ruby: "
if (Test-CommandExists ruby) {
    $rubyVersion = ruby -v
    if ($rubyVersion -match "3\.4") {
        Write-Success "Ruby $($rubyVersion.Split()[1]) installed"
    } else {
        Write-Failure "Ruby $($rubyVersion.Split()[1]) installed (expected 3.4.x)"
    }
} else {
    Write-Failure "Ruby not found"
}

# Check Rails
Write-Host -NoNewline "Rails: "
if (Test-CommandExists rails) {
    $railsVersion = rails -v
    if ($railsVersion -match "7\.2") {
        Write-Success "$railsVersion installed"
    } else {
        Write-Failure "$railsVersion installed (expected 7.2.x)"
    }
} else {
    Write-Failure "Rails not found"
}

# Check Bundler
Write-Host -NoNewline "Bundler: "
if (Test-CommandExists bundle) {
    $bundlerVersion = bundle -v
    Write-Success "$bundlerVersion"
} else {
    Write-Failure "Bundler not found"
}

# Check Node.js
Write-Host -NoNewline "Node.js: "
if (Test-CommandExists node) {
    $nodeVersion = node -v
    if ($nodeVersion -match "v16|v18|v20") {
        Write-Success "Node.js $nodeVersion installed"
    } else {
        Write-Failure "Node.js $nodeVersion installed (expected v16.x)"
    }
} else {
    Write-Failure "Node.js not found"
}

# Check Yarn
Write-Host -NoNewline "Yarn: "
if (Test-CommandExists yarn) {
    $yarnVersion = yarn -v
    Write-Success "Yarn $yarnVersion installed"
} else {
    Write-Failure "Yarn not found"
}

# Check PostgreSQL
Write-Host -NoNewline "PostgreSQL: "
if (Test-CommandExists psql) {
    $pgVersion = (psql --version).Split()[2]
    Write-Success "PostgreSQL $pgVersion installed"
} else {
    Write-Failure "PostgreSQL not found"
}

# Check PostgreSQL Service
Write-Host -NoNewline "PostgreSQL Service: "
$pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
if ($pgService -and $pgService.Status -eq "Running") {
    Write-Success "Running"
} else {
    Write-Failure "Not running"
}

# Check Redis
Write-Host -NoNewline "Redis: "
if (Test-CommandExists redis-cli) {
    Write-Success "Redis CLI installed"
} else {
    Write-Failure "Redis CLI not found"
}

# Check Redis Connection
Write-Host -NoNewline "Redis Service: "
try {
    $redisPing = redis-cli ping 2>$null
    if ($redisPing -eq "PONG") {
        Write-Success "Running"
    } else {
        Write-Failure "Not responding"
    }
} catch {
    Write-Failure "Cannot connect"
}

# Check Chrome
Write-Host -NoNewline "Google Chrome: "
if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") {
    Write-Success "Installed"
} else {
    Write-Failure "Chrome not found"
}

# Check ChromeDriver
Write-Host -NoNewline "ChromeDriver: "
if (Test-CommandExists chromedriver) {
    $chromedriverVersion = (chromedriver --version).Split()[1]
    Write-Success "ChromeDriver $chromedriverVersion installed"
} else {
    Write-Failure "ChromeDriver not found"
}

# Check Git
Write-Host -NoNewline "Git: "
if (Test-CommandExists git) {
    $gitVersion = git --version
    Write-Success "$gitVersion"
} else {
    Write-Failure "Git not found"
}

Write-Host ""
Write-Host "Checking Rails Application..."
Write-Host "============================="
Write-Host ""

# Check if in OpenSplitTime directory
if (-not (Test-Path "Gemfile")) {
    Write-Failure "Not in OpenSplitTime directory (Gemfile not found)"
    Write-Host ""
    Write-Host "Please run this script from the OpenSplitTime root directory"
    exit 1
}

# Check bundle install
Write-Host -NoNewline "Bundle Install: "
try {
    bundle check | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "All gems installed"
    } else {
        Write-Failure "Missing gems - run 'bundle install'"
    }
} catch {
    Write-Failure "Bundle check failed"
}

# Check yarn install
Write-Host -NoNewline "Yarn Install: "
if (Test-Path "node_modules") {
    Write-Success "Node modules installed"
} else {
    Write-Failure "Node modules not installed - run 'yarn install'"
}

# Check database
Write-Host -NoNewline "Database: "
try {
    $dbVersion = bundle exec rails db:version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database exists"
    } else {
        Write-Failure "Database not setup - run 'rails db:setup'"
    }
} catch {
    Write-Failure "Cannot check database"
}

Write-Host ""
Write-Host "======================================"

if ($ErrorCount -eq 0) {
    Write-Host ""
    Write-Host "All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You're ready to:"
    Write-Host "  1. Start the server: foreman start -f Procfile.dev"
    Write-Host "  2. Run tests: bundle exec rspec"
    Write-Host "  3. Access the app: http://localhost:3000"
    Write-Host ""
    Write-Host "Default login credentials:"
    Write-Host "  Email: user@example.com"
    Write-Host "  Password: password"
} else {
    Write-Host ""
    Write-Host "Some checks failed! ($ErrorCount errors)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please review the errors above and:"
    Write-Host "  1. Install missing dependencies"
    Write-Host "  2. Start required services"
    Write-Host "  3. Run setup commands as needed"
    Write-Host ""
    Write-Host "Refer to the Windows Setup Guide for detailed instructions."
}

Write-Host "======================================"