const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const axios = require("axios");

initializeApp();
const db = getFirestore();

// ════════════════════════════════════════════════════════════════
//  CONFIG — Replace with your real API keys before deploying
// ════════════════════════════════════════════════════════════════
const WAQI_TOKEN = process.env.WAQI_TOKEN || "YOUR_WAQI_TOKEN";
// Weather uses Open-Meteo (free, no API key needed)

const CITIES = [
  { name: "Lahore", waqi: "lahore", owm: "Lahore,PK", lat: 31.52, lon: 74.36 },
  { name: "Islamabad", waqi: "islamabad", owm: "Islamabad,PK", lat: 33.68, lon: 73.05 },
  { name: "Karachi", waqi: "karachi", owm: "Karachi,PK", lat: 24.86, lon: 67.00 },
  { name: "Faisalabad", waqi: "faisalabad", owm: "Faisalabad,PK", lat: 31.42, lon: 73.08 },
  { name: "Peshawar", waqi: "peshawar", owm: "Peshawar,PK", lat: 34.02, lon: 71.52 },
  { name: "Multan", waqi: "multan", owm: "Multan,PK", lat: 30.16, lon: 71.52 },
];

// ════════════════════════════════════════════════════════════════
//  FUNCTION 1: onAlertCreated
//  Sends push notification when a new alert is created in Firestore.
// ════════════════════════════════════════════════════════════════
exports.onAlertCreated = onDocumentCreated("alerts/{alertId}", async (event) => {
  const alert = event.data.data();
  if (!alert) return;

  const { title, description, severity, type, location } = alert;

  // Build smart notification text based on alert type and severity.
  const body = buildSmartNotificationText(alert);

  // Derive topic from type + city.
  const cityKey = (location || "lahore").toLowerCase().split(",")[0].trim().replace(/\s+/g, "_");
  const typeTopic = `${type || "general"}_${cityKey}`;

  // Send to type-specific topic.
  const message = {
    topic: typeTopic,
    notification: {
      title: title || "EcoAlert Warning",
      body: body,
    },
    data: {
      alertId: event.params.alertId,
      type: type || "general",
      severity: severity || "MEDIUM",
      location: location || "",
    },
    android: {
      priority: severity === "HIGH" ? "high" : "normal",
      notification: {
        channelId: "ecoalert_alerts",
        priority: severity === "HIGH" ? "max" : "high",
        defaultSound: true,
      },
    },
  };

  try {
    await getMessaging().send(message);
    console.log(`[FCM] Sent to topic: ${typeTopic}`);

    // Also send to global topic.
    await getMessaging().send({ ...message, topic: "all_alerts" });
    console.log("[FCM] Sent to all_alerts topic");
  } catch (err) {
    console.error("[FCM] Error sending notification:", err);
  }
});

// ════════════════════════════════════════════════════════════════
//  FUNCTION 2: onReportApproved
//  Sends a personal push when a user's report is approved.
// ════════════════════════════════════════════════════════════════
exports.onReportStatusChanged = onDocumentUpdated("reports/{reportId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  // Only trigger on status change to "approved".
  if (before.status === after.status || after.status !== "approved") return;

  const reporterUid = after.reporterUid;
  if (!reporterUid) return;

  // Get the reporter's FCM token.
  const tokenDoc = await db.collection("fcm_tokens").doc(reporterUid).get();
  if (!tokenDoc.exists) return;
  const token = tokenDoc.data().token;
  if (!token) return;

  try {
    await getMessaging().send({
      token: token,
      notification: {
        title: "Report Verified! ✅",
        body: `Your ${after.hazardType} report in ${after.locationLabel} has been verified by authorities.`,
      },
      data: {
        reportId: event.params.reportId,
        type: "report_approved",
      },
    });
    console.log(`[FCM] Sent approval notification to user ${reporterUid}`);
  } catch (err) {
    console.error("[FCM] Error sending approval notification:", err);
  }

  // Award gamification points.
  try {
    await db.collection("users").doc(reporterUid).update({
      points: FieldValue.increment(25),
      approvedReportCount: FieldValue.increment(1),
    });
    console.log(`[Gamification] Awarded 25 points to ${reporterUid}`);
  } catch (err) {
    console.error("[Gamification] Error awarding points:", err);
  }
});

// ════════════════════════════════════════════════════════════════
//  FUNCTION 3: scheduledAqiFetch
//  Fetches AQI data every 30 minutes for all cities → writes to Firestore.
//  Auto-creates alerts if AQI > 300.
// ════════════════════════════════════════════════════════════════
exports.scheduledAqiFetch = onSchedule("every 30 minutes", async () => {
  console.log("[AQI] Starting scheduled fetch...");

  for (const city of CITIES) {
    try {
      const url = `https://api.waqi.info/feed/${city.waqi}/?token=${WAQI_TOKEN}`;
      const response = await axios.get(url, { timeout: 10000 });

      if (response.data.status !== "ok") {
        console.warn(`[AQI] Bad response for ${city.name}`);
        continue;
      }

      const feed = response.data.data;
      const aqi = feed.aqi;
      const iaqi = feed.iaqi || {};

      const reading = {
        aqi: aqi,
        category: getAqiCategory(aqi),
        pm25: iaqi.pm25?.v || 0,
        pm10: iaqi.pm10?.v || 0,
        o3: iaqi.o3?.v || 0,
        no2: iaqi.no2?.v || 0,
        co: iaqi.co?.v || 0,
        timestamp: new Date().toISOString(),
        city: city.name,
        updatedAt: FieldValue.serverTimestamp(),
      };

      // Write latest reading.
      await db.collection("aqi_readings").doc(city.name.toLowerCase()).set(reading);

      // Append to hourly history.
      await db
        .collection("aqi_readings")
        .doc(city.name.toLowerCase())
        .collection("hourly")
        .add(reading);

      console.log(`[AQI] ${city.name}: AQI ${aqi}`);

      // Auto-create alert if AQI is hazardous (> 300).
      if (aqi > 300) {
        await db.collection("alerts").add({
          title: `Hazardous Air Quality in ${city.name}`,
          description: `AQI has reached ${aqi} (Hazardous). Avoid all outdoor activities. Wear N95 masks indoors near openings.`,
          severity: "HIGH",
          location: city.name,
          timestamp: new Date().toISOString(),
          type: "air_quality",
          actionText: `Stay indoors. AQI: ${aqi}. Use air purifiers if available.`,
          autoGenerated: true,
        });
        console.log(`[AQI] Auto-created alert for ${city.name} (AQI: ${aqi})`);
      }
    } catch (err) {
      console.error(`[AQI] Failed for ${city.name}:`, err.message);
    }
  }
});

// ════════════════════════════════════════════════════════════════
//  FUNCTION 4: scheduledWeatherFetch
//  Fetches weather data every 30 minutes → writes to Firestore.
//  Auto-creates flood alerts if risk is critical.
// ════════════════════════════════════════════════════════════════
exports.scheduledWeatherFetch = onSchedule("every 30 minutes", async () => {
  console.log("[Weather] Starting scheduled fetch...");

  const BASE_RISK = { Lahore: 20, Karachi: 25, Islamabad: 15, Faisalabad: 18, Peshawar: 28, Multan: 22 };

  for (const city of CITIES) {
    try {
      // Open-Meteo API — FREE, no API key needed.
      const meteoUrl = `https://api.open-meteo.com/v1/forecast?latitude=${city.lat}&longitude=${city.lon}&hourly=precipitation&current=precipitation&forecast_days=3&timezone=auto`;
      const meteoRes = await axios.get(meteoUrl, { timeout: 10000 });
      const meteoData = meteoRes.data;

      const mmPerHour = meteoData.current?.precipitation || 0;
      const hourlyPrecip = meteoData.hourly?.precipitation || [];

      let mm24h = 0;
      let mm48h = 0;
      for (let i = 0; i < hourlyPrecip.length && i < 72; i++) {
        const mm = hourlyPrecip[i] || 0;
        if (i < 24) mm24h += mm;
        if (i < 48) mm48h += mm;
      }

      // Calculate flood risk (same algorithm as Flutter FloodRiskCalculator).
      const baseRisk = BASE_RISK[city.name] || 15;
      let score = baseRisk;
      if (mm24h > 80) score += 35;
      else if (mm24h > 50) score += 25;
      else if (mm24h > 20) score += 15;

      if (mmPerHour > 15) score += 25;
      else if (mmPerHour > 8) score += 15;
      else if (mmPerHour > 3) score += 8;

      if (mm48h > 120) score += 10;
      else if (mm48h > 80) score += 7;
      else if (mm48h > 40) score += 3;

      score = Math.min(score, 100);

      const level = score >= 75 ? "critical" : score >= 50 ? "high" : score >= 25 ? "moderate" : "low";

      const weatherData = {
        mm24h, mmPerHour, mm48h,
        riskScore: score,
        level,
        city: city.name,
        timestamp: new Date().toISOString(),
        updatedAt: FieldValue.serverTimestamp(),
      };

      await db.collection("weather_data").doc(city.name.toLowerCase()).set(weatherData);
      console.log(`[Weather] ${city.name}: risk=${score} (${level})`);

      // Auto-create flood alert if critical.
      if (score >= 75) {
        await db.collection("alerts").add({
          title: `Flash Flood Risk: CRITICAL in ${city.name}`,
          description: `Flood risk score: ${score}/100. Rainfall: ${mm24h.toFixed(1)}mm in 24h, intensity: ${mmPerHour.toFixed(1)}mm/hr.`,
          severity: "HIGH",
          location: city.name,
          timestamp: new Date().toISOString(),
          type: "flood",
          actionText: `Avoid low-lying areas. Move to higher ground immediately.`,
          autoGenerated: true,
        });
        console.log(`[Weather] Auto-created flood alert for ${city.name}`);
      }
    } catch (err) {
      console.error(`[Weather] Failed for ${city.name}:`, err.message);
    }
  }
});

// ════════════════════════════════════════════════════════════════
//  HELPER FUNCTIONS
// ════════════════════════════════════════════════════════════════

function getAqiCategory(aqi) {
  if (aqi <= 50) return "good";
  if (aqi <= 100) return "moderate";
  if (aqi <= 150) return "sensitive";
  if (aqi <= 200) return "unhealthy";
  if (aqi <= 300) return "veryUnhealthy";
  return "hazardous";
}

/**
 * Build smart, context-aware notification text.
 */
function buildSmartNotificationText(alert) {
  const { type, severity, location, description } = alert;
  const hour = new Date().getHours();
  const isRushHour = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19);
  const timeContext = isRushHour ? "Rush hour advisory: " : "";

  switch (type) {
    case "air_quality": {
      const aqiMatch = (description || "").match(/(\d{3,})/);
      const aqiVal = aqiMatch ? aqiMatch[1] : "dangerously high";
      return `${timeContext}AQI hit ${aqiVal} in ${location}. Wear N95 if going outside. Keep windows closed.`;
    }
    case "flood":
      return `${timeContext}Flash flood risk is ${severity} near ${location}. Avoid low-lying areas and canal routes. Stay on higher ground.`;
    case "cloudburst":
      return `${timeContext}Sudden heavy rainfall expected in ${location}. Seek shelter immediately. Avoid underpasses.`;
    case "heatwave":
      return `${timeContext}Extreme heat warning for ${location}. Stay hydrated. Avoid direct sun exposure between 11am-4pm.`;
    default:
      return description || `${severity} alert for ${location}. Stay safe and follow official guidance.`;
  }
}
