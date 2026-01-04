#!/bin/bash
set -e

# Install gems if Gemfile exists
if [ -f Gemfile ]; then
  echo "Installing gems..."
  bundle install
fi

# Execute the main command
exec "$@"

