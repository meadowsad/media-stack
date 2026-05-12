# GitHub Repository - Quick Start Guide

This document explains the complete GitHub repository structure for your media automation system.

## 📦 What's Included

Your repository contains everything needed to deploy and maintain a Docker-based media automation stack:

### Core Files
- **docker-compose.yml** - Main Docker configuration for all services
- **.env.example** - Template for environment variables (copy to .env)
- **.gitignore** - Prevents committing sensitive data and generated files
- **LICENSE** - MIT License for the project
- **CHANGELOG.md** - Version history and changes

### Documentation
- **README.md** - Main project documentation with quick start
- **INSTALL.md** - Detailed step-by-step installation guide
- **docs/TROUBLESHOOTING.md** - Comprehensive troubleshooting guide
- **docs/CONFIGURATION_EXAMPLES.md** - Advanced configuration examples

### System Configuration
- **systemd/storage-data-nas-media.mount** - NFS mount systemd unit
- **systemd/docker-wait-for-nfs.conf** - Docker service override

### Automation Scripts
- **scripts/setup-directories.sh** - Automated directory structure creation
- **scripts/backup.sh** - Configuration backup script
- **scripts/update.sh** - Container update script

## 🚀 How to Use This Repository

### 1. Create Your GitHub Repository

```bash
# On GitHub, create a new repository (public or private)
# Name it: media-stack or similar
```

### 2. Initialize and Push

```bash
# Navigate to the repository folder
cd /path/to/media-stack-repo

# Initialize git (if not already done)
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: Media automation stack"

# Add your GitHub remote
git remote add origin https://github.com/yourusername/media-stack.git

# Push to GitHub
git push -u origin main
```

### 3. Clone on Your Server

When setting up a new server:

```bash
# Clone your repository
cd /opt
sudo git clone https://github.com/yourusername/media-stack.git
cd media-stack

# Set ownership
sudo chown -R $USER:$USER /opt/media-stack

# Follow INSTALL.md for complete setup
```

## 📋 Repository Structure

```
media-stack/
├── README.md                    # Main documentation
├── INSTALL.md                   # Installation guide
├── CHANGELOG.md                 # Version history
├── LICENSE                      # MIT License
├── .gitignore                   # Git ignore rules
├── docker-compose.yml           # Docker configuration
├── .env.example                 # Environment template
│
├── docs/
│   ├── TROUBLESHOOTING.md       # Problem solving guide
│   └── CONFIGURATION_EXAMPLES.md # Advanced configs
│
├── scripts/
│   ├── setup-directories.sh     # Directory setup automation
│   ├── backup.sh                # Backup configurations
│   └── update.sh                # Update containers
│
└── systemd/
    ├── storage-data-nas-media.mount  # NFS mount config
    └── docker-wait-for-nfs.conf      # Docker service override
```

## 🔒 Security Best Practices

### Never Commit These Files

The `.gitignore` is configured to prevent committing:
- `.env` (contains your actual credentials)
- Container config directories (may contain API keys)
- Backup archives
- Log files

### What to Customize Before Committing

1. **systemd/storage-data-nas-media.mount**
   - Replace `your_nas_ip:/mnt/Default_Pool/Media` with your_nas_ip:/your/path
   - Or use placeholders and document in README

2. **.env.example**
   - Keep as generic template
   - Document all required variables

3. **README.md**
   - Update GitHub URLs to your repository
   - Add any specific notes for your setup

## 🔄 Workflow for Updates

### Making Changes

```bash
# Make your changes to files
nano docker-compose.yml

# Stage changes
git add docker-compose.yml

# Commit with descriptive message
git commit -m "Update: Added resource limits to Jellyfin"

# Push to GitHub
git push
```

### Pulling Updates on Server

```bash
cd /opt/media-stack

# Stop containers
docker-compose down

# Pull latest changes
git pull

# Restart containers with new config
docker-compose up -d
```

## 📚 Documentation Guide

### README.md
- **Purpose:** Quick overview and getting started
- **Audience:** New users
- **Content:** Architecture, quick start, basic config

### INSTALL.md
- **Purpose:** Complete installation walkthrough
- **Audience:** First-time installers
- **Content:** Step-by-step with commands and explanations

### docs/TROUBLESHOOTING.md
- **Purpose:** Problem resolution
- **Audience:** Users having issues
- **Content:** Common problems and solutions

### docs/CONFIGURATION_EXAMPLES.md
- **Purpose:** Advanced customization
- **Audience:** Experienced users
- **Content:** Alternative configs and optimizations

## 🛠️ Maintenance Tasks

### Regular Commits

Track your configuration changes:
```bash
# After making working changes
git add .
git commit -m "Config: Update Sonarr quality profiles"
git push
```

### Version Tags

Tag stable configurations:
```bash
git tag -a v1.0.0 -m "Stable working configuration"
git push --tags
```

### Backup Strategy

1. **Local backups:** Use `scripts/backup.sh`
2. **Git history:** Commits track all changes
3. **GitHub:** Remote backup of all configs

## 🔧 Customization Tips

### Fork vs Clone

**Clone** (recommended for personal use):
- Direct copy of repository
- You control everything
- Simpler workflow

**Fork** (if you want to contribute back):
- GitHub copy with attribution
- Can submit pull requests
- Good for sharing improvements

### Branch Strategy

For personal use, single branch (main) is fine.

For experimentation:
```bash
# Create experimental branch
git checkout -b experimental

# Make changes and test
# ...

# If it works, merge back
git checkout main
git merge experimental
```

## 📤 Sharing Your Setup

### Make Repository Public

If you want to help others:
1. Clean any personal data from files
2. Use placeholders for IPs/paths
3. Make repository public on GitHub
4. Add good README with your setup details

### Private Repository

For personal use:
- Keep repository private
- Only you can access
- Free on GitHub for private repos

## 🎯 Next Steps

1. **Customize** the template files with your information
2. **Commit** to your local git
3. **Push** to GitHub
4. **Clone** on your server
5. **Deploy** using INSTALL.md
6. **Maintain** with regular git commits

## 💡 Pro Tips

### Use GitHub Releases

Create releases for stable versions:
1. Go to your repo on GitHub
2. Click "Releases" → "Create a new release"
3. Tag version (e.g., v1.0.0)
4. Add release notes
5. Attach any additional files if needed

### GitHub Actions (Optional)

Automate testing or deployment:
```yaml
# .github/workflows/test.yml
name: Test Configuration
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate docker-compose
        run: docker-compose config
```

### Wiki for Documentation

Use GitHub Wiki for:
- Personal notes
- Hardware specs
- Network diagrams
- Troubleshooting log

## 📞 Support

If you make your repository public, consider:
- Adding issue templates
- Creating a CONTRIBUTING.md
- Adding a CODE_OF_CONDUCT.md

---

**You now have a complete, version-controlled, reproducible media automation system!**

Happy automating! 🎬📺
