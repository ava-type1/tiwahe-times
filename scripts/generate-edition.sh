#!/bin/bash
# generate-edition.sh — Daily edition generator for The Tiwahe Times
# Run daily via cron: 0 6 * * * /path/to/generate-edition.sh
#
# This script orchestrates all data fetching for a new daily edition.
# In production, each section would have its own scraper/fetcher.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
DATA_DIR="$PROJECT_DIR/data"

echo "========================================="
echo " The Tiwahe Times — Daily Edition Builder"
echo " $(date '+%A, %B %d, %Y')"
echo "========================================="

# Step 1: Fetch weather
echo ""
echo "[1/5] Fetching weather data..."
bash "$SCRIPT_DIR/fetch-weather.sh" && echo "  ✓ Weather updated" || echo "  ✗ Weather fetch failed"

# Step 2: Fetch news stories
echo ""
echo "[2/5] Fetching local news..."
echo "  → TODO: Scrape Lake City Reporter RSS"
echo "  → TODO: Scrape Gainesville Sun local section"
echo "  → TODO: Check Columbia County government site"
echo "  ⚠ Using existing stories.json (manual update needed)"

# Step 3: Fetch community events
echo ""
echo "[3/5] Updating community events..."
echo "  → TODO: Scrape Columbia County events calendar"
echo "  → TODO: Check Fort White community Facebook groups"
echo "  → TODO: Pull from local church calendars"
echo "  ⚠ Using existing events.json (manual update needed)"

# Step 4: Update sports
echo ""
echo "[4/5] Updating sports data..."
echo "  → TODO: Scrape MaxPreps for Fort White Indians scores"
echo "  → TODO: Check FHSAA schedule"
echo "  ⚠ Using existing sports.json (manual update needed)"

# Step 5: Government notices
echo ""
echo "[5/5] Checking government notices..."
echo "  → TODO: Scrape Columbia County BCC agenda"
echo "  → TODO: Check FDOT road work notices"
echo "  ⚠ Using existing government.json (manual update needed)"

echo ""
echo "========================================="
echo " Edition build complete!"
echo " Deploy with:"
echo "   cd $PROJECT_DIR && npx wrangler pages deploy . --project-name tiwahe-times"
echo "========================================="
