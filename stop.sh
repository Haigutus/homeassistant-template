#!/bin/bash

# Exit on any error
set -e

echo "Stopping Home Assistant and other services..."

docker-compose down

echo "Services stopped."
