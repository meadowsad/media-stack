# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
