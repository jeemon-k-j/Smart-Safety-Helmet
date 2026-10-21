'use strict';

const SUBJECT = 'SMART SAFETY HELMET — EMERGENCY ALERT';
const HEADING = 'SMART SAFETY HELMET — EMERGENCY ALERT';

const KNOWN_SEVERITIES = new Set(['low', 'medium', 'high']);

/**
 * Escapes text for safe HTML email bodies.
 */
function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Normalizes wire severity to low | medium | high for display.
 */
function formatSeverity(raw) {
  const value = String(raw ?? '')
    .trim()
    .toLowerCase();
  if (KNOWN_SEVERITIES.has(value)) {
    return value.toUpperCase();
  }
  if (value === 'med') {
    return 'MEDIUM';
  }
  return 'UNAVAILABLE';
}

/**
 * Formats an ISO/UTC timestamp for display in India Standard Time (12-hour).
 * Internal timestamps remain UTC in the payload; only the display string is IST.
 */
function formatIncidentTimeIst(occurredAt) {
  if (occurredAt == null || occurredAt === '') {
    return 'Unavailable';
  }
  const date = occurredAt instanceof Date ? occurredAt : new Date(occurredAt);
  if (Number.isNaN(date.getTime())) {
    return 'Unavailable';
  }
  const formatted = new Intl.DateTimeFormat('en-IN', {
    timeZone: 'Asia/Kolkata',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    second: '2-digit',
    hour12: true,
  }).format(date);
  return `${formatted} IST`;
}

function formatCoordinate(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value.toFixed(6);
  }
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed.toFixed(6);
    }
  }
  return null;
}

function sanitizeMapsUrl(url) {
  if (typeof url !== 'string') {
    return null;
  }
  const trimmed = url.trim();
  if (!/^https?:\/\//i.test(trimmed)) {
    return null;
  }
  return trimmed;
}

function buildPlainText({
  severityLabel,
  incidentTime,
  latitudeLabel,
  longitudeLabel,
  mapsUrl,
}) {
  const lines = [
    HEADING,
    '',
    `Severity: ${severityLabel}`,
    `Incident time: ${incidentTime}`,
    `GPS coordinates: ${latitudeLabel}, ${longitudeLabel}`,
  ];
  if (mapsUrl) {
    lines.push(`Location: ${mapsUrl}`);
  } else {
    lines.push('Location: Unavailable');
  }
  lines.push(
    '',
    'Open the location link above in a browser or maps app to view the incident site.',
    '',
    'This message was sent by the Smart Safety Helmet emergency alert system.',
  );
  return lines.join('\n');
}

function buildHtml({
  severityLabel,
  incidentTime,
  latitudeLabel,
  longitudeLabel,
  mapsUrl,
}) {
  const severityHtml = escapeHtml(severityLabel);
  const timeHtml = escapeHtml(incidentTime);
  const latHtml = escapeHtml(latitudeLabel);
  const lngHtml = escapeHtml(longitudeLabel);
  const mapsSafe = mapsUrl ? escapeHtml(mapsUrl) : null;
  const locationRow = mapsSafe
    ? `<tr>
              <td style="padding:10px 0 4px;font-size:12px;letter-spacing:0.06em;text-transform:uppercase;color:#8A949E;font-family:Arial,Helvetica,sans-serif;">
                Location
              </td>
            </tr>
            <tr>
              <td style="padding:0 0 8px;font-size:16px;line-height:1.5;font-family:Arial,Helvetica,sans-serif;">
                <a href="${mapsSafe}" style="color:#B71C1C;text-decoration:underline;word-break:break-all;">
                  Open in Google Maps
                </a>
              </td>
            </tr>
            <tr>
              <td style="padding:0 0 4px;font-size:13px;line-height:1.45;color:#5C6670;font-family:Arial,Helvetica,sans-serif;word-break:break-all;">
                ${mapsSafe}
              </td>
            </tr>`
    : `<tr>
              <td style="padding:10px 0 4px;font-size:12px;letter-spacing:0.06em;text-transform:uppercase;color:#8A949E;font-family:Arial,Helvetica,sans-serif;">
                Location
              </td>
            </tr>
            <tr>
              <td style="padding:0 0 4px;font-size:16px;line-height:1.5;color:#1A1F24;font-family:Arial,Helvetica,sans-serif;">
                Unavailable
              </td>
            </tr>`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>${escapeHtml(HEADING)}</title>
</head>
<body style="margin:0;padding:0;background-color:#F2F4F6;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F2F4F6;margin:0;padding:24px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;width:100%;background-color:#FFFFFF;border-collapse:collapse;">
          <tr>
            <td style="height:6px;line-height:6px;font-size:0;background-color:#B71C1C;">&nbsp;</td>
          </tr>
          <tr>
            <td style="padding:28px 28px 8px;font-family:Arial,Helvetica,sans-serif;">
              <p style="margin:0 0 6px;font-size:12px;letter-spacing:0.12em;text-transform:uppercase;color:#B71C1C;font-weight:700;">
                Emergency notification
              </p>
              <h1 style="margin:0;font-size:22px;line-height:1.35;color:#1A1F24;font-weight:700;">
                ${escapeHtml(HEADING)}
              </h1>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 28px 20px;font-family:Arial,Helvetica,sans-serif;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#FFF5F5;border-left:4px solid #B71C1C;">
                <tr>
                  <td style="padding:16px 18px;">
                    <p style="margin:0 0 4px;font-size:12px;letter-spacing:0.08em;text-transform:uppercase;color:#8A1C1C;font-family:Arial,Helvetica,sans-serif;">
                      Accident severity
                    </p>
                    <p style="margin:0;font-size:28px;line-height:1.2;font-weight:700;color:#B71C1C;font-family:Arial,Helvetica,sans-serif;">
                      ${severityHtml}
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 28px;font-family:Arial,Helvetica,sans-serif;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td style="padding:10px 0 4px;font-size:12px;letter-spacing:0.06em;text-transform:uppercase;color:#8A949E;font-family:Arial,Helvetica,sans-serif;">
                    Incident time
                  </td>
                </tr>
                <tr>
                  <td style="padding:0 0 8px;font-size:16px;line-height:1.5;color:#1A1F24;font-family:Arial,Helvetica,sans-serif;">
                    ${timeHtml}
                  </td>
                </tr>
                <tr>
                  <td style="padding:10px 0 4px;font-size:12px;letter-spacing:0.06em;text-transform:uppercase;color:#8A949E;font-family:Arial,Helvetica,sans-serif;">
                    GPS coordinates
                  </td>
                </tr>
                <tr>
                  <td style="padding:0 0 8px;font-size:16px;line-height:1.5;color:#1A1F24;font-family:Arial,Helvetica,sans-serif;">
                    ${latHtml}, ${lngHtml}
                  </td>
                </tr>
                ${locationRow}
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 28px;font-family:Arial,Helvetica,sans-serif;border-top:1px solid #E6EAEE;">
              <p style="margin:20px 0 0;font-size:13px;line-height:1.5;color:#5C6670;">
                This message was sent by the Smart Safety Helmet emergency alert system.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

/**
 * Builds multipart email content from the Flutter notification payload.
 * Uses phone GPS and mapsUrl from the payload when present — never substitutes
 * hardcoded coordinates for real alerts.
 */
function buildEmail(note) {
  const n = note || {};
  const severityLabel = formatSeverity(n.severity);
  const incidentTime = formatIncidentTimeIst(n.occurredAt);
  const lat = formatCoordinate(n.latitude);
  const lng = formatCoordinate(n.longitude);
  const latitudeLabel = lat ?? 'Unavailable';
  const longitudeLabel = lng ?? 'Unavailable';
  const mapsUrl = sanitizeMapsUrl(n.mapsUrl);

  const text = buildPlainText({
    severityLabel,
    incidentTime,
    latitudeLabel,
    longitudeLabel,
    mapsUrl,
  });
  const html = buildHtml({
    severityLabel,
    incidentTime,
    latitudeLabel,
    longitudeLabel,
    mapsUrl,
  });

  return { subject: SUBJECT, text, html };
}

module.exports = {
  SUBJECT,
  HEADING,
  buildEmail,
  formatSeverity,
  formatIncidentTimeIst,
};
