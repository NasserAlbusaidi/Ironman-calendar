# Ironman Training Dashboard

An advanced, opinionated dashboard for the serious Ironman athlete. This Flutter-based application is designed to be a single source of truth for your race preparation, integrating your training plan, real-world activities, and crucial race logistics into one high-contrast, data-rich interface.

## Features

- **Race Countdown:** A prominent countdown timer keeps your primary goal front and center.
- **Dynamic Entropy Blur:** The background image sharpens as the race day approaches, creating a psychological focusing effect.
- **Confidence Bank:** At-a-glance visualization of your total training volume (Swim, Bike, Run) to build confidence in your preparation.
- **Training Plan Integration:** Ingests your structured training plan from Intervals.icu (via iCalendar link).
- **Strava Integration:** Pulls your actual workout data from Strava to compare against your plan.
- **Compliance & Debt Tracking:** Automatically calculates "training debt" in minutes when you miss or fall short on planned workouts. A "Panic Button" allows you to either accept the deficit or reset your debt for a fresh start.
- **Race Day Predictor:** Simulates your race day finish time based on your current average paces for each discipline.
- **Build & Taper Chart:** A line chart that visualizes your training volume over time, showing your build and taper phases.
- **Logistics Protocol:** A checklist of critical race-week and pre-race tasks (e.g., booking hotels, bike tune-ups) that automatically appear as the race gets closer.

## Getting Started

### Prerequisites

- Flutter SDK installed.
- An `.env` file in the root of the project with your Strava and Intervals.icu credentials.

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/ironman-dashboard.git
   cd ironman-dashboard
   ```

2. **Create the `.env` file:**
   In the root of the project, create a file named `.env` and add the following:

   ```
   STRAVA_CLIENT_ID=your_strava_client_id
   STRAVA_CLIENT_SECRET=your_strava_client_secret
   STRAVA_REFRESH_TOKEN=your_strava_refresh_token
   ```

   *Note: You will need to go through the Strava API authentication flow once to get your initial refresh token.*

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## Configuration

- **Race Date:** To set your race date, modify the `raceDate` final variable in `lib/main.dart`.
- **Training Plan:** To use your own training plan, replace the `calendarUrl` in `lib/services/plan_service.dart` with your own iCalendar link from a service like Intervals.icu.

## Project Structure

- `lib/main.dart`: The main entry point of the application and the primary UI for the dashboard.
- `lib/logic/`: Contains the business logic for processing and merging training data.
  - `compliance_engine.dart`: Merges the training plan with actual workouts and calculates compliance.
- `lib/services/`: Contains services for interacting with external APIs and data sources.
  - `plan_service.dart`: Fetches and parses the training plan from an iCalendar feed.
  - `strava_service.dart`: Handles authentication and data fetching from the Strava API.
  - `logistics_service.dart`: Manages the race logistics checklist.
- `lib/widgets/`: Contains reusable UI components.
  - `taper_chart.dart`: The line chart for visualizing training volume.
  - `predictor_card.dart`: The card that displays the race day simulation.
- `lib/screens/`: Contains screen-level widgets.
  - `dashboard.dart`: **DEPRECATED.** The old dashboard UI, now merged into `main.dart`.
