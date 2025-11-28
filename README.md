# Rain-app


# Rain App 🌧️

A weather monitoring app that checks for rain in your area and sends notifications when rain is expected in the next 15 minutes.

## Features

- **Real-time Weather Monitoring**: Check current weather conditions based on your location
- **Rain Notifications**: Get notified when rain is expected in the next 15 minutes
- **Automatic Monitoring**: Toggle automatic weather checks every 15 minutes
- **Location-based**: Uses your device's GPS to get accurate local weather data
- **Weather Details**: Displays weather code, precipitation amount, and location coordinates

## Tech Stack

### Frontend (iOS)
- **SwiftUI**: Modern declarative UI framework
- **CoreLocation**: Location services for GPS coordinates
- **URLSession**: Network requests to backend API
- **UserNotifications**: Local push notifications

### Backend (Python)
- **FastAPI**: High-performance web framework
- **Open-Meteo API**: Weather data provider
- **Uvicorn**: ASGI server

