#!/bin/bash

# Cross-Platform Python Clean Slate Script
# Works on Windows (via Git Bash/WSL), macOS, and Linux
# Save as: python-clean-slate.sh

show_help() {
    echo "🌍 Cross-Platform Python Clean Slate"
    echo "Compatible with Windows, macOS, and Linux"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  detect             Detect OS and show appropriate instructions"
    echo "  analyze            Show what will be removed (safe)"
    echo "  backup             Backup current environments"
    echo "  full-reset         Complete cleanup + modern setup"
    echo "  download-scripts   Download OS-specific scripts"
    echo ""
    echo "OS-specific commands will be shown after running 'detect'"
}

detect_os() {
    echo "🔍 Detecting operating system..."
    echo ""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🍎 macOS detected"
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "🐧 Linux detected"
        OS="linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "🪟 Windows (Git Bash) detected"
        OS="windows-bash"
    elif [[ -n "$WSL_DISTRO_NAME" ]]; then
        echo "🐧 Windows Subsystem for Linux detected"
        OS="wsl"
    else
        echo "❓ Unknown OS: $OSTYPE"
        echo ""
        echo "Manual detection:"
        echo "- Windows: Use PowerShell script"
        echo "- macOS/Linux: Use bash script"
        return 1
    fi

    echo "✅ OS detected: $OS"
    show_instructions_for_os
}

show_instructions_for_os() {
    echo ""
    echo "📋 Instructions for your OS:"
    echo ""

    case "$OS" in
        "macos"|"linux")
            echo "🔧 Use the Unix/Linux script:"
            echo "1. Download: curl -O https://raw.githubusercontent.com/yourusername/scripts/main/unix-python-cleanup.sh"
            echo "2. Make executable: chmod +x unix-python-cleanup.sh"
            echo "3. Run: ./unix-python-cleanup.sh full-reset"
            echo ""
            echo "Or use the built-in functions below..."
            ;;
        "windows-bash")
            echo "🔧 You're in Git Bash on Windows. Options:"
            echo ""
            echo "Option 1 - Use PowerShell script (Recommended):"
            echo "1. Download PowerShell script"
            echo "2. Run in PowerShell: .\\python-clean-slate.ps1 full-reset"
            echo ""
            echo "Option 2 - Use this script (Limited Windows support):"
            echo "./python-clean-slate.sh unix-cleanup-limited"
            ;;
        "wsl")
            echo "🔧 WSL detected - treat as Linux:"
            echo "1. Use the Unix cleanup functions"
            echo "2. Also consider cleaning Windows Python installations separately"
            echo "   (Run PowerShell script from Windows)"
            ;;
    esac
}

download_scripts() {
    echo "📥 Downloading OS-specific scripts..."
    echo ""

    # Create scripts directory
    mkdir -p python-cleanup-scripts
    cd python-cleanup-scripts

    echo "Downloading scripts to: $(pwd)"
    echo ""

    # Note: In a real implementation, these would be actual URLs
    echo "📝 Script templates created. In a real setup, download from:"
    echo ""
    echo "Windows PowerShell:"
    echo "curl -O https://raw.githubusercontent.com/yourusername/scripts/main/windows-python-cleanup.ps1"
    echo ""
    echo "Unix (macOS/Linux):"
    echo "curl -O https://raw.githubusercontent.com/yourusername/scripts/main/unix-python-cleanup.sh"
    echo ""
    echo "Cross-platform:"
    echo "curl -O https://raw.githubusercontent.com/yourusername/scripts/main/python-clean-slate.sh"

    # Create template files
    create_template_scripts
}

create_template_scripts() {
    # Create Windows PowerShell script template
    cat > windows-python-cleanup.ps1 << 'EOF'
# Windows Python Cleanup Script
# Usage: .\windows-python-cleanup.ps1 [command]
# Commands: analyze, backup, clean-all, setup-modern, full-reset

Write-Host "🪟 Windows Python Cleanup Script" -ForegroundColor Cyan
Write-Host "Use: .\windows-python-cleanup.ps1 full-reset" -ForegroundColor Yellow
Write-Host ""
Write-Host "For full script, see the complete PowerShell version." -ForegroundColor White
EOF

    # Create Unix script template
    cat > unix-python-cleanup.sh << 'EOF'
#!/bin/bash
# Unix Python Cleanup Script (macOS/Linux)
# Usage: ./unix-python-cleanup.sh [command]
# Commands: analyze, backup, clean-all, setup-modern, full-reset

echo "🐧 Unix Python Cleanup Script"
echo "Use: ./unix-python-cleanup.sh full-reset"
echo ""
echo "For full script, see the complete bash version."
EOF

    chmod +x unix-python-cleanup.sh

    echo "✅ Template scripts created in python-cleanup-scripts/"
    echo ""
    echo "📝 Next steps:"
    echo "1. Download the full scripts from the repository"
    echo "2. Replace these templates with the complete versions"
    echo "3. Run the appropriate script for your OS"
}

# Simplified cross-platform functions
unix_analyze() {
    echo "🔍 Quick Python analysis (Unix-style)..."
    echo ""

    echo "📍 Python executables:"
    for cmd in python python3 python3.11 python3.10 python3.9; do
        if command -v "$cmd" &> /dev/null; then
            location=$(which "$cmd")
            version=$("$cmd" --version 2>&1)
            echo "  ✓ $cmd: $version ($location)"
        fi
    done

    echo ""
    echo "🐍 Pyenv status:"
    if command -v pyenv &> /dev/null; then
        echo "  Installed: $(pyenv --version)"
        echo "  Versions: $(pyenv versions --bare | wc -l) Python versions"
        if [ -d ~/.pyenv ]; then
            size=$(du -sh ~/.pyenv 2>/dev/null | cut -f1)
            echo "  Disk usage: $size"
        fi
    else
        echo "  Not installed"
    fi

    echo ""
    echo "📦 Virtual environments:"
    for venv_dir in ~/.venvs .venv; do
        if [ -d "$venv_dir" ]; then
            count=$(find "$venv_dir" -name "pyvenv.cfg" 2>/dev/null | wc -l)
            size=$(du -sh "$venv_dir" 2>/dev/null | cut -f1)
            echo "  $venv_dir: $count environments, $size"
        fi
    done

    echo ""
    echo "💡 For detailed analysis, use the full OS-specific script"
}

unix_quick_setup() {
    echo "🚀 Quick modern Python setup (Unix)..."
    echo ""

    # Install pyenv if not present
    if ! command -v pyenv &> /dev/null; then
        echo "📥 Installing pyenv..."
        curl https://pyenv.run | bash
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init -)"
    fi

    # Install uv if not present
    if ! command -v uv &> /dev/null; then
        echo "📥 Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    # Install Python 3.11
    echo "🐍 Installing Python 3.11..."
    pyenv install 3.11.7 || echo "Python 3.11.7 may already be installed"
    pyenv global 3.11.7

    # Basic shell setup
    echo "⚙️  Basic shell setup..."
    SHELL_CONFIG="$HOME/.bashrc"
    [ -n "$ZSH_VERSION" ] && SHELL_CONFIG="$HOME/.zshrc"

    if ! grep -q "pyenv init" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Python modern stack" >> "$SHELL_CONFIG"
        echo 'export PATH="$HOME/.pyenv/bin:$HOME/.cargo/bin:$PATH"' >> "$SHELL_CONFIG"
        echo 'eval "$(pyenv init -)"' >> "$SHELL_CONFIG"
        echo 'alias python="python3"' >> "$SHELL_CONFIG"
    fi

    mkdir -p ~/.venvs

    echo ""
    echo "✅ Quick setup complete!"
    echo "🔄 Restart your terminal or run: source $SHELL_CONFIG"
    echo ""
    echo "💡 For complete cleanup + setup, use the full script"
}

windows_instructions() {
    echo "🪟 Windows-specific instructions:"
    echo ""
    echo "1. Open PowerShell as Administrator"
    echo "2. Download the Windows script:"
    echo "   Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/yourusername/scripts/main/windows-python-cleanup.ps1' -OutFile 'python-cleanup.ps1'"
    echo "3. Run the script:"
    echo "   PowerShell -ExecutionPolicy Bypass -File python-cleanup.ps1 full-reset"
    echo ""
    echo "Or use the simplified commands:"
    echo "  analyze    - See current Python installations"
    echo "  backup     - Backup current environments"
    echo "  full-reset - Complete cleanup + modern setup"
}

# Main script logic
case "$1" in
    "detect")
        detect_os
        ;;
    "analyze")
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            windows_instructions
        else
            unix_analyze
        fi
        ;;
    "backup")
        echo "💾 For proper backup, use the full OS-specific script"
        echo "This cross-platform script provides basic functionality only"
        ;;
    "quick-setup")
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            windows_instructions
        else
            unix_quick_setup
        fi
        ;;
    "full-reset")
        echo "🔄 For full reset, use the complete OS-specific script:"
        echo ""
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            windows_instructions
        else
            echo "Unix/Linux: Use the complete bash script"
            echo "Quick setup available with: $0 quick-setup"
        fi
        ;;
    "download-scripts")
        download_scripts
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Run '$0 help' for available commands"
        echo ""
        echo "💡 Start with: $0 detect"
        exit 1
        ;;
esac
