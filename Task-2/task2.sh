#!/bin/bash

# Install Docker and Docker Compose if not already installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
else
    echo "Docker Compose is already installed."
fi

# Create a directory for the setup
mkdir redash_metabase_superset
cd redash_metabase_superset

# Create a docker-compose.yml file
cat > docker-compose.yml <<EOL
version: '3'
services:
  redash:
    image: redash/redash:latest
    ports:
      - 5000:5000
    environment:
      - REDASH_DATABASE_URL=postgresql://postgres@postgres/postgres
      - REDASH_REDIS_URL=redis://redis:6379/0
    depends_on:
      - postgres
      - redis

  metabase:
    image: metabase/metabase
    ports:
      - 3000:3000
    environment:
      - MB_DB_TYPE=postgres
      - MB_DB_DBNAME=metabase
      - MB_DB_PORT=5432
      - MB_DB_USER=metabase
      - MB_DB_PASS=metabase
      - MB_DB_HOST=postgres
    depends_on:
      - postgres

  superset:
    image: apache/superset
    ports:
      - 8088:8088
    environment:
      - SUPERSET_CONFIG=superset_config.py
      - SUPERSET_ADMIN_USERNAME=admin
      - SUPERSET_ADMIN_PASSWORD=admin
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:13.2
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres

  redis:
    image: redis:6.0-alpine
EOL

# Create a configuration file for Superset
cat > superset_config.py <<EOL
import os

REDIS_HOST = 'redis'
REDIS_PORT = 6379
EOL

# Start the containers
docker-compose up -d

echo "Redash, Metabase, and Superset are now running in Docker containers."