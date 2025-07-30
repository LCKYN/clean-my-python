#!/bin/bash

# Complete Python Clean Slate Script
# ⚠️ WARNING: This will remove ALL Python installations and packages
# Save as ~/scripts/python-clean-slate.sh

set -e

show_help() {
    echo "🧹 Complete Python Clean Slate"
    echo "⚠️  WARNING: This will remove ALL Python installations and packages"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  analyze            Show what will be removed (safe)"
    echo "  backup             Backup current environments to files"
    echo "  clean-all          ⚠️ Remove everything and start fresh"
    echo "  clean-system       Remove system Python installations"
    echo "  clean-pyenv        Remove all pyenv Python versions"
    echo "  clean-packages     Remove global pip packages"
    echo "  setup-modern       Install modern Python stack (pyenv + uv)"
    echo "  full-reset         ⚠️ Complete nuclear option: remove everything + setup modern"
    echo ""
    echo "Recommended workflow:"
    echo "  1. $0 analyze       # See what you have"
    echo "  2. $0 backup        # Backup important environments"
    echo "  3. $0 full-reset    # Clean slate + modern setup"
}

analyze_current_setup() {
    echo "🔍 Analyzing current Python setup..."
    echo ""

    echo "📍 Python executables found:"
    for cmd in python python2 python3 python3.7 python3.8 python3.9 python3.10 python3.11 python3.12; do
        if command -v "$cmd" &> /dev/null; then
            location=$(which "$cmd")
            version=$("$cmd" --version 2>&1 || echo "unknown")
            echo "  ✓ $cmd: $version ($location)"
        fi
    done
    echo ""

    echo "🏠 Python installation locations:"

    # System Python (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  macOS System Python:"
        ls -la /usr/bin/python* 2>/dev/null | sed 's/^/    /' || echo "    None found"

        echo "  Homebrew Python:"
        if command -v brew &> /dev/null; then
            brew list 2>/dev/null | grep python | sed 's/^/    /' || echo "    None found"
            ls -la /opt/homebrew/bin/python* 2>/dev/null | sed 's/^/    /' || true
            ls -la /usr/local/bin/python* 2>/dev/null | sed 's/^/    /' || true
        else
            echo "    Homebrew not installed"
        fi
    fi

    # Linux system Python
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  System Python (Linux):"
        ls -la /usr/bin/python* 2>/dev/null | sed 's/^/    /' || echo "    None found"

        echo "  Package manager Python:"
        dpkg -l | grep python 2>/dev/null | head -5 | sed 's/^/    /' || echo "    None found (or not Debian-based)"
    fi

    echo ""
    echo "🐍 Pyenv installations:"
    if command -v pyenv &> /dev/null; then
        echo "  Pyenv location: $(which pyenv)"
        echo "  Python versions:"
        pyenv versions | sed 's/^/    /'
        echo "  Disk usage: $(du -sh ~/.pyenv 2>/dev/null | cut -f1 || echo 'unknown')"
    else
        echo "  pyenv not installed"
    fi

    echo ""
    echo "📦 Virtual environments:"

    # Find .venv directories
    echo "  Local .venv directories:"
    find . -name ".venv" -type d 2>/dev/null | while read -r venv; do
        size=$(du -sh "$venv" 2>/dev/null | cut -f1)
        echo "    $(dirname "$venv"): $size"
    done

    # Check common venv locations
    for venv_dir in ~/.venvs ~/venv ~/envs ~/.virtualenvs; do
        if [ -d "$venv_dir" ]; then
            size=$(du -sh "$venv_dir" 2>/dev/null | cut -f1)
            count=$(ls -1 "$venv_dir" 2>/dev/null | wc -l)
            echo "  $venv_dir: $size ($count environments)"
        fi
    done

    echo ""
    echo "🔧 Package managers:"
    echo "  pip: $(command -v pip &> /dev/null && pip --version || echo 'not found')"
    echo "  uv: $(command -v uv &> /dev/null && uv --version || echo 'not found')"
    echo "  conda: $(command -v conda &> /dev/null && conda --version || echo 'not found')"
    echo "  pipenv: $(command -v pipenv &> /dev/null && pipenv --version || echo 'not found')"
    echo "  poetry: $(command -v poetry &> /dev/null && poetry --version || echo 'not found')"

    echo ""
    echo "💾 Estimated total disk usage:"
    total_estimate=0

    if [ -d ~/.pyenv ]; then
        pyenv_size=$(du -s ~/.pyenv 2>/dev/null | cut -f1)
        echo "  pyenv: ~$((pyenv_size / 1024))MB"
        total_estimate=$((total_estimate + pyenv_size))
    fi

    # Estimate other Python-related directories
    for dir in ~/.cache/pip ~/.cache/uv ~/.venvs; do
        if [ -d "$dir" ]; then
            dir_size=$(du -s "$dir" 2>/dev/null | cut -f1)
            echo "  $(basename "$dir"): ~$((dir_size / 1024))MB"
            total_estimate=$((total_estimate + dir_size))
        fi
    done

    echo "  Total estimated: ~$((total_estimate / 1024))MB"

    echo ""
    echo "⚠️  Items that will be removed with 'clean-all':"
    echo "  - All pyenv Python versions"
    echo "  - All virtual environments (.venv, ~/.venvs, etc.)"
    echo "  - All pip caches"
    echo "  - Homebrew Python packages (macOS)"
    echo "  - Global pip packages"
    echo "  - Python-related configs"
}

backup_environments() {
    echo "💾 Backing up current environments..."

    # Create backup directory
    BACKUP_DIR="$HOME/python-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    echo "📁 Backup directory: $BACKUP_DIR"
    echo ""

    # Backup global pip packages
    if command -v pip &> /dev/null; then
        echo "📦 Backing up global pip packages..."
        pip freeze > "$BACKUP_DIR/global-pip-packages.txt" 2>/dev/null || echo "# No global packages" > "$BACKUP_DIR/global-pip-packages.txt"
        echo "  Saved to: global-pip-packages.txt"
    fi

    # Backup pyenv versions list
    if command -v pyenv &> /dev/null; then
        echo "🐍 Backing up pyenv version list..."
        pyenv versions --bare > "$BACKUP_DIR/pyenv-versions.txt"
        echo "  Saved to: pyenv-versions.txt"
    fi

    # Backup virtual environments
    echo "🏠 Backing up virtual environment packages..."
    venv_count=0

    # Check common venv locations
    for venv_dir in ~/.venvs ~/venv ~/envs ~/.virtualenvs; do
        if [ -d "$venv_dir" ]; then
            for env in "$venv_dir"/*; do
                if [ -d "$env" ] && [ -f "$env/bin/activate" ]; then
                    env_name=$(basename "$env")
                    echo "  Backing up: $env_name"
                    source "$env/bin/activate"
                    pip freeze > "$BACKUP_DIR/venv-${env_name}-packages.txt" 2>/dev/null || echo "# Failed to backup" > "$BACKUP_DIR/venv-${env_name}-packages.txt"
                    deactivate 2>/dev/null || true
                    venv_count=$((venv_count + 1))
                fi
            done
        fi
    done

    # Find local .venv directories
    find . -name ".venv" -type d 2>/dev/null | while read -r venv; do
        project_name=$(basename "$(dirname "$venv")")
        echo "  Backing up local venv: $project_name"
        if [ -f "$venv/bin/activate" ]; then
            source "$venv/bin/activate"
            pip freeze > "$BACKUP_DIR/local-${project_name}-packages.txt" 2>/dev/null || echo "# Failed to backup" > "$BACKUP_DIR/local-${project_name}-packages.txt"
            deactivate 2>/dev/null || true
        fi
    done

    # Create restore script
    cat > "$BACKUP_DIR/restore-guide.md" << 'EOF'
# Python Environment Restore Guide

This backup was created before cleaning your Python installation.

## Files in this backup:

- `global-pip-packages.txt` - Global pip packages
- `pyenv-versions.txt` - Pyenv Python versions that were installed
- `venv-*-packages.txt` - Packages from each virtual environment
- `local-*-packages.txt` - Packages from local project environments

## To restore after setting up modern Python stack:

### 1. Reinstall Python versions with pyenv:
```bash
# Read the versions file and install each version
cat pyenv-versions.txt | while read version; do
    pyenv install "$version"
done
```

### 2. Recreate environments with uv:
```bash
# For each venv backup file, create new environment
# Example for a data science environment:
uv venv ~/.venvs/data-science
source ~/.venvs/data-science/bin/activate
uv pip install -r venv-data-science-packages.txt
```

### 3. Modern approach (recommended):
Instead of recreating old environments exactly, consider:
- Creating shared base environments by purpose (web-dev, data-science, etc.)
- Using environment templates from GitHub
- Using `uv` for automatic dependency management

## Example modern recreation:
```bash
# Instead of exact restore, create purpose-based environments
uv venv ~/.venvs/data-science
source ~/.venvs/data-science/bin/activate
uv pip install pandas numpy matplotlib scikit-learn jupyter

# Then use across multiple projects
```
EOF

    echo ""
    echo "✅ Backup completed!"
    echo "📁 Location: $BACKUP_DIR"
    echo "📋 Backed up $venv_count virtual environments"
    echo "📖 See restore-guide.md for restoration instructions"
}

clean_system_python() {
    echo "🧹 Cleaning system Python installations..."
    echo ""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🍎 macOS detected - cleaning Homebrew Python..."

        if command -v brew &> /dev/null; then
            # Remove all Python versions from Homebrew
            echo "🍺 Removing Homebrew Python packages..."

            # Get list of installed Python packages
            PYTHON_PACKAGES=$(brew list | grep python || true)

            if [ -n "$PYTHON_PACKAGES" ]; then
                echo "Found Homebrew Python packages:"
                echo "$PYTHON_PACKAGES" | sed 's/^/  - /'
                echo ""

                read -p "❓ Remove all Homebrew Python packages? (y/N): " -n 1 -r
                echo

                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo "$PYTHON_PACKAGES" | while read -r pkg; do
                        if [ -n "$pkg" ]; then
                            echo "🗑️  Removing $pkg..."
                            brew uninstall --ignore-dependencies "$pkg" 2>/dev/null || echo "  Failed to remove $pkg"
                        fi
                    done

                    # Clean up orphaned dependencies
                    brew autoremove 2>/dev/null || true
                fi
            else
                echo "✅ No Homebrew Python packages found"
            fi

            # Remove Python symlinks in /usr/local/bin
            echo "🔗 Cleaning Python symlinks..."
            for link in /usr/local/bin/python* /opt/homebrew/bin/python*; do
                if [ -L "$link" ]; then
                    echo "🗑️  Removing symlink: $link"
                    rm -f "$link" 2>/dev/null || sudo rm -f "$link" 2>/dev/null || echo "  Failed to remove $link"
                fi
            done

        else
            echo "Homebrew not found, skipping Homebrew cleanup"
        fi

        # Note about system Python (don't remove on macOS)
        echo ""
        echo "ℹ️  Keeping macOS system Python (in /usr/bin) - it's needed by the system"

    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "🐧 Linux detected"
        echo ""
        echo "⚠️  WARNING: Removing system Python on Linux can break your system!"
        echo "Many system tools depend on Python. Proceeding will only remove user-installed Python packages."
        echo ""

        read -p "❓ Continue with Linux Python cleanup? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Remove user-installed Python packages via package manager
            if command -v apt &> /dev/null; then
                echo "🗑️  Removing user-installed Python packages (apt)..."
                sudo apt autoremove python3-pip python3-venv python3-dev 2>/dev/null || echo "  Some packages may not be installed"
            elif command -v yum &> /dev/null; then
                echo "🗑️  Removing user-installed Python packages (yum)..."
                sudo yum remove python3-pip python3-devel 2>/dev/null || echo "  Some packages may not be installed"
            fi
        fi
    fi

    echo "✅ System Python cleanup completed"
}

clean_pyenv() {
    echo "🐍 Cleaning pyenv installations..."

    if ! command -v pyenv &> /dev/null; then
        echo "✅ pyenv not installed, nothing to clean"
        return 0
    fi

    echo "📋 Current pyenv versions:"
    pyenv versions
    echo ""

    read -p "❓ Remove ALL pyenv Python versions? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing all pyenv Python versions..."

        # Get all installed versions (excluding system)
        pyenv versions --bare | grep -v system | while read -r version; do
            if [ -n "$version" ]; then
                echo "  Removing Python $version..."
                pyenv uninstall -f "$version"
            fi
        done

        echo "🗑️  Removing pyenv itself..."
        rm -rf ~/.pyenv

        # Remove pyenv from shell configs
        for config in ~/.bashrc ~/.zshrc ~/.bash_profile ~/.profile; do
            if [ -f "$config" ]; then
                echo "🧹 Cleaning pyenv from $config..."
                grep -v "pyenv" "$config" > "${config}.tmp" && mv "${config}.tmp" "$config"
            fi
        done

        echo "✅ pyenv completely removed"
    else
        echo "⏭️  Skipped pyenv removal"
    fi
}

clean_virtual_environments() {
    echo "🏠 Cleaning virtual environments..."
    echo ""

    # Remove common venv directories
    for venv_dir in ~/.venvs ~/venv ~/envs ~/.virtualenvs; do
        if [ -d "$venv_dir" ]; then
            size=$(du -sh "$venv_dir" 2>/dev/null | cut -f1)
            echo "🗑️  Removing $venv_dir ($size)..."
            rm -rf "$venv_dir"
        fi
    done

    # Find and remove local .venv directories
    echo "🔍 Finding local .venv directories..."
    find . -name ".venv" -type d 2>/dev/null | while read -r venv; do
        size=$(du -sh "$venv" 2>/dev/null | cut -f1)
        project=$(dirname "$venv")
        echo "🗑️  Removing .venv in $project ($size)..."
        rm -rf "$venv"
    done

    echo "✅ Virtual environments cleaned"
}

clean_caches_and_configs() {
    echo "🧹 Cleaning Python caches and configs..."

    # Remove pip cache
    if [ -d ~/.cache/pip ]; then
        size=$(du -sh ~/.cache/pip 2>/dev/null | cut -f1)
        echo "🗑️  Removing pip cache ($size)..."
        rm -rf ~/.cache/pip
    fi

    # Remove uv cache
    if [ -d ~/.cache/uv ]; then
        size=$(du -sh ~/.cache/uv 2>/dev/null | cut -f1)
        echo "🗑️  Removing uv cache ($size)..."
        rm -rf ~/.cache/uv
    fi

    # Remove other Python-related caches
    for cache_dir in ~/.cache/pyright ~/.mypy_cache ~/.pytest_cache; do
        if [ -d "$cache_dir" ]; then
            echo "🗑️  Removing $cache_dir..."
            rm -rf "$cache_dir"
        fi
    done

    # Remove Python configs
    for config_dir in ~/.config/pip ~/.config/uv ~/.local/share/uv; do
        if [ -d "$config_dir" ]; then
            echo "🗑️  Removing $config_dir..."
            rm -rf "$config_dir"
        fi
    done

    echo "✅ Caches and configs cleaned"
}

setup_modern_python_stack() {
    echo "🚀 Setting up modern Python stack..."
    echo ""

    # Install pyenv
    echo "📥 Installing pyenv..."
    if command -v pyenv &> /dev/null; then
        echo "  pyenv already installed"
    else
        curl https://pyenv.run | bash
        export PATH="$HOME/.pyenv/bin:$PATH"
    fi

    # Install uv
    echo "📥 Installing uv..."
    if command -v uv &> /dev/null; then
        echo "  uv already installed"
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    # Install Python 3.11 (stable and modern)
    echo "🐍 Installing Python 3.11..."
    pyenv install 3.11.7
    pyenv global 3.11.7

    # Setup shell configuration
    echo "⚙️  Configuring shell..."

    # Detect shell and add to appropriate config
    SHELL_CONFIG=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    else
        echo "⚠️  Could not detect shell. Please add manually to your shell config:"
    fi

    if [ -n "$SHELL_CONFIG" ]; then
        echo "📝 Adding configuration to $SHELL_CONFIG..."

        # Remove any existing pyenv/uv configs
        grep -v -E "(pyenv|uv|\.cargo)" "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp" 2>/dev/null || touch "${SHELL_CONFIG}.tmp"
        mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"

        # Add new configurations
        cat >> "$SHELL_CONFIG" << 'EOF'

# Modern Python stack configuration
export PATH="$HOME/.pyenv/bin:$HOME/.cargo/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Python aliases
alias python="python3"
alias pip="python -m pip"

# UV configuration
export UV_CACHE_DIR="$HOME/.cache/uv"
export UV_PYTHON_INSTALL_DIR="$HOME/.local/share/uv/python"
EOF

        echo "✅ Shell configuration added"
    fi

    # Create shared environments directory
    echo "📁 Creating shared environments directory..."
    mkdir -p ~/.venvs

    echo ""
    echo "🎉 Modern Python stack setup complete!"
    echo ""
    echo "🔄 Please restart your terminal or run:"
    echo "source $SHELL_CONFIG"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Restart terminal"
    echo "2. Verify setup: python --version (should show 3.11.7)"
    echo "3. Verify uv: uv --version"
    echo "4. Create your first modern environment: uv venv ~/.venvs/general"
}

clean_all() {
    echo "💥 NUCLEAR OPTION: Complete Python cleanup"
    echo ""
    echo "⚠️  This will remove:"
    echo "  - ALL Python versions (except macOS system Python)"
    echo "  - ALL virtual environments"
    echo "  - ALL pip packages"
    echo "  - ALL Python caches and configs"
    echo "  - pyenv installation"
    echo "  - Homebrew Python packages"
    echo ""

    read -p "❓ Are you absolutely sure? Type 'yes' to proceed: " -r
    echo

    if [[ $REPLY == "yes" ]]; then
        echo "🚀 Starting complete cleanup..."
        echo ""

        clean_virtual_environments
        echo ""
        clean_pyenv
        echo ""
        clean_system_python
        echo ""
        clean_caches_and_configs
        echo ""

        echo "✅ Complete cleanup finished!"
        echo "🧹 Your system is now clean of Python installations"
    else
        echo "❌ Cleanup cancelled"
    fi
}

full_reset() {
    echo "🔄 FULL RESET: Clean everything + setup modern stack"
    echo ""
    echo "This will:"
    echo "1. Remove all existing Python installations"
    echo "2. Set up modern Python stack (pyenv + uv + Python 3.11)"
    echo ""

    read -p "❓ Proceed with full reset? Type 'yes': " -r
    echo

    if [[ $REPLY == "yes" ]]; then
        echo "🚀 Starting full reset..."
        echo ""

        # Clean everything
        clean_virtual_environments
        echo ""
        clean_pyenv
        echo ""
        clean_system_python
        echo ""
        clean_caches_and_configs
        echo ""

        # Setup modern stack
        setup_modern_python_stack
        echo ""

        echo "🎉 Full reset complete!"
        echo "🐍 You now have a clean, modern Python setup"
        echo ""
        echo "🎯 Ready for:"
        echo "  - pyenv for Python version management"
        echo "  - uv for fast package management"
        echo "  - Python 3.11 as your default"
        echo "  - Clean slate for creating new environments"

    else
        echo "❌ Full reset cancelled"
    fi
}

# Main script logic
case "$1" in
    "analyze")
        analyze_current_setup
        ;;
    "backup")
        backup_environments
        ;;
    "clean-all")
        clean_all
        ;;
    "clean-system")
        clean_system_python
        ;;
    "clean-pyenv")
        clean_pyenv
        ;;
    "clean-packages")
        clean_caches_and_configs
        ;;
    "setup-modern")
        setup_modern_python_stack
        ;;
    "full-reset")
        full_reset
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
