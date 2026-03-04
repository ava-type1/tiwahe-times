#!/bin/bash
# fetch-weather.sh — Fetch weather data for Fort White, FL
# Uses Open-Meteo API (free, no key required)
# Run daily via cron: 0 6 * * * /path/to/fetch-weather.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../data"
OUTPUT="$DATA_DIR/weather.json"

# Fort White, FL coordinates
LAT=29.9219
LON=-82.7140

# Fetch from Open-Meteo
RESPONSE=$(curl -s --max-time 15 "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,uv_index&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America/New_York&forecast_days=5")

if [ -z "$RESPONSE" ]; then
    echo "Error: Empty response from API"
    exit 1
fi

# Map WMO weather codes to conditions and icons
weather_info() {
    local code=$1
    case $code in
        0) echo "Clear Sky|☀️" ;;
        1) echo "Mainly Clear|🌤️" ;;
        2) echo "Partly Cloudy|⛅" ;;
        3) echo "Overcast|☁️" ;;
        45|48) echo "Foggy|🌫️" ;;
        51|53|55) echo "Drizzle|🌦️" ;;
        61|63|65) echo "Rain|🌧️" ;;
        71|73|75) echo "Snow|❄️" ;;
        80|81|82) echo "Rain Showers|🌦️" ;;
        95) echo "Thunderstorm|⛈️" ;;
        96|99) echo "Thunderstorm w/ Hail|⛈️" ;;
        *) echo "Unknown|❓" ;;
    esac
}

# Parse current conditions
CURRENT_TEMP=$(echo "$RESPONSE" | jq '.current.temperature_2m | round')
CURRENT_FEELS=$(echo "$RESPONSE" | jq '.current.apparent_temperature | round')
CURRENT_HUMIDITY=$(echo "$RESPONSE" | jq '.current.relative_humidity_2m')
CURRENT_WIND_SPEED=$(echo "$RESPONSE" | jq '.current.wind_speed_10m | round')
CURRENT_UV=$(echo "$RESPONSE" | jq '.current.uv_index | round')
CURRENT_CODE=$(echo "$RESPONSE" | jq '.current.weather_code')

CURRENT_INFO=$(weather_info "$CURRENT_CODE")
CURRENT_CONDITION=$(echo "$CURRENT_INFO" | cut -d'|' -f1)
CURRENT_ICON=$(echo "$CURRENT_INFO" | cut -d'|' -f2)

# Get today's rain chance
TODAY_RAIN=$(echo "$RESPONSE" | jq '.daily.precipitation_probability_max[0]')

# Build forecast array
DAYS=("$(date +%a)" "$(date -d '+1 day' +%a)" "$(date -d '+2 days' +%a)" "$(date -d '+3 days' +%a)" "$(date -d '+4 days' +%a)")
DATES=("$(date '+%b %d')" "$(date -d '+1 day' '+%b %d')" "$(date -d '+2 days' '+%b %d')" "$(date -d '+3 days' '+%b %d')" "$(date -d '+4 days' '+%b %d')")

FORECAST="["
for i in 0 1 2 3 4; do
    HIGH=$(echo "$RESPONSE" | jq ".daily.temperature_2m_max[$i] | round")
    LOW=$(echo "$RESPONSE" | jq ".daily.temperature_2m_min[$i] | round")
    CODE=$(echo "$RESPONSE" | jq ".daily.weather_code[$i]")
    RAIN=$(echo "$RESPONSE" | jq ".daily.precipitation_probability_max[$i]")
    
    INFO=$(weather_info "$CODE")
    CONDITION=$(echo "$INFO" | cut -d'|' -f1)
    ICON=$(echo "$INFO" | cut -d'|' -f2)
    
    [ $i -gt 0 ] && FORECAST+=","
    FORECAST+=$(cat <<EOF
    {
      "day": "${DAYS[$i]}",
      "date": "${DATES[$i]}",
      "high": $HIGH,
      "low": $LOW,
      "condition": "$CONDITION",
      "icon": "$ICON",
      "chanceOfRain": $RAIN
    }
EOF
)
done
FORECAST+="]"

# Write final JSON
cat > "$OUTPUT" <<EOF
{
  "location": "Fort White, FL",
  "updated": "$(date -Iseconds)",
  "current": {
    "temp": $CURRENT_TEMP,
    "feelsLike": $CURRENT_FEELS,
    "condition": "$CURRENT_CONDITION",
    "icon": "$CURRENT_ICON",
    "humidity": $CURRENT_HUMIDITY,
    "wind": "$CURRENT_WIND_SPEED mph",
    "uvIndex": $CURRENT_UV,
    "chanceOfRain": $TODAY_RAIN
  },
  "forecast": $FORECAST
}
EOF

echo "Weather data written to $OUTPUT"
