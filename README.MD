# Python Version Management Cheat Sheet

## 📋 Quick Reference

### Check Current Setup
```bash
python --version                 # Current Python version
pyenv version                   # Current pyenv version + source
pyenv versions                  # All installed versions
which python                    # Python executable location
```

### Install Python Versions
```bash
pyenv install --list           # Show available versions to install
pyenv install 3.12.1          # Install specific version
pyenv install 3.11.7          # Install another version
pyenv rehash                   # Refresh pyenv shims after install
```

### Change Python Versions

#### Global (System-wide)
```bash
pyenv global 3.12.1           # Set global default
pyenv global 3.11.7           # Switch back to 3.11.7
pyenv global system            # Use system Python (not recommended)
```

#### Local (Per Project)
```bash
cd ~/my-project
pyenv local 3.10.12           # Set for this directory
pyenv local --unset           # Remove local setting (use global)
```

#### Temporary (One Command)
```bash
pyenv exec python script.py               # Use current pyenv version
PYENV_VERSION=3.12.1 python script.py    # Use specific version once
```

### UV Version Management

#### Project-Specific
```bash
# Method 1: .python-version file
echo "3.12.1" > .python-version
uv sync                        # Uses specified version

# Method 2: Direct specification
uv run --python 3.12 python script.py
uv venv --python 3.11 .venv
```

#### Multiple Environments
```bash
# Create environments with different Python versions
uv venv --python 3.11 ~/.venvs/data-science-311
uv venv --python 3.12 ~/.venvs/web-dev-312
uv venv --python 3.10 ~/.venvs/legacy-310

# Use in projects
source ~/.venvs/data-science-311/bin/activate
```

## 🎯 Common Scenarios

### Scenario 1: New Project Needs Python 3.12
```bash
# Install Python 3.12 if not available
pyenv install 3.12.1

# Create project
mkdir ~/new-project && cd ~/new-project

# Set Python version for this project
pyenv local 3.12.1

# Initialize with uv
uv init --no-readme
uv add requests

# Verify
python --version  # Should show 3.12.1
```

### Scenario 2: Legacy Project Needs Python 3.9
```bash
# Install older Python version
pyenv install 3.9.18

# Navigate to legacy project
cd ~/legacy-project

# Set local Python version
pyenv local 3.9.18

# Use with uv
uv sync  # Will use Python 3.9.18
```

### Scenario 3: Testing Across Multiple Python Versions
```bash
# Test script with different Python versions
uv run --python 3.10 python test_script.py
uv run --python 3.11 python test_script.py
uv run --python 3.12 python test_script.py

# Or use tox/nox for automated testing across versions
```

### Scenario 4: Different Teams Use Different Versions
```bash
# Team A uses Python 3.11
mkdir ~/team-a-project && cd ~/team-a-project
pyenv local 3.11.7
uv init && uv add fastapi

# Team B uses Python 3.12
mkdir ~/team-b-project && cd ~/team-b-project
pyenv local 3.12.1
uv init && uv add django
```

## 🔧 Troubleshooting

### Version Not Switching?
```bash
# Refresh pyenv
pyenv rehash

# Check for .python-version files
find . -name ".python-version" -exec cat {} \;

# Verify pyenv is in PATH
echo $PATH | grep pyenv

# Restart terminal if needed
```

### UV Not Using Right Python?
```bash
# Check what UV sees
uv python list
uv python install 3.12.1

# Force specific version
uv run --python 3.12 python --version
```

### Clean Install Issues?
```bash
# Remove problematic version and reinstall
pyenv uninstall 3.12.1
pyenv install 3.12.1
```

## 📁 File Locations

### Configuration Files
- `~/.python-version` - Global pyenv version
- `project/.python-version` - Local project version
- `~/.pyenv/version` - Alternative global version file

### Installation Paths
- `~/.pyenv/versions/` - All pyenv Python installations
- `~/.venvs/` - Shared virtual environments
- `project/.venv/` - Local project environments

## 🎨 Advanced Tips

### Set Multiple Global Versions
```bash
# Use multiple Python versions globally
pyenv global 3.11.7 3.12.1 3.10.12
python3.11 --version  # Python 3.11.7
python3.12 --version  # Python 3.12.1
```

### Environment Variables
```bash
# Temporary version override
export PYENV_VERSION=3.12.1
python --version  # Uses 3.12.1

# Clear override
unset PYENV_VERSION
```

### Shell Functions (Add to ~/.zshrc or ~/.bashrc)
```bash
# Quick Python version switcher
pyswitch() {
    if [ -z "$1" ]; then
        echo "Current: $(python --version)"
        echo "Usage: pyswitch 3.11|3.12|3.10"
    else
        pyenv local "$1"
        echo "Switched to Python $1"
        python --version
    fi
}

# Usage: pyswitch 3.12
```

## 🚀 Best Practices

1. **Use local versions for projects** - Always set `pyenv local` in project directories
2. **Keep .python-version in git** - Team members get same Python version
3. **Test with multiple versions** - Use UV's `--python` flag for testing
4. **Update regularly** - `pyenv install --list` to see new versions
5. **Document requirements** - Specify Python version in README
