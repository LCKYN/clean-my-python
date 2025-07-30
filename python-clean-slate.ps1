# Windows Python Clean Slate Script
# Save as: python-clean-slate.ps1
# Run with: PowerShell -ExecutionPolicy Bypass -File python-clean-slate.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$Command = "help"
)

function Show-Help {
    Write-Host "🧹 Windows Python Clean Slate" -ForegroundColor Cyan
    Write-Host "⚠️  WARNING: This will remove ALL Python installations and packages" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage: .\python-clean-slate.ps1 [COMMAND]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Green
    Write-Host "  analyze            Show what will be removed (safe)" -ForegroundColor White
    Write-Host "  backup             Backup current environments to files" -ForegroundColor White
    Write-Host "  clean-all          ⚠️ Remove everything and start fresh" -ForegroundColor White
    Write-Host "  clean-system       Remove system Python installations" -ForegroundColor White
    Write-Host "  clean-pyenv        Remove pyenv-win Python versions" -ForegroundColor White
    Write-Host "  clean-packages     Remove global pip packages and caches" -ForegroundColor White
    Write-Host "  setup-modern       Install modern Python stack (pyenv-win + uv)" -ForegroundColor White
    Write-Host "  full-reset         ⚠️ Complete nuclear option: remove everything + setup modern" -ForegroundColor White
    Write-Host ""
    Write-Host "Recommended workflow:" -ForegroundColor Yellow
    Write-Host "  1. .\python-clean-slate.ps1 analyze       # See what you have"
    Write-Host "  2. .\python-clean-slate.ps1 backup        # Backup important environments"
    Write-Host "  3. .\python-clean-slate.ps1 full-reset    # Clean slate + modern setup"
}

function Analyze-CurrentSetup {
    Write-Host "🔍 Analyzing current Python setup..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "📍 Python executables found:" -ForegroundColor Green

    # Check common Python locations
    $pythonPaths = @(
        "python", "python3", "py",
        "C:\Python*\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python*\python.exe",
        "$env:APPDATA\Python\Python*\python.exe"
    )

    foreach ($path in $pythonPaths) {
        try {
            if ($path -like "*\*") {
                # Handle wildcard paths
                $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                foreach ($pythonExe in $found) {
                    $version = & $pythonExe --version 2>$null
                    Write-Host "  ✓ $($pythonExe.FullName): $version" -ForegroundColor White
                }
            } else {
                # Handle command names
                $location = Get-Command $path -ErrorAction SilentlyContinue
                if ($location) {
                    $version = & $path --version 2>$null
                    Write-Host "  ✓ $path: $version ($($location.Source))" -ForegroundColor White
                }
            }
        } catch {
            # Silently continue if command fails
        }
    }

    Write-Host ""
    Write-Host "🏠 Python installation locations:" -ForegroundColor Green

    # Check Windows Store Python
    $storePython = "$env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe"
    if (Test-Path $storePython) {
        Write-Host "  Windows Store Python: $storePython" -ForegroundColor White
    }

    # Check system installations
    $systemPaths = @(
        "C:\Python*",
        "$env:LOCALAPPDATA\Programs\Python\Python*",
        "$env:APPDATA\Python\Python*"
    )

    foreach ($sysPath in $systemPaths) {
        $found = Get-ChildItem -Path $sysPath -Directory -ErrorAction SilentlyContinue
        foreach ($pythonDir in $found) {
            $size = (Get-ChildItem -Recurse $pythonDir.FullName -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
            $sizeMB = [math]::Round($size / 1MB, 1)
            Write-Host "  $($pythonDir.FullName): ${sizeMB}MB" -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "🐍 Pyenv-win installations:" -ForegroundColor Green

    $pyenvPath = "$env:USERPROFILE\.pyenv"
    if (Test-Path $pyenvPath) {
        Write-Host "  Pyenv location: $pyenvPath" -ForegroundColor White

        $versionsPath = "$pyenvPath\pyenv-win\versions"
        if (Test-Path $versionsPath) {
            Write-Host "  Python versions:" -ForegroundColor White
            Get-ChildItem $versionsPath -Directory | ForEach-Object {
                $size = (Get-ChildItem -Recurse $_.FullName -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
                $sizeMB = [math]::Round($size / 1MB, 1)
                Write-Host "    $($_.Name): ${sizeMB}MB" -ForegroundColor Gray
            }
        }

        $totalSize = (Get-ChildItem -Recurse $pyenvPath -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
        $totalSizeMB = [math]::Round($totalSize / 1MB, 1)
        Write-Host "  Total disk usage: ${totalSizeMB}MB" -ForegroundColor White
    } else {
        Write-Host "  pyenv-win not installed" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "📦 Virtual environments:" -ForegroundColor Green

    # Check common venv locations
    $venvPaths = @(
        "$env:USERPROFILE\.venvs",
        "$env:USERPROFILE\venv",
        "$env:USERPROFILE\envs",
        "$env:USERPROFILE\.virtualenvs"
    )

    foreach ($venvPath in $venvPaths) {
        if (Test-Path $venvPath) {
            $size = (Get-ChildItem -Recurse $venvPath -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
            $sizeMB = [math]::Round($size / 1MB, 1)
            $count = (Get-ChildItem $venvPath -Directory -ErrorAction SilentlyContinue).Count
            Write-Host "  $venvPath: ${sizeMB}MB ($count environments)" -ForegroundColor White
        }
    }

    # Find local .venv directories in current path
    Write-Host "  Local .venv directories:" -ForegroundColor White
    Get-ChildItem -Recurse -Directory -Name ".venv" -ErrorAction SilentlyContinue | ForEach-Object {
        $venvPath = Join-Path (Get-Location) $_
        $projectPath = Split-Path (Split-Path $venvPath -Parent) -Leaf
        try {
            $size = (Get-ChildItem -Recurse $venvPath -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
            $sizeMB = [math]::Round($size / 1MB, 1)
            Write-Host "    $projectPath: ${sizeMB}MB" -ForegroundColor Gray
        } catch {
            Write-Host "    $projectPath: unknown size" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "🔧 Package managers:" -ForegroundColor Green

    # Check for package managers
    $managers = @("pip", "uv", "conda", "pipenv", "poetry")
    foreach ($manager in $managers) {
        try {
            $version = & $manager --version 2>$null
            Write-Host "  $manager`: $version" -ForegroundColor White
        } catch {
            Write-Host "  $manager`: not found" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "💾 Cache locations:" -ForegroundColor Green

    $cachePaths = @(
        "$env:APPDATA\pip",
        "$env:LOCALAPPDATA\pip",
        "$env:USERPROFILE\.cache\uv",
        "$env:USERPROFILE\.cache\pip"
    )

    $totalCacheSize = 0
    foreach ($cachePath in $cachePaths) {
        if (Test-Path $cachePath) {
            $size = (Get-ChildItem -Recurse $cachePath -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
            $sizeMB = [math]::Round($size / 1MB, 1)
            Write-Host "  $(Split-Path $cachePath -Leaf): ${sizeMB}MB" -ForegroundColor White
            $totalCacheSize += $size
        }
    }

    Write-Host "  Total cache: $([math]::Round($totalCacheSize / 1MB, 1))MB" -ForegroundColor White

    Write-Host ""
    Write-Host "⚠️  Items that will be removed with 'clean-all':" -ForegroundColor Red
    Write-Host "  - All pyenv-win Python versions" -ForegroundColor White
    Write-Host "  - All virtual environments (.venv, .venvs, etc.)" -ForegroundColor White
    Write-Host "  - All pip caches" -ForegroundColor White
    Write-Host "  - System Python installations (C:\Python*, LocalAppData)" -ForegroundColor White
    Write-Host "  - Global pip packages" -ForegroundColor White
    Write-Host "  - Python-related configs" -ForegroundColor White
    Write-Host "  - Note: Windows Store Python will remain (uninstall manually if needed)" -ForegroundColor Yellow
}

function Backup-Environments {
    Write-Host "💾 Backing up current environments..." -ForegroundColor Cyan

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = "$env:USERPROFILE\python-backup-$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    Write-Host "📁 Backup directory: $backupDir" -ForegroundColor Green
    Write-Host ""

    # Backup global pip packages
    try {
        Write-Host "📦 Backing up global pip packages..." -ForegroundColor Yellow
        $globalPackages = & pip freeze 2>$null
        if ($globalPackages) {
            $globalPackages | Out-File -FilePath "$backupDir\global-pip-packages.txt" -Encoding UTF8
            Write-Host "  Saved to: global-pip-packages.txt" -ForegroundColor White
        } else {
            "# No global packages found" | Out-File -FilePath "$backupDir\global-pip-packages.txt" -Encoding UTF8
        }
    } catch {
        "# Failed to backup global packages" | Out-File -FilePath "$backupDir\global-pip-packages.txt" -Encoding UTF8
    }

    # Backup pyenv-win versions
    $pyenvPath = "$env:USERPROFILE\.pyenv\pyenv-win\versions"
    if (Test-Path $pyenvPath) {
        Write-Host "🐍 Backing up pyenv-win version list..." -ForegroundColor Yellow
        $versions = Get-ChildItem $pyenvPath -Directory | ForEach-Object { $_.Name }
        $versions | Out-File -FilePath "$backupDir\pyenv-versions.txt" -Encoding UTF8
        Write-Host "  Saved to: pyenv-versions.txt" -ForegroundColor White
    }

    # Backup virtual environments
    Write-Host "🏠 Backing up virtual environment packages..." -ForegroundColor Yellow
    $venvCount = 0

    $venvPaths = @(
        "$env:USERPROFILE\.venvs",
        "$env:USERPROFILE\venv",
        "$env:USERPROFILE\envs",
        "$env:USERPROFILE\.virtualenvs"
    )

    foreach ($venvDir in $venvPaths) {
        if (Test-Path $venvDir) {
            Get-ChildItem $venvDir -Directory | ForEach-Object {
                $envName = $_.Name
                $activateScript = Join-Path $_.FullName "Scripts\activate.bat"

                if (Test-Path $activateScript) {
                    Write-Host "  Backing up: $envName" -ForegroundColor Gray

                    try {
                        # Activate and get packages
                        $pipPath = Join-Path $_.FullName "Scripts\pip.exe"
                        if (Test-Path $pipPath) {
                            $packages = & $pipPath freeze 2>$null
                            if ($packages) {
                                $packages | Out-File -FilePath "$backupDir\venv-$envName-packages.txt" -Encoding UTF8
                            } else {
                                "# No packages found" | Out-File -FilePath "$backupDir\venv-$envName-packages.txt" -Encoding UTF8
                            }
                            $venvCount++
                        }
                    } catch {
                        "# Failed to backup $envName" | Out-File -FilePath "$backupDir\venv-$envName-packages.txt" -Encoding UTF8
                    }
                }
            }
        }
    }

    # Create restore guide
    $restoreGuide = @"
# Windows Python Environment Restore Guide

This backup was created before cleaning your Python installation.

## Files in this backup:

- ``global-pip-packages.txt`` - Global pip packages
- ``pyenv-versions.txt`` - Pyenv Python versions that were installed
- ``venv-*-packages.txt`` - Packages from each virtual environment

## To restore after setting up modern Python stack:

### 1. Reinstall Python versions with pyenv-win:
``````powershell
# Read the versions file and install each version
Get-Content pyenv-versions.txt | ForEach-Object {
    pyenv install `$_
}
``````

### 2. Recreate environments with uv:
``````powershell
# For each venv backup file, create new environment
# Example for a data science environment:
uv venv `$env:USERPROFILE\.venvs\data-science
& "`$env:USERPROFILE\.venvs\data-science\Scripts\activate.bat"
uv pip install -r venv-data-science-packages.txt
``````

### 3. Modern approach (recommended):
Instead of recreating old environments exactly, consider:
- Creating shared base environments by purpose (web-dev, data-science, etc.)
- Using environment templates
- Using ``uv`` for automatic dependency management

## Example modern recreation:
``````powershell
# Instead of exact restore, create purpose-based environments
uv venv `$env:USERPROFILE\.venvs\data-science
& "`$env:USERPROFILE\.venvs\data-science\Scripts\activate.bat"
uv pip install pandas numpy matplotlib scikit-learn jupyter

# Then use across multiple projects
``````
"@

    $restoreGuide | Out-File -FilePath "$backupDir\restore-guide.md" -Encoding UTF8

    Write-Host ""
    Write-Host "✅ Backup completed!" -ForegroundColor Green
    Write-Host "📁 Location: $backupDir" -ForegroundColor White
    Write-Host "📋 Backed up $venvCount virtual environments" -ForegroundColor White
    Write-Host "📖 See restore-guide.md for restoration instructions" -ForegroundColor White
}

function Clean-SystemPython {
    Write-Host "🧹 Cleaning system Python installations..." -ForegroundColor Cyan
    Write-Host ""

    # Remove system Python installations
    $systemPaths = @(
        "C:\Python*",
        "$env:LOCALAPPDATA\Programs\Python\Python*",
        "$env:APPDATA\Python\Python*"
    )

    foreach ($sysPath in $systemPaths) {
        $found = Get-ChildItem -Path $sysPath -Directory -ErrorAction SilentlyContinue
        foreach ($pythonDir in $found) {
            Write-Host "🗑️  Removing $($pythonDir.FullName)..." -ForegroundColor Yellow
            try {
                Remove-Item -Recurse -Force $pythonDir.FullName -ErrorAction Stop
                Write-Host "  ✅ Removed successfully" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # Clean PATH environment variable
    Write-Host "🧹 Cleaning PATH environment variable..." -ForegroundColor Yellow

    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pathEntries = $currentPath -split ";"
    $cleanedEntries = $pathEntries | Where-Object {
        $_ -notlike "*Python*" -and
        $_ -notlike "*pip*" -and
        $_ -ne ""
    }
    $newPath = $cleanedEntries -join ";"

    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "  ✅ PATH cleaned" -ForegroundColor Green

    Write-Host ""
    Write-Host "ℹ️  Note: Windows Store Python (if installed) remains." -ForegroundColor Blue
    Write-Host "   Uninstall manually from Settings > Apps if needed." -ForegroundColor Blue

    Write-Host "✅ System Python cleanup completed" -ForegroundColor Green
}

function Clean-PyenvWin {
    Write-Host "🐍 Cleaning pyenv-win installations..." -ForegroundColor Cyan

    $pyenvPath = "$env:USERPROFILE\.pyenv"

    if (-not (Test-Path $pyenvPath)) {
        Write-Host "✅ pyenv-win not installed, nothing to clean" -ForegroundColor Green
        return
    }

    Write-Host "📋 Current pyenv-win versions:" -ForegroundColor Yellow
    $versionsPath = "$pyenvPath\pyenv-win\versions"
    if (Test-Path $versionsPath) {
        Get-ChildItem $versionsPath -Directory | ForEach-Object {
            Write-Host "  $($_.Name)" -ForegroundColor White
        }
    }
    Write-Host ""

    $confirmation = Read-Host "❓ Remove ALL pyenv-win Python versions? (y/N)"

    if ($confirmation -eq "y" -or $confirmation -eq "Y") {
        Write-Host "🗑️  Removing all pyenv-win Python versions..." -ForegroundColor Yellow

        try {
            Remove-Item -Recurse -Force $pyenvPath -ErrorAction Stop
            Write-Host "✅ pyenv-win completely removed" -ForegroundColor Green

            # Clean environment variables
            Write-Host "🧹 Cleaning environment variables..." -ForegroundColor Yellow
            [Environment]::SetEnvironmentVariable("PYENV", $null, "User")
            [Environment]::SetEnvironmentVariable("PYENV_ROOT", $null, "User")
            [Environment]::SetEnvironmentVariable("PYENV_HOME", $null, "User")

            # Clean PATH
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            $pathEntries = $currentPath -split ";"
            $cleanedEntries = $pathEntries | Where-Object {
                $_ -notlike "*pyenv*" -and $_ -ne ""
            }
            $newPath = $cleanedEntries -join ";"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

            Write-Host "✅ Environment variables cleaned" -ForegroundColor Green

        } catch {
            Write-Host "❌ Failed to remove pyenv-win: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "⏭️  Skipped pyenv-win removal" -ForegroundColor Yellow
    }
}

function Clean-VirtualEnvironments {
    Write-Host "🏠 Cleaning virtual environments..." -ForegroundColor Cyan
    Write-Host ""

    # Remove common venv directories
    $venvPaths = @(
        "$env:USERPROFILE\.venvs",
        "$env:USERPROFILE\venv",
        "$env:USERPROFILE\envs",
        "$env:USERPROFILE\.virtualenvs"
    )

    foreach ($venvDir in $venvPaths) {
        if (Test-Path $venvDir) {
            try {
                $size = (Get-ChildItem -Recurse $venvDir -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
                $sizeMB = [math]::Round($size / 1MB, 1)
                Write-Host "🗑️  Removing $venvDir (${sizeMB}MB)..." -ForegroundColor Yellow
                Remove-Item -Recurse -Force $venvDir -ErrorAction Stop
                Write-Host "  ✅ Removed successfully" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # Find and remove local .venv directories
    Write-Host "🔍 Finding local .venv directories..." -ForegroundColor Yellow
    Get-ChildItem -Recurse -Directory -Name ".venv" -ErrorAction SilentlyContinue | ForEach-Object {
        $venvPath = Join-Path (Get-Location) $_
        $projectPath = Split-Path (Split-Path $venvPath -Parent) -Leaf

        try {
            $size = (Get-ChildItem -Recurse $venvPath -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
            $sizeMB = [math]::Round($size / 1MB, 1)
            Write-Host "🗑️  Removing .venv in $projectPath (${sizeMB}MB)..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $venvPath -ErrorAction Stop
            Write-Host "  ✅ Removed successfully" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "✅ Virtual environments cleaned" -ForegroundColor Green
}

function Clean-CachesAndConfigs {
    Write-Host "🧹 Cleaning Python caches and configs..." -ForegroundColor Cyan

    $cachePaths = @(
        "$env:APPDATA\pip",
        "$env:LOCALAPPDATA\pip",
        "$env:USERPROFILE\.cache\pip",
        "$env:USERPROFILE\.cache\uv",
        "$env:APPDATA\uv",
        "$env:LOCALAPPDATA\uv"
    )

    foreach ($cachePath in $cachePaths) {
        if (Test-Path $cachePath) {
            try {
                $size = (Get-ChildItem -Recurse $cachePath -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
                $sizeMB = [math]::Round($size / 1MB, 1)
                Write-Host "🗑️  Removing $(Split-Path $cachePath -Leaf) cache (${sizeMB}MB)..." -ForegroundColor Yellow
                Remove-Item -Recurse -Force $cachePath -ErrorAction Stop
                Write-Host "  ✅ Removed successfully" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # Remove other Python-related caches
    $otherCaches = @(
        "$env:USERPROFILE\.mypy_cache",
        "$env:USERPROFILE\.pytest_cache"
    )

    foreach ($cache in $otherCaches) {
        if (Test-Path $cache) {
            try {
                Write-Host "🗑️  Removing $(Split-Path $cache -Leaf)..." -ForegroundColor Yellow
                Remove-Item -Recurse -Force $cache -ErrorAction Stop
                Write-Host "  ✅ Removed successfully" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Write-Host "✅ Caches and configs cleaned" -ForegroundColor Green
}

function Setup-ModernPythonStack {
    Write-Host "🚀 Setting up modern Python stack..." -ForegroundColor Cyan
    Write-Host ""

    # Install pyenv-win
    Write-Host "📥 Installing pyenv-win..." -ForegroundColor Yellow

    if (Test-Path "$env:USERPROFILE\.pyenv") {
        Write-Host "  pyenv-win already installed" -ForegroundColor Green
    } else {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"
            .\install-pyenv-win.ps1
            Remove-Item "./install-pyenv-win.ps1" -Force
            Write-Host "  ✅ pyenv-win installed" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Failed to install pyenv-win: $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }

    # Install uv
    Write-Host "📥 Installing uv..." -ForegroundColor Yellow

    try {
        $uvCommand = Get-Command uv -ErrorAction SilentlyContinue
        if ($uvCommand) {
            Write-Host "  uv already installed" -ForegroundColor Green
        } else {
            Invoke-WebRequest -UseBasicParsing -Uri "https://astral.sh/uv/install.ps1" -O install-uv.ps1
            .\install-uv.ps1
            Remove-Item "./install-uv.ps1" -Force
            Write-Host "  ✅ uv installed" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ❌ Failed to install uv: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Refresh environment variables
    $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [Environment]::GetEnvironmentVariable("PATH", "Machine")

    # Install Python 3.11
    Write-Host "🐍 Installing Python 3.11..." -ForegroundColor Yellow

    try {
        & "$env:USERPROFILE\.pyenv\pyenv-win\bin\pyenv.bat" install 3.11.7
        & "$env:USERPROFILE\.pyenv\pyenv-win\bin\pyenv.bat" global 3.11.7
        Write-Host "  ✅ Python 3.11.7 installed and set as global" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Failed to install Python 3.11: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Setup environment variables
    Write-Host "⚙️  Configuring environment variables..." -ForegroundColor Yellow

    [Environment]::SetEnvironmentVariable("PYENV", "$env:USERPROFILE\.pyenv\pyenv-win", "User")
    [Environment]::SetEnvironmentVariable("PYENV_ROOT", "$env:USERPROFILE\.pyenv", "User")
    [Environment]::SetEnvironmentVariable("PYENV_HOME", "$env:USERPROFILE\.pyenv\pyenv-win", "User")

    # Update PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pyenvPaths = @(
        "$env:USERPROFILE\.pyenv\pyenv-win\bin",
        "$env:USERPROFILE\.pyenv\pyenv-win\shims",
        "$env:USERPROFILE\.cargo\bin"
    )

    foreach ($pyenvPath in $pyenvPaths) {
        if ($currentPath -notlike "*$pyenvPath*") {
            $currentPath = "$pyenvPath;$currentPath"
        }
    }

    [Environment]::SetEnvironmentVariable("PATH", $currentPath, "User")
    Write-Host "  ✅ Environment variables configured" -ForegroundColor Green

    # Create shared environments directory
    Write-Host "📁 Creating shared environments directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.venvs" -Force | Out-Null
    Write-Host "  ✅ Created ~/.venvs directory" -ForegroundColor Green

    Write-Host ""
    Write-Host "🎉 Modern Python stack setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔄 Please restart your PowerShell/Command Prompt" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🎯 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Restart terminal" -ForegroundColor White
    Write-Host "2. Verify setup: python --version (should show 3.11.7)" -ForegroundColor White
    Write-Host "3. Verify uv: uv --version" -ForegroundColor White
    Write-Host "4. Create your first modern environment: uv venv `$env:USERPROFILE\.venvs\general" -ForegroundColor White
}

function Clean-All {
    Write-Host "💥 NUCLEAR OPTION: Complete Python cleanup" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  This will remove:" -ForegroundColor Red
    Write-Host "  - ALL Python versions (except Windows Store Python)" -ForegroundColor White
    Write-Host "  - ALL virtual environments" -ForegroundColor White
    Write-Host "  - ALL pip packages and caches" -ForegroundColor White
    Write-Host "  - pyenv-win installation" -ForegroundColor White
    Write-Host "  - System Python installations" -ForegroundColor White
    Write-Host "  - Python-related configs" -ForegroundColor White
    Write-Host ""

    $confirmation = Read-Host "❓ Are you absolutely sure? Type 'yes' to proceed"

    if ($confirmation -eq "yes") {
        Write-Host "🚀 Starting complete cleanup..." -ForegroundColor Cyan
        Write-Host ""

        Clean-VirtualEnvironments
        Write-Host ""
        Clean-PyenvWin
        Write-Host ""
        Clean-SystemPython
        Write-Host ""
        Clean-CachesAndConfigs
        Write-Host ""

        Write-Host "✅ Complete cleanup finished!" -ForegroundColor Green
        Write-Host "🧹 Your system is now clean of Python installations" -ForegroundColor White
    } else {
        Write-Host "❌ Cleanup cancelled" -ForegroundColor Red
    }
}

function Full-Reset {
    Write-Host "🔄 FULL RESET: Clean everything + setup modern stack" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "1. Remove all existing Python installations" -ForegroundColor White
    Write-Host "2. Set up modern Python stack (pyenv-win + uv + Python 3.11)" -ForegroundColor White
    Write-Host ""

    $confirmation = Read-Host "❓ Proceed with full reset? Type 'yes'"

    if ($confirmation -eq "yes") {
        Write-Host "🚀 Starting full reset..." -ForegroundColor Cyan
        Write-Host ""

        # Clean everything
        Clean-VirtualEnvironments
        Write-Host ""
        Clean-PyenvWin
        Write-Host ""
        Clean-SystemPython
        Write-Host ""
        Clean-CachesAndConfigs
        Write-Host ""

        # Setup modern stack
        Setup-ModernPythonStack
        Write-Host ""

        Write-Host "🎉 Full reset complete!" -ForegroundColor Green
        Write-Host "🐍 You now have a clean, modern Python setup" -ForegroundColor White
        Write-Host ""
        Write-Host "🎯 Ready for:" -ForegroundColor Cyan
        Write-Host "  - pyenv-win for Python version management" -ForegroundColor White
        Write-Host "  - uv for fast package management" -ForegroundColor White
        Write-Host "  - Python 3.11 as your default" -ForegroundColor White
        Write-Host "  - Clean slate for creating new environments" -ForegroundColor White

    } else {
        Write-Host "❌ Full reset cancelled" -ForegroundColor Red
    }
}

# Main script logic
switch ($Command.ToLower()) {
    "analyze" {
        Analyze-CurrentSetup
    }
    "backup" {
        Backup-Environments
    }
    "clean-all" {
        Clean-All
    }
    "clean-system" {
        Clean-SystemPython
    }
    "clean-pyenv" {
        Clean-PyenvWin
    }
    "clean-packages" {
        Clean-CachesAndConfigs
    }
    "setup-modern" {
        Setup-ModernPythonStack
    }
    "full-reset" {
        Full-Reset
    }
    default {
        Show-Help
    }
}
