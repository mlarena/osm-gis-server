#!/bin/bash

# Script to install PostgreSQL 18, PostGIS 3.6, osm2pgsql and other utilities on Debian
# Based on official PostgreSQL APT repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions for printing messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run with root privileges (sudo)"
   exit 1
fi

print_message "Starting software installation..."

# Detect Debian version
DEBIAN_VERSION=$(lsb_release -cs)
print_message "Detected Debian version: $DEBIAN_VERSION"

# Add PostgreSQL official APT repository
print_message "Adding PostgreSQL official APT repository..."
apt install -y curl ca-certificates gnupg lsb-release
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt ${DEBIAN_VERSION}-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Update package list
print_message "Updating package lists..."
apt update

# Install PostgreSQL 18 and PostGIS 3.6
print_message "Installing PostgreSQL 18 and PostGIS 3.6..."
apt install -y postgresql-18 postgresql-18-postgis-3 postgresql-18-postgis-3-scripts

# Install additional utilities
print_message "Installing additional utilities..."
apt install -y osm2pgsql osmium-tool curl wget htop iotop sudo build-essential

# Install pg_config for extension management (if needed)
apt install -y postgresql-server-dev-18

# Set password for postgres user
print_message "Setting password for postgres user..."
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '12345678';"

# Create GIS database and extensions
print_message "Creating GIS database and extensions..."
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS gisdb;
CREATE DATABASE gisdb;
\c gisdb
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS address_standardizer;
EOF

echo ""
echo "================================================================================"
echo "                         INSTALLATION INFORMATION"
echo "================================================================================"

# Display PostgreSQL version
print_message "PostgreSQL version:"
sudo -u postgres psql --version

# Display PostGIS version
print_message "PostGIS version:"
sudo -u postgres psql -d gisdb -t -c "SELECT PostGIS_Version();" | xargs

# Display osm2pgsql version
print_message "osm2pgsql version:"
osm2pgsql --version 2>&1 | head -1

# Get installation directories from PostgreSQL
print_message "PostgreSQL installation directories (from database queries):"

# Data directory
print_message "Data directory:"
sudo -u postgres psql -d gisdb -t -c "SHOW data_directory;" | xargs

# Configuration file
print_message "Configuration file:"
sudo -u postgres psql -d gisdb -t -c "SHOW config_file;" | xargs

# HBA file
print_message "pg_hba.conf file:"
sudo -u postgres psql -d gisdb -t -c "SHOW hba_file;" | xargs

# Log directory
print_message "Log directory:"
LOGDIR=$(sudo -u postgres psql -d gisdb -t -c "SHOW log_directory;" | xargs)
DATADIR=$(sudo -u postgres psql -d gisdb -t -c "SHOW data_directory;" | xargs)
if [[ "$LOGDIR" != /* ]]; then
    echo "  $DATADIR/$LOGDIR"
else
    echo "  $LOGDIR"
fi

# Extensions directory
print_message "Extensions directory:"
SHAREDIR=$(sudo -u postgres psql -d gisdb -t -c "SELECT setting FROM pg_settings WHERE name = 'sharedir';" | xargs)
echo "  $SHAREDIR/extension/"

# Binary directory
print_message "Binary directory:"
BINDIR=$(sudo -u postgres psql -d gisdb -t -c "SELECT setting FROM pg_settings WHERE name = 'bindir';" | xargs)
if [ -n "$BINDIR" ]; then
    echo "  $BINDIR"
else
    which psql | sed 's|/bin/psql||' || echo "  /usr/lib/postgresql/18/bin/"
fi

# PostgreSQL service status
print_message "PostgreSQL service status:"
systemctl status postgresql --no-pager | grep "Active:" || true

echo ""
echo "================================================================================"
echo "                    INSTALLED EXTENSIONS IN DATABASE gisdb"
echo "================================================================================"
sudo -u postgres psql -d gisdb -c "\dx"
echo "================================================================================"

# Detailed PostGIS version
print_message "Detailed PostGIS version information:"
sudo -u postgres psql -d gisdb -c "SELECT PostGIS_full_version();"

echo ""
echo "================================================================================"
echo "                       POSTGRESQL RUNTIME PARAMETERS"
echo "================================================================================"
print_message "PostgreSQL runtime parameters:"
echo "  Port:"
sudo -u postgres psql -d gisdb -t -c "SHOW port;" | xargs
echo "  Max connections:"
sudo -u postgres psql -d gisdb -t -c "SHOW max_connections;" | xargs
echo "  Shared buffers:"
sudo -u postgres psql -d gisdb -t -c "SHOW shared_buffers;" | xargs
echo "  Server version:"
sudo -u postgres psql -d gisdb -t -c "SHOW server_version;" | xargs
echo "================================================================================"

print_message "Installation and configuration completed successfully!"
echo ""
print_message "Database connection information:"
echo "  Database name:             gisdb"
echo "  Username:                  postgres"
echo "  Password:                  12345678"
echo "  Connection command:        sudo -u postgres psql -d gisdb"
echo "  Or:                        psql -h localhost -U postgres -d gisdb"
echo ""
print_message "To connect to the database:"
echo "  sudo -u postgres psql -d gisdb"
echo ""
print_message "To check extensions manually:"
echo "  sudo -u postgres psql -d gisdb -c \"\\dx\""
echo ""

# Check installed utilities
print_message "Checking installed utilities:"
for tool in curl wget htop iotop osmium osm2pgsql; do
    if command -v $tool &> /dev/null; then
        echo "  ✓ $tool - installed"
    else
        echo "  ✗ $tool - NOT INSTALLED"
    fi
done

echo ""
print_message "PostGIS 3.6 New Features:"
echo "  ✓ Native Arrow Flight SQL support"
echo "  ✓ Parquet/GeoParquet export via COPY"
echo "  ✓ ST_FromFlatGeobuf() and ST_AsFlatGeobuf()"
echo "  ✓ Improved raster performance"
echo ""

echo "================================================================================"