# OpenSplitTime Windows Setup Guide (PowerShell)

## Overview
OpenSplitTime is a Ruby on Rails application for tracking endurance event data. This guide provides complete setup instructions for Windows using PowerShell.

## Prerequisites

### System Requirements
- **PowerShell**: Version 5.1 or higher (Windows PowerShell or PowerShell Core)
- **Administrator Access**: Required for some installations
- **Ruby**: 3.4.0
- **Rails**: 7.2
- **Node.js**: v16
- **PostgreSQL**: Latest stable version
- **Redis**: Latest stable version
- **Git**: Latest version
- **Chrome Browser**: Required for integration tests

---

## Step-by-Step Setup Instructions

### Step 1: Enable PowerShell Script Execution

Open PowerShell as Administrator and run:

```powershell
# For all users
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

### Step 2: Install Chocolatey (Package Manager)

Chocolatey is a package manager for Windows that simplifies software installation.

```powershell
# Run PowerShell as Administrator

# Install Chocolatey
Download from https://chocolatey.org/install

# Verify installation
choco --version

# Refresh environment variables
refreshenv
```
---

### Step 3: Install Git
---

Manual installation: https://git-scm.com/download/win

---

### Step 4: Install Ruby with RubyInstaller

Windows doesn't have rbenv, so we use RubyInstaller.

```powershell
# Install via Chocolatey
choco install ruby --version=3.4.0 -y

```

**Manual Installation Steps:**
1. Download Ruby 3.4.0 with Devkit from https://rubyinstaller.org/downloads/
2. Run the installer
3. Check "Add Ruby executables to your PATH"
4. Check "Associate .rb and .rbw files with this Ruby installation"
5. Run `ridk install` when prompted (install MSYS2 and development toolchain)
6. Select option 3 (MSYS2 and MINGW development toolchain)

**After Installation:**

```powershell
# Refresh environment
refreshenv

# Verify Ruby installation
ruby --version

# Verify gem
gem --version

# Update RubyGems
gem update --system

# Install Bundler
gem install bundler

# Verify Bundler
bundle --version
```

---

### Step 5: Install Node.js and Yarn

### Step 6: Install PostgreSQL


**After Installation:**

```powershell
# Refresh environment
refreshenv

# Verify PostgreSQL installation
psql --version

# Test connection (password is what you set during installation)
psql -U postgres -h localhost

# Inside psql, create your user:
# CREATE USER your_windows_username WITH SUPERUSER PASSWORD 'your_password';
# \q to exit

# Or create user via command line
psql -U postgres -c "CREATE USER $env:USERNAME WITH SUPERUSER PASSWORD 'password123';"
```

**Start PostgreSQL Service:**

```powershell
# Check service status
Get-Service -Name postgresql*

# Start service
Start-Service -Name postgresql-x64-16  # Adjust name based on your version

# Set to start automatically
Set-Service -Name postgresql-x64-16 -StartupType Automatic
```

---

### Step 7: Install Redis

Redis doesn't have official Windows support, but we can use alternatives.

**Docker Desktop (RECOMMENDED)**

```powershell
# If you have Docker Desktop installed
docker run -d -p 6379:6379 --name redis redis:latest

# Verify
docker ps
```

**Verify Redis:**

```powershell
# Test connection
redis-cli ping
(OR)
docker exec -it redis redis-cli ping
# Should return: PONG
```

---

### Step 8: Install Chrome and ChromeDriver

**Install Google Chrome:**

```powershell
# Install Chrome
choco install googlechrome -y

# Verify
Get-Command chrome
```

Manual installation: https://www.google.com/chrome/

**Install ChromeDriver:**

```powershell
# Install ChromeDriver
choco install chromedriver -y

# Refresh environment
refreshenv

# Verify
chromedriver --version

# Check Chrome version to ensure compatibility
# Open Chrome and go to: chrome://settings/help
```


Manual installation: https://chromedriver.chromium.org/downloads

---

### Step 9: Clone the OpenSplitTime Repository

```powershell

# Clone the repository
git clone https://github.com/SplitTime/OpenSplitTime.git

# Navigate into the directory
Set-Location OpenSplitTime

```

---

### Step 10: Install Ruby Dependencies

```powershell
# Make sure you're in the OpenSplitTime directory

# Install Bundler if not already installed
gem install bundler

# Install all Ruby gems
bundle install

# If you encounter errors, try:
bundle install --retry 3

# Verify bundle is working
bundle check
```
---


### Step 11: Configure Database Connection

Create a `.env` file for local configuration (optional but recommended):

```powershell
# Create .env file
New-Item -Path ".env" -ItemType File -Force

# Add database configuration
@"
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_postgres_password
DATABASE_HOST=localhost
DATABASE_PORT=5432
"@ | Out-File -FilePath ".env" -Encoding UTF8
```

Or update `config/database.yml`:

```powershell
# Backup original database.yml
Copy-Item config\database.yml config\database.yml.backup

# Edit database.yml (use your preferred editor)
notepad config\database.yml
```

Add to development section:
```yaml
development:
  <<: *default
  database: opensplittime_development
  username: postgres
  password: your_postgres_password
  host: localhost
  port: 5432
```

---

### Step 12: Setup Database

```powershell
# Create database
bundle exec rails db:create

# Run migrations
bundle exec rails db:migrate

# Or use db:setup (create + migrate + seed)
bundle exec rails db:setup

# Load test fixtures
bundle exec rails db:from_fixtures

# Verify database was created
bundle exec rails db:version
```

**If you encounter errors:**

```powershell
# Check PostgreSQL is running
Get-Service -Name postgresql*

# If not running, start it
Start-Service -Name postgresql-x64-16

# Test database connection
psql -U postgres -h localhost -c "SELECT version();"

# Check if database exists
psql -U postgres -h localhost -c "\l"
```

---

### Step 13: Verify Installation with Environment Check Script

Create a PowerShell environment check script:

**Run the check script:**

```powershell
# Run environment check
.\check_environment.ps1

# Or if execution policy prevents it
powershell -ExecutionPolicy Bypass -File .\check_environment.ps1
```

---

### Step 14: Start the Development Server


**Start services individually**

Open multiple PowerShell windows:

**Window 1 - Rails Server:**
```powershell
Set-Location "$HOME\projects\OpenSplitTime"
bundle exec rails server
```

**Window 2 - Sidekiq (Background Jobs):**
```powershell
Set-Location "$HOME\projects\OpenSplitTime"
bundle exec sidekiq
```

**Window 3 - Asset Compilation (if needed):**
```powershell
Set-Location "$HOME\projects\OpenSplitTime"
yarn build --watch
```

**Access the application:**
- Open browser: http://localhost:3000
- Login with test credentials:
  - Email: user@example.com
  - Password: password

---

## Running Tests

### Prepare Test Database

```powershell
# Create and setup test database
$env:RAILS_ENV = "test"
bundle exec rails db:create
bundle exec rails db:schema:load

# Or use db:test:prepare
bundle exec rails db:test:prepare
```

### Run All Tests

```powershell
# Run all tests
bundle exec rspec

# Or simply
rspec

```
---


## Troubleshooting Common Windows Issues

### Issue 1: Yarn Install Fails

**Problem:** Yarn cannot install packages

**Solution:**
```powershell
# Clear Yarn cache
yarn cache clean

# Remove node_modules
Remove-Item -Recurse -Force node_modules
Remove-Item yarn.lock

# Reinstall
yarn install

# If still failing, use increased timeout
yarn install --network-timeout 100000

# Or use npm instead
npm install
```

---

### Running Tests

```powershell
# Prepare test database
bundle exec rails db:test:prepare

# Run all tests
bundle exec rspec

# Run specific tests
rspec spec\models\effort_spec.rb

# Run with coverage
$env:COVERAGE = "true"
bundle exec rspec

# View coverage
Invoke-Item coverage\index.html
```