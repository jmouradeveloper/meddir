# Scripts Documentation

This directory contains documentation for the development scripts used in this project.

## Available Documentation

- [Docker Scripts](docker-scripts.md) - Scripts for Docker-based development workflow

## Overview

All development is done via Docker Compose. The scripts in `bin/docker/` provide convenient wrappers for common tasks.

### Quick Reference

| Task | Command |
|------|---------|
| Start server | `bin/docker/up` |
| Stop server | `bin/docker/down` |
| Rails console | `bin/docker/console` |
| Run tests | `bin/docker/test` |
| Run migrations | `bin/docker/migrate` |
| Generate model | `bin/docker/generate model Name` |
| View logs | `bin/docker/logs -f` |
| Shell access | `bin/docker/bash` |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
| Lint code | `bin/docker/lint` |
| Full setup | `bin/docker/setup` |

