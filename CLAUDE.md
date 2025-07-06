# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

DBDB is a database version manager that supports multiple databases (MySQL, PostgreSQL, MongoDB, Redis, Memcached) across Linux and macOS platforms. It allows users to create, manage, and run multiple database instances with different versions simultaneously.

## Database Operations

All database types follow the same command pattern:
```bash
./{database}/{operation}.sh {name} [{version}] [{port}]
```

Operations: `create`, `start`, `stop`, `restart`, `port`, `status`, `connect`, `delete`, `create-start`

Examples:
```bash
# Create and start databases
./mysql/create.sh mysql1 8.0.41 3306
./mongodb/create.sh mongo1 7.0.21 27017
./redis/create.sh redis1 6.2.14 6379

# Use random port
./mysql/create.sh mysql2 8.0.41 random

# Create and start in one command
./mysql/create-start.sh mysql3 8.0.41 3306
```

## Supported Versions

### MySQL
- linux-amd64: 5.7.31, 8.0.23, 8.0.30
- macos-arm64: 8.0.28, 8.0.41, 8.4.4, 9.2.0

### PostgreSQL
- linux-amd64: 12.6, 13.2
- macos-arm64: 12.6, 13.2

### MongoDB
- linux-amd64: 6.0.24, 7.0.21
- macos-arm64: 6.0.24, 7.0.21

### Redis
- linux-amd64: 6.2.14, 7.2.5
- macos-arm64: 6.2.14, 7.2.5

### Memcached
- linux-amd64: 1.6.31
- macos-arm64: 1.6.31

## Testing

Run database-specific tests:
```bash
cd tests
./mongodb-8.0.11.sh
./mysql-8.0.41.sh
./redis-6.2.14.sh
```

Tests create temporary instances, perform operations, and clean up automatically.

## Architecture

### Core Components

- **Database directories** (`mysql/`, `mongodb/`, etc.): Database-specific implementations
- **`lib/functions.sh`**: Shared utilities for OS detection, confirmation prompts
- **`dbdb.sh`**: Main script to list all managed database instances
- **`tests/`**: Integration tests for each supported database version

### Database-Specific Functions

Each database directory contains:
- `functions.sh`: Database-specific utility functions
- Operation scripts implementing the standard interface
- Shared patterns for installation, configuration, and lifecycle management

### Data Storage

Databases are installed in: `$HOME/.local/share/dbdb/{database}/versions/{version}/`

Each instance has:
- `basedir/`: Extracted database binaries
- `datadir/{name}/`: Instance-specific data and configuration

### Cross-Platform Support

- OS detection via `getOS()` function (Linux/macOS)
- Platform-specific binary downloads and configurations
- Compatible with both x86_64 and arm64 architectures

### Client Compatibility

MongoDB scripts handle client tool evolution:
- Try `mongosh` first (MongoDB 7.0+)
- Fallback to legacy `mongo` client
- Fallback to port-based status checking when no client is available

## GitHub Actions

CI tests run on both macOS and Ubuntu 22.04, with some database versions excluded on specific platforms due to compatibility issues (e.g., GLIBC requirements).
