import requests

def fetch_weather_data(latitude, longitude):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&minutely_15=precipitation,weathercode"
    
    response = requests.get(url)
    if response.status_code == 200:
        return response.json()  # Return raw JSON data
    else:
        print(f"Error: Received status code {response.status_code}")
        print(f"Response content: {response.text}")
        return None