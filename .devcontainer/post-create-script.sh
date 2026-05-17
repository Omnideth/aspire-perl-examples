#!/usr/bin/env bash
set -e

echo "Installing system dependencies..."
sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends perl cpanminus libpq-dev build-essential socat bubblewrap && \
    sudo apt-get clean -y && \
    sudo rm -rf /var/lib/apt/lists/*

echo "Installing Aspire CLI..."
curl -sSL https://aspire.dev/install.sh | bash

echo "Updating Aspire to latest stable version..."


echo "Done!"