rain_codes = {
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    61: "Slight rain",
    82: "Rain showers (violent)"
}

def extract_info(data):
    try:
        next_15_precip = data["minutely_15"]["precipitation"][0]
        next_15_code = data["minutely_15"]["weathercode"][0]
        
        if next_15_precip != 0:
            weather_code = rain_codes.get(next_15_code, "Unknown weather code")
            return {
                "raining": True,
                "weather_code": weather_code,
                "precipitation": next_15_precip
            }
        else:
            return {
                "raining": False,
                "weather_code": "No precipitation",
                "precipitation": 0
            }
    except KeyError as e:
        print(f"Error processing data: Missing key {e}")
        return None