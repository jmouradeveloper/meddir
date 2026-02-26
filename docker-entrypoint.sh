#!/bin/bash
set -e

# Install gems if Gemfile exists
if [ -f Gemfile ]; then
  echo "Installing gems..."
  bundle install
fi

# Remove stale Rails server pid so the server can start (volume persists across restarts)
rm -f tmp/pids/server.pid

# Execute the main command
exec "$@"

