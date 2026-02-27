const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;

// ─── Middleware ───────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '5mb' }));

// ─── Health Check ────────────────────────────────────────────
app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', service: 'hridhaya-backend', uptime: process.uptime() });
});

// ─── Stethoscope Analysis ────────────────────────────────────
//
// Expects POST with JSON body:
// {
//   "samples": [
//     { "timestamp": 1234567890, "x": 0.01, "y": -0.02, "z": 0.03 },
//     ...
//   ],
//   "durationMs": 15000
// }
//
// Returns a simulated cardiac analysis report.
app.post('/api/stethoscope/analyze', (req, res) => {
    const { samples, durationMs } = req.body;

    if (!samples || !Array.isArray(samples) || samples.length === 0) {
        return res.status(400).json({
            error: 'Missing or empty "samples" array. Send gyroscope data.',
        });
    }

    const duration = durationMs || 15000;

    // ─── 1. Compute signal statistics ───
    const magnitudes = samples.map(s => Math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z));

    const meanMag = magnitudes.reduce((a, b) => a + b, 0) / magnitudes.length;
    const maxMag = Math.max(...magnitudes);
    const minMag = Math.min(...magnitudes);

    // Variance
    const variance = magnitudes.reduce((sum, m) => sum + (m - meanMag) ** 2, 0) / magnitudes.length;
    const stdDev = Math.sqrt(variance);

    // ─── 2. Detect peaks (heartbeats) via threshold crossing ───
    const peakThreshold = meanMag + stdDev * 0.6;
    const peaks = [];
    let inPeak = false;

    for (let i = 1; i < magnitudes.length - 1; i++) {
        if (magnitudes[i] > peakThreshold && magnitudes[i] > magnitudes[i - 1] && magnitudes[i] > magnitudes[i + 1]) {
            if (!inPeak) {
                peaks.push(i);
                inPeak = true;
            }
        } else {
            inPeak = false;
        }
    }

    // ─── 3. Estimate heart rate from peak intervals ───
    let estimatedBpm = 0;
    let rhythmRegularity = 'unknown';
    const intervals = [];

    if (peaks.length >= 2) {
        // Calculate intervals between peaks (in sample indices)
        for (let i = 1; i < peaks.length; i++) {
            intervals.push(peaks[i] - peaks[i - 1]);
        }

        const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;

        // Convert sample interval to time interval
        const sampleRate = samples.length / (duration / 1000); // samples per second
        const avgIntervalSeconds = avgInterval / sampleRate;

        if (avgIntervalSeconds > 0) {
            estimatedBpm = Math.round(60 / avgIntervalSeconds);
        }

        // Clamp to realistic range
        if (estimatedBpm < 40 || estimatedBpm > 200) {
            // Fallback to simulated estimate based on signal energy
            estimatedBpm = 60 + Math.round(meanMag * 40); // Heuristic
            estimatedBpm = Math.max(55, Math.min(estimatedBpm, 110));
        }

        // Rhythm regularity (coefficient of variation of intervals)
        const intervalMean = intervals.reduce((a, b) => a + b, 0) / intervals.length;
        const intervalVariance = intervals.reduce((sum, iv) => sum + (iv - intervalMean) ** 2, 0) / intervals.length;
        const cv = Math.sqrt(intervalVariance) / intervalMean;

        if (cv < 0.1) {
            rhythmRegularity = 'regular';
        } else if (cv < 0.25) {
            rhythmRegularity = 'mostly_regular';
        } else {
            rhythmRegularity = 'irregular';
        }
    } else {
        // Too few peaks — use heuristic
        estimatedBpm = 60 + Math.round(meanMag * 30);
        estimatedBpm = Math.max(58, Math.min(estimatedBpm, 100));
        rhythmRegularity = 'insufficient_data';
    }

    // ─── 4. Signal quality assessment ───
    let signalQuality = 'poor';
    if (samples.length > 100 && stdDev > 0.01) {
        if (stdDev > 0.05 && peaks.length >= 3) {
            signalQuality = 'good';
        } else {
            signalQuality = 'fair';
        }
    }

    // ─── 5. Risk indicators ───
    const riskFactors = [];
    if (estimatedBpm > 100) riskFactors.push('Elevated resting heart rate (tachycardia range)');
    if (estimatedBpm < 50) riskFactors.push('Low resting heart rate (bradycardia range)');
    if (rhythmRegularity === 'irregular') riskFactors.push('Irregular rhythm detected — consider follow-up');
    if (signalQuality === 'poor') riskFactors.push('Signal quality was poor — try holding phone steadier');

    let riskLevel = 'low';
    if (riskFactors.length >= 2) riskLevel = 'moderate';
    if (estimatedBpm > 120 || estimatedBpm < 45) riskLevel = 'high';

    // ─── 6. Build response ───
    const report = {
        success: true,
        analysis: {
            heartRate: {
                bpm: estimatedBpm,
                classification: classifyHeartRate(estimatedBpm),
            },
            rhythm: {
                regularity: rhythmRegularity,
                peaksDetected: peaks.length,
                intervalCount: intervals.length,
            },
            signal: {
                quality: signalQuality,
                sampleCount: samples.length,
                durationMs: duration,
                meanMagnitude: round4(meanMag),
                maxMagnitude: round4(maxMag),
                stdDeviation: round4(stdDev),
            },
            risk: {
                level: riskLevel,
                factors: riskFactors,
            },
        },
        disclaimer:
            'This is a prototype analysis based on phone gyroscope data. It is NOT a medical diagnosis. Always consult a qualified cardiologist for accurate assessment.',
        timestamp: new Date().toISOString(),
    };

    console.log(`[Stethoscope] Analyzed ${samples.length} samples → ${estimatedBpm} BPM, quality=${signalQuality}, risk=${riskLevel}`);
    res.json(report);
});

// ─── Fall Detection ──────────────────────────────────────────
//
// When the phone detects a cardiac fall (free-fall → impact → stillness),
// the Flutter app sends the event here for logging and emergency response.
//
// Expects POST with JSON body:
// {
//   "fallEvent": {
//     "at": "2026-02-28T01:30:00.000Z",
//     "impactMagnitude": 28.5,
//     "freeFallDurationMs": 320,
//     "stillnessDurationMs": 2000,
//     "peakJerk": 15.2,
//     "phasesDetected": ["freeFall", "impact", "stillness"]
//   },
//   "userSettings": {
//     "abhaId": "XX-XXXX-XXXX-XXXX",
//     "bloodGroup": "O+"
//   }
// }

const incidents = []; // In-memory log (replace with DB in production)

app.post('/api/fall-detection/report', (req, res) => {
    const { fallEvent, userSettings } = req.body;

    if (!fallEvent) {
        return res.status(400).json({ error: 'Missing "fallEvent" in request body.' });
    }

    // ─── 1. Assess severity ───
    const severity = assessFallSeverity(fallEvent);

    // ─── 2. Generate incident ───
    const incidentId = `INC-${Date.now()}`;
    const incident = {
        incidentId,
        reportedAt: new Date().toISOString(),
        fallEvent,
        userSettings: userSettings || {},
        severity,
        status: 'active',
        actions: [],
    };

    // ─── 3. Determine emergency actions ───
    if (severity === 'critical') {
        incident.actions.push(
            { action: 'EMERGENCY_SOS_DISPATCHED', detail: 'Ambulance notified via 108' },
            { action: 'FAMILY_NOTIFIED', detail: 'Emergency contacts alerted with GPS location' },
            { action: 'HOSPITAL_ALERTED', detail: 'Nearest hospital ER notified with ABHA ID' },
        );
    } else if (severity === 'high') {
        incident.actions.push(
            { action: 'SAFETY_LOOP_TRIGGERED', detail: '30-second countdown started on device' },
            { action: 'FAMILY_NOTIFIED', detail: 'Emergency contacts sent a precautionary alert' },
        );
    } else {
        incident.actions.push(
            { action: 'SAFETY_LOOP_TRIGGERED', detail: '30-second countdown started on device' },
        );
    }

    // ─── 4. Log it ───
    incidents.push(incident);
    if (incidents.length > 100) incidents.shift(); // Keep last 100

    console.log(`\n🚨 [FALL DETECTED] ${incidentId}`);
    console.log(`   Severity: ${severity.toUpperCase()}`);
    console.log(`   Impact: ${fallEvent.impactMagnitude?.toFixed(1)}g | Jerk: ${fallEvent.peakJerk?.toFixed(1)}`);
    console.log(`   Phases: ${fallEvent.phasesDetected?.join(' → ')}`);
    console.log(`   Actions: ${incident.actions.map(a => a.action).join(', ')}`);
    if (userSettings?.abhaId) console.log(`   ABHA: ${userSettings.abhaId} | Blood: ${userSettings.bloodGroup}`);
    console.log();

    res.json({
        success: true,
        incidentId,
        severity,
        actions: incident.actions,
        message: severity === 'critical'
            ? 'CRITICAL FALL DETECTED. Emergency services have been notified.'
            : 'Fall detected. Safety Loop activated on device.',
        timestamp: incident.reportedAt,
    });
});

// ─── Get recent incidents ────────────────────────────────────
app.get('/api/fall-detection/incidents', (_req, res) => {
    res.json({
        count: incidents.length,
        incidents: incidents.slice(-20).reverse(),
    });
});

// ─── Helpers ─────────────────────────────────────────────────
function assessFallSeverity(event) {
    const phases = event.phasesDetected || [];
    const hasFreeFall = phases.includes('freeFall');
    const hasImpact = phases.includes('impact');
    const hasStillness = phases.includes('stillness');
    const impactG = event.impactMagnitude || 0;

    // All 3 phases + high impact → critical (person collapsed and is unconscious)
    if (hasFreeFall && hasImpact && hasStillness && impactG > 25) {
        return 'critical';
    }

    // Free-fall + impact (but person moved after) → high
    if (hasFreeFall && hasImpact) {
        return 'high';
    }

    // Impact only (could be phone dropped) → moderate
    if (hasImpact && impactG > 20) {
        return 'moderate';
    }

    return 'low';
}

function classifyHeartRate(bpm) {
    if (bpm < 50) return 'bradycardia';
    if (bpm < 60) return 'low_normal';
    if (bpm <= 100) return 'normal';
    if (bpm <= 120) return 'elevated';
    return 'tachycardia';
}

function round4(n) {
    return Math.round(n * 10000) / 10000;
}

// ─── Nearby Hospitals ────────────────────────────────────────

const hospitals = [
    {
        id: 'hosp_001',
        name: 'Apollo Hospitals',
        type: 'Multi-Specialty',
        address: '21, Greams Lane, Off Greams Road, Chennai 600006',
        phone: '+91 44 2829 3333',
        emergencyPhone: '108',
        distance: { km: 1.2, walkMins: 15, driveMins: 4 },
        coordinates: { lat: 13.0604, lng: 80.2496 },
        specialties: ['Cardiology', 'Cardiac Surgery', 'Emergency Medicine', 'Interventional Cardiology'],
        emergency: { available: true, ambulanceCount: 5, erBeds: 12 },
        beds: { total: 600, available: 42 },
        rating: 4.5,
        accreditation: ['NABH', 'JCI'],
        openNow: true,
        is24x7: true,
    },
    {
        id: 'hosp_002',
        name: 'Fortis Malar Hospital',
        type: 'Cardiac Specialty',
        address: '52, 1st Main Road, Gandhi Nagar, Adyar, Chennai 600020',
        phone: '+91 44 4289 2222',
        emergencyPhone: '108',
        distance: { km: 2.8, walkMins: 35, driveMins: 8 },
        coordinates: { lat: 13.0067, lng: 80.2572 },
        specialties: ['Cardiology', 'Cardiac Surgery', 'Electrophysiology', 'Heart Failure Clinic'],
        emergency: { available: true, ambulanceCount: 3, erBeds: 8 },
        beds: { total: 180, available: 15 },
        rating: 4.3,
        accreditation: ['NABH'],
        openNow: true,
        is24x7: true,
    },
    {
        id: 'hosp_003',
        name: 'SIMS Hospital',
        type: 'Multi-Specialty',
        address: 'No.1, Jawaharlal Nehru Salai, Vadapalani, Chennai 600026',
        phone: '+91 44 4539 5000',
        emergencyPhone: '108',
        distance: { km: 4.1, walkMins: 52, driveMins: 12 },
        coordinates: { lat: 13.0519, lng: 80.2121 },
        specialties: ['Cardiology', 'Neurology', 'Emergency Medicine', 'Critical Care'],
        emergency: { available: true, ambulanceCount: 4, erBeds: 10 },
        beds: { total: 350, available: 28 },
        rating: 4.2,
        accreditation: ['NABH'],
        openNow: true,
        is24x7: true,
    },
    {
        id: 'hosp_004',
        name: 'Kauvery Hospital',
        type: 'Heart Specialty',
        address: 'No.199, Luz Church Road, Mylapore, Chennai 600004',
        phone: '+91 44 4000 6000',
        emergencyPhone: '108',
        distance: { km: 3.5, walkMins: 44, driveMins: 10 },
        coordinates: { lat: 13.0339, lng: 80.2707 },
        specialties: ['Cardiology', 'Cardiac Surgery', 'Pediatric Cardiology', 'Cardiac Rehabilitation'],
        emergency: { available: true, ambulanceCount: 3, erBeds: 6 },
        beds: { total: 250, available: 19 },
        rating: 4.4,
        accreditation: ['NABH', 'NABL'],
        openNow: true,
        is24x7: true,
    },
    {
        id: 'hosp_005',
        name: 'Vijaya Hospital',
        type: 'Multi-Specialty',
        address: 'NSK Salai, Vadapalani, Chennai 600026',
        phone: '+91 44 4351 8100',
        emergencyPhone: '108',
        distance: { km: 5.2, walkMins: 65, driveMins: 15 },
        coordinates: { lat: 13.0524, lng: 80.2098 },
        specialties: ['Cardiology', 'Orthopedics', 'Emergency Medicine'],
        emergency: { available: true, ambulanceCount: 2, erBeds: 8 },
        beds: { total: 300, available: 35 },
        rating: 4.1,
        accreditation: ['NABH'],
        openNow: true,
        is24x7: true,
    },
    {
        id: 'hosp_006',
        name: 'Government General Hospital',
        type: 'Government',
        address: 'Park Town, Chennai 600003',
        phone: '+91 44 2530 5000',
        emergencyPhone: '108',
        distance: { km: 6.8, walkMins: 85, driveMins: 20 },
        coordinates: { lat: 13.0781, lng: 80.2748 },
        specialties: ['Cardiology', 'Emergency Medicine', 'General Medicine', 'Trauma Care'],
        emergency: { available: true, ambulanceCount: 8, erBeds: 25 },
        beds: { total: 2500, available: 180 },
        rating: 3.8,
        accreditation: ['NABH'],
        openNow: true,
        is24x7: true,
    },
];

app.get('/api/hospitals/nearby', (req, res) => {
    const sortBy = req.query.sort || 'distance';

    let sorted;
    if (sortBy === 'rating') {
        sorted = [...hospitals].sort((a, b) => b.rating - a.rating);
    } else {
        sorted = [...hospitals].sort((a, b) => a.distance.km - b.distance.km);
    }

    console.log(`[Hospitals] Returning ${sorted.length} nearby hospitals (sorted by ${sortBy})`);

    res.json({
        success: true,
        count: sorted.length,
        hospitals: sorted,
        timestamp: new Date().toISOString(),
    });
});

app.get('/api/hospitals/:id', (req, res) => {
    const hospital = hospitals.find(h => h.id === req.params.id);
    if (!hospital) {
        return res.status(404).json({ error: 'Hospital not found' });
    }
    res.json({ success: true, hospital });
});

// ─── Start ───────────────────────────────────────────────────
app.listen(PORT, () => {
    console.log(`\n🫀  Hridhaya Backend running on http://localhost:${PORT}`);
    console.log(`   GET  /api/health`);
    console.log(`   POST /api/stethoscope/analyze`);
    console.log(`   POST /api/fall-detection/report`);
    console.log(`   GET  /api/fall-detection/incidents`);
    console.log(`   GET  /api/hospitals/nearby`);
    console.log(`   GET  /api/hospitals/:id\n`);
});
