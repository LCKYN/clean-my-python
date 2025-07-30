# UV-First Modern Python Workflow

## 🎯 The Modern Python Stack (2024+)

### Recommended Tools Hierarchy
```
1. 🚀 UV (Package management + virtual envs) - PRIMARY TOOL
2. 🐍 pyenv (Python version management) - SECONDARY
3. 📦 pip (Fallback only) - RARELY NEEDED
```

## ⚡ Why UV Should Be Your Primary Tool

### Speed Benchmarks
| Task | pip + venv | UV | Speedup |
|------|------------|----|---------|
| Install pandas | ~45s | ~6s | 7x faster |
| Create environment | ~8s | ~2s | 4x faster |
| Install from requirements.txt | ~120s | ~15s | 8x faster |
| Resolve dependencies | ~30s | ~3s | 10x faster |

### Feature Comparison
| Feature | pip/venv | UV |
|---------|----------|----|
| Speed | Slow | 🚀 Ultra-fast |
| Dependency resolution | Poor | 🧠 Excellent |
| Environment management | Manual | 🤖 Automatic |
| Caching | Basic | 💾 Advanced |
| Cross-platform | OK | ✅ Excellent |
| Lock files | No | ✅ Yes |
| Modern standards | Partial | ✅ Full |

## 🛠️ UV-First Project Setup

### New Project Workflow
```bash
# 1. Create project directory
mkdir my-awesome-project && cd my-awesome-project

# 2. Set Python version (if needed)
echo "3.11.7" > .python-version

# 3. Initialize UV project
uv init --no-readme

# 4. Add dependencies (automatically creates/manages venv)
uv add fastapi uvicorn
uv add --dev pytest black mypy

# 5. Run your code (no activation needed!)
uv run python main.py

# 6. Add more packages as needed
uv add requests pandas
```

### Existing Project Migration
```bash
# Migrate from pip to uv
cd existing-project

# Option 1: From requirements.txt
uv init --no-readme
uv add $(cat requirements.txt | grep -v '^#' | tr '\n' ' ')

# Option 2: From pip freeze
uv init --no-readme
pip freeze | grep -v '^#' > requirements.txt
uv add $(cat requirements.txt | tr '\n' ' ')

# Clean up old environment
rm -rf .venv-old  # your old venv
rm requirements.txt  # now managed by pyproject.toml
```

## 📋 UV Command Cheat Sheet

### Essential Commands
```bash
# Project initialization
uv init                          # Initialize UV project
uv init --no-readme             # Skip README creation

# Package management
uv add package_name             # Add package
uv add --dev package_name       # Add dev dependency
uv remove package_name          # Remove package
uv sync                         # Install all dependencies
uv lock                         # Generate lockfile

# Running code
uv run python script.py         # Run with auto venv
uv run --python 3.12 script.py  # Run with specific Python
uv run pytest                   # Run dev tools

# Environment management
uv venv                         # Create virtual environment
uv venv --python 3.12          # Create with specific Python
uv pip install package         # Pip-like interface
uv pip freeze                   # List installed packages

# Global tools
uv tool install black           # Install CLI tool globally
uv tool install pytest         # Install testing tool globally
uv tool list                    # List global tools
```

### Advanced Commands
```bash
# Python management (newer UV versions)
uv python install 3.12.1       # Install Python version
uv python list                  # List available Pythons
uv python pin 3.11             # Pin Python version

# Project management
uv export > requirements.txt    # Export for compatibility
uv cache clean                  # Clean package cache
uv tree                        # Show dependency tree
```

## 🎨 Workflow Examples

### Data Science Project
```bash
# Setup
mkdir data-analysis && cd data-analysis
echo "3.11.7" > .python-version
uv init --no-readme

# Add data science stack
uv add pandas numpy matplotlib seaborn jupyter
uv add --dev pytest black isort

# Add project-specific packages
uv add scikit-learn plotly

# Run Jupyter
uv run jupyter notebook

# Run analysis script
uv run python analyze_data.py
```

### Web Development Project
```bash
# Setup
mkdir web-app && cd web-app
uv init --no-readme

# Add web framework
uv add fastapi uvicorn
uv add --dev pytest pytest-asyncio black

# Add database tools
uv add sqlalchemy alembic

# Run development server
uv run uvicorn main:app --reload

# Run tests
uv run pytest
```

### CLI Tool Project
```bash
# Setup
mkdir cli-tool && cd cli-tool
uv init --no-readme

# Add CLI dependencies
uv add click rich typer
uv add --dev pytest black mypy

# Make CLI tool globally available
uv tool install --editable .

# Run locally during development
uv run python cli.py --help
```

## 🔄 Migration from Old Workflows

### From pip + requirements.txt
```bash
# Before (old way)
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip freeze > requirements-lock.txt

# After (UV way)
uv add $(cat requirements.txt | tr '\n' ' ')
uv lock  # Creates uv.lock automatically
```

### From pipenv
```bash
# Before (pipenv)
pipenv install
pipenv install --dev pytest
pipenv run python script.py

# After (UV)
uv sync  # If migrating Pipfile
uv add --dev pytest
uv run python script.py
```

### From poetry
```bash
# Before (poetry)
poetry install
poetry add requests
poetry run python script.py

# After (UV)
uv sync  # If migrating pyproject.toml
uv add requests
uv run python script.py
```

## 🏗️ Project Structure with UV

### Recommended Structure
```
my-project/
├── .python-version          # Python version (pyenv)
├── pyproject.toml          # UV manages this automatically
├── uv.lock                 # Lockfile (like poetry.lock)
├── .venv/                  # Auto-created by UV
├── src/
│   └── myproject/
├── tests/
└── README.md
```

### pyproject.toml (auto-generated by UV)
```toml
[project]
name = "my-project"
version = "0.1.0"
description = ""
dependencies = [
    "fastapi>=0.104.1",
    "uvicorn>=0.24.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "black>=23.9.0",
    "mypy>=1.6.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

## 🎯 Best Practices with UV

### 1. Always Use uv.lock
```bash
# Generate lockfile for reproducible builds
uv lock

# Install exact versions from lockfile
uv sync

# Commit lockfile to version control
git add uv.lock
```

### 2. Separate Dev Dependencies
```bash
# Production dependencies
uv add requests fastapi

# Development dependencies
uv add --dev pytest black mypy isort

# Install only production deps
uv sync --no-dev
```

### 3. Use .python-version Files
```bash
# Set Python version for project
echo "3.11.7" > .python-version

# UV will automatically use this version
uv sync  # Uses Python 3.11.7
```

### 4. Global Tools with UV
```bash
# Install tools globally (not per-project)
uv tool install black
uv tool install ruff
uv tool install mypy

# Use anywhere
black my_file.py  # Works in any directory
```

### 5. Environment Variables
```bash
# Customize UV behavior
export UV_CACHE_DIR="$HOME/.cache/uv"  # Cache location
export UV_PYTHON_INSTALL_DIR="$HOME/.local/share/uv/python"  # Python installs
```

## 🔧 Troubleshooting UV

### Common Issues and Solutions

#### "No Python interpreter found"
```bash
# Install Python version first
pyenv install 3.11.7
# or
uv python install 3.11.7

# Then retry UV command
uv sync
```

#### "Package not found"
```bash
# Update package index
uv cache clean

# Try different package name or version
uv add "package>=1.0.0"
```

#### "Dependency resolution failed"
```bash
# Check for conflicts
uv tree

# Try resolving manually
uv add package1 package2 --resolution=highest
```

### Performance Optimization
```bash
# Use UV's parallel installation
uv sync --no-progress  # Disable progress bars for CI

# Enable link mode for faster installs
export UV_LINK_MODE=copy
```

## 📊 When to Still Use pip

### Rare Cases Where pip Might Be Needed
```bash
# 1. Installing from git with specific options
pip install git+https://github.com/user/repo.git@branch#egg=package

# 2. Editable installs with complex paths
pip install -e ../other-project[extra]

# 3. Very specific wheel files
pip install ./custom-wheel.whl

# 4. Legacy systems that require pip
```

### But UV Can Handle Most of These Now
```bash
# UV equivalents
uv add git+https://github.com/user/repo.git@branch
uv add -e ../other-project
uv pip install ./custom-wheel.whl  # UV has pip interface too
```

## 🚀 The Ultimate Modern Python Setup

```bash
# 1. Install modern tools
curl https://pyenv.run | bash           # Python version management
curl -LsSf https://astral.sh/uv/install.sh | sh  # UV package manager

# 2. Install Python
pyenv install 3.11.7
pyenv global 3.11.7

# 3. Start any new project with UV
mkdir awesome-project && cd awesome-project
uv init --no-readme
uv add your-dependencies
uv run python main.py

# 4. Never look back! 🎉
```

### Result: Modern, Fast, Reliable Python Development! 🚀🚀
