# MedDir

Personal medical document management system. Allows users to organize exams, reports, and health documents in folders categorized by medical specialty, with secure sharing functionality.

## Features

- **Full authentication**: Registration, login, and password recovery
- **Medical folders**: Organized by specialty (Cardiology, Neurology, Dermatology, etc.)
- **Document upload**: Support for PDF, images (JPEG, PNG, GIF, WebP), and DICOM
- **Secure sharing**: Links with configurable expiration and access limits
- **Subscription plans**: Free, Premium, and Enterprise with different limits
- **Internationalization**: Support for Portuguese (pt-BR) and English (en)
- **PWA**: Progressive Web App with offline support
- **Admin panel**: Subscription management

## Tech Stack

| Technology | Version/Description |
|------------|---------------------|
| Ruby | 4.0.0 |
| Rails | 8.1.2 |
| Database | SQLite3 |
| Frontend | Hotwire (Turbo + Stimulus) |
| CSS | Tailwind CSS |
| Components | ViewComponent |
| Background Jobs | Solid Queue |
| Cache | Solid Cache |
| WebSockets | Solid Cable |
| Deployment | Kamal |
| Containerization | Docker |

## Requirements

- Docker and Docker Compose

## Installation and Development

This project uses Docker for development. All commands should be executed via Docker scripts located in `bin/docker/`.

### Initial Setup

```bash
# Full setup (build + database)
bin/docker/setup
```

### Daily Commands

```bash
# Start development server
bin/docker/up

# Stop server
bin/docker/down

# View logs
bin/docker/logs -f

# Rails console
bin/docker/console

# Run tests
bin/docker/test

# Run migrations
bin/docker/migrate

# Lint and security checks
bin/docker/lint
```

### Full Reset

```bash
# Remove all data and recreate environment
bin/docker/reset
```

For complete Docker scripts documentation, see [docs/scripts/docker-scripts.md](docs/scripts/docker-scripts.md).

## Project Structure

```
app/
├── components/       # ViewComponents
├── controllers/      # Application controllers
├── models/          
│   ├── user.rb              # Users
│   ├── medical_folder.rb    # Medical folders
│   ├── document.rb          # Documents
│   ├── shareable_link.rb    # Sharing links
│   ├── plan.rb              # Subscription plans
│   └── subscription.rb      # User subscriptions
├── views/            # ERB templates
└── javascript/       # Stimulus controllers
```

## Subscription Plans

| Feature | Free | Premium | Enterprise |
|---------|------|---------|------------|
| Storage | 100 MB | 5 GB | Unlimited |
| Folders | 3 | 20 | Unlimited |
| Sharing | No | Yes | Yes |
| Active links | - | 10 | Unlimited |
| Accesses per link | - | 100 | Unlimited |

## Supported Medical Specialties

- General Practice
- Cardiology
- Dermatology
- Endocrinology
- Gastroenterology
- Neurology
- Oncology
- Ophthalmology
- Orthopedics
- Pediatrics
- Psychiatry
- Pulmonology
- Radiology
- Urology
- Gynecology
- Other

## Testing

```bash
# Run all tests
bin/docker/test

# Run specific test file
bin/docker/test test/models/user_test.rb

# Run test by line number
bin/docker/test test/models/user_test.rb:10
```

## Lint and Security

```bash
# Run all checks
bin/docker/lint

# Includes:
# - RuboCop (code style)
# - Brakeman (security vulnerabilities)
# - Bundler Audit (gem vulnerabilities)
```

## Deployment

This project uses [Kamal](https://kamal-deploy.org) for deployment. Configuration is in `config/deploy.yml`.

```bash
# Deploy to production
bin/kamal deploy
```

## License

Proprietary - JML Consultech
