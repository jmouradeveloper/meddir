# Docker Development Scripts

This project uses Docker Compose for development. All scripts are located in `bin/docker/` and provide convenient wrappers for common development tasks.

## Quick Start

```bash
# First time setup
bin/docker/setup

# Start the development server
bin/docker/up

# Stop the server
bin/docker/down
```

---

## Container Management

### `bin/docker/up`

Start the development environment.

```bash
# Start in foreground (see logs)
bin/docker/up

# Start in detached mode (background)
bin/docker/up -d
```

### `bin/docker/down`

Stop the development environment.

```bash
# Stop containers
bin/docker/down

# Stop and remove volumes (WARNING: deletes database data)
bin/docker/down -v
```

### `bin/docker/build`

Rebuild the Docker image. Use this after changing `Dockerfile.dev` or system dependencies.

```bash
# Rebuild image
bin/docker/build

# Rebuild without cache
bin/docker/build --no-cache
```

### `bin/docker/logs`

View container logs.

```bash
# View recent logs
bin/docker/logs

# Follow logs in real-time
bin/docker/logs -f

# Show last 100 lines and follow
bin/docker/logs -f --tail=100
```

### `bin/docker/setup`

Full setup from scratch. This script:
1. Builds the Docker image
2. Starts containers in detached mode
3. Runs `db:prepare` to set up the database

```bash
bin/docker/setup
```

### `bin/docker/reset`

Reset the entire development environment. This will:
1. Stop all containers
2. Remove all volumes (including database data)
3. Rebuild the image
4. Start fresh containers
5. Set up the database

**Warning**: This deletes all local data. You will be prompted for confirmation.

```bash
bin/docker/reset
```

---

## Rails Commands

### `bin/docker/console`

Open the Rails console inside the container.

```bash
bin/docker/console

# With sandbox mode (changes are rolled back)
bin/docker/console --sandbox
```

### `bin/docker/rails`

Run any Rails command inside the container.

```bash
# View routes
bin/docker/rails routes

# View routes for a specific controller
bin/docker/rails routes -c users

# Run a specific task
bin/docker/rails about

# Credentials
bin/docker/rails credentials:edit
```

### `bin/docker/rake`

Run Rake tasks inside the container.

```bash
# List all tasks
bin/docker/rake -T

# Run a specific task
bin/docker/rake assets:precompile
```

### `bin/docker/generate`

Run Rails generators.

```bash
# Generate a model
bin/docker/generate model User name:string email:string

# Generate a controller
bin/docker/generate controller Products index show

# Generate a migration
bin/docker/generate migration AddStatusToOrders status:integer

# Generate a scaffold
bin/docker/generate scaffold Product name:string price:decimal
```

### `bin/docker/test`

Run the test suite.

```bash
# Run all tests
bin/docker/test

# Run a specific test file
bin/docker/test test/models/user_test.rb

# Run a specific test by line number
bin/docker/test test/models/user_test.rb:10

# Run tests matching a pattern
bin/docker/test -n /user_can_login/
```

---

## Database

### `bin/docker/migrate`

Run pending database migrations.

```bash
bin/docker/migrate
```

### `bin/docker/db`

Database management with subcommands.

```bash
# Open database console (sqlite3, psql, mysql, etc.)
bin/docker/db console

# Run pending migrations
bin/docker/db migrate

# Rollback last migration
bin/docker/db rollback

# Rollback multiple migrations
bin/docker/db rollback STEP=3

# Run database seeds
bin/docker/db seed

# Reset database (drop, create, migrate, seed)
bin/docker/db reset

# Create and migrate (or just migrate if exists)
bin/docker/db prepare

# Show migration status
bin/docker/db status
```

---

## Utilities

### `bin/docker/bash`

Open a bash shell inside the container for debugging or running arbitrary commands.

```bash
bin/docker/bash
```

### `bin/docker/exec`

Execute any command inside the container.

```bash
# List files
bin/docker/exec ls -la

# Check Ruby version
bin/docker/exec ruby -v

# Run a Ruby script
bin/docker/exec ruby script.rb
```

### `bin/docker/bundle`

Run Bundler commands.

```bash
# Install gems
bin/docker/bundle install

# Add a new gem
bin/docker/bundle add devise

# Update all gems
bin/docker/bundle update

# Update a specific gem
bin/docker/bundle update rails

# Show outdated gems
bin/docker/bundle outdated
```

### `bin/docker/lint`

Run code quality and security checks.

```bash
# Run all checks (RuboCop, Brakeman, Bundle Audit)
bin/docker/lint

# Run only RuboCop
bin/docker/lint --rubocop-only

# Auto-correct RuboCop offenses
bin/docker/lint -a
```

---

## Tips

### Running Containers in Background

Start containers in detached mode and use `logs` to view output:

```bash
bin/docker/up -d
bin/docker/logs -f
```

### Debugging

If something isn't working, try:

```bash
# Check container status
docker compose ps

# View logs
bin/docker/logs -f

# Open a shell to investigate
bin/docker/bash
```

### Gem Installation Issues

If gems aren't installing correctly:

```bash
# Force reinstall all gems
bin/docker/bundle install --redownload

# Or reset the bundle cache volume
bin/docker/down -v
bin/docker/up
```

### Database Issues

If the database is in a bad state:

```bash
# Check migration status
bin/docker/db status

# Reset everything
bin/docker/db reset
```

