from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.client import fetch_weather_data
from services.processor import extract_info


app = FastAPI()

# Allow requests from your simulator (or localhost)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/weather")
def get_weather(latitude: float, longitude: float):
    data = fetch_weather_data("40.7128", "-74.0060")  # New York City coordinates
    if data is None:
        print("No precipitation data available.")
        return
    results = extract_info(data)
    print("Extracted Information:")
    print(results)
    return results
