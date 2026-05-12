# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-12

### Changed
- Migrated from Docker Compose V1 (`docker-compose`) to V2 (`docker compose`) throughout all scripts and documentation
- `scripts/update.sh` now stops containers before pulling images to prevent `ContainerConfig` errors on newer Docker Engine versions
- Removed deprecated `version` key from `docker-compose.yml`
- Replaced `docker-compose-plugin` installation in INSTALL.md (was incorrectly installing EOL V1 package)
- Standardized placeholder aliases: `YOUR_SERVER_IP` for web interface URLs, `YOUR_NAS_IP` for NFS configuration throughout all docs

### Added
- `docker-compose.yml`: named Docker networks (`media`, `media-readonly`) for container isolation — Jellyfin separated from download stack
- `systemd/storage-data-nas-media.mount`: added NFS hardening options (`noexec`, `nosuid`, `nodev`)
- `.gitignore`: was referenced in docs but missing from the repository
- `.env.example`: added `YOUR_NAS_IP` placeholder (previously contained a real IP)
- `mkdir -p` before `git clone` in all setup instructions

### Removed
- `GITHUB_GUIDE.md`: content fully covered by README.md
- `HOW_TO_APPLY.md`: one-time patch delivery document, no longer relevant
- `UPDATE_SUMMARY.md`: companion to HOW_TO_APPLY.md, no longer relevant
- `REPOSITORY_STRUCTURE.txt`: redundant with Directory Structure section in README.md
- `LICENSE.MD`: no necessary

## [1.0.0] - 2026-01-31

### Added
- Initial release
- Docker Compose configuration for SABnzbd, Sonarr, Radarr, and Jellyfin
- NFS mount systemd unit file
- Docker systemd override for NFS dependency
- Automated setup script for directory creation
- Backup and update scripts
- Comprehensive documentation (README, INSTALL, TROUBLESHOOTING)
- Environment variable support via .env file
- MIT License

### Features
- Automated TV show and movie downloads via Usenet
- Local download storage with NFS final destination
- Proper file organization and renaming
- Universal streaming via Jellyfin
- Support for multiple client devices

## [Unreleased]

### Planned
- Add Prowlarr for unified indexer management
- Optional Nginx reverse proxy configuration
- Automated SSL certificate setup with Let's Encrypt
- Monitoring stack with Prometheus and Grafana
- Additional client setup guides (Kodi, Plex, etc.)
