'use strict';

const SUBJECT = 'Smart Safety Helmet Emergency Alert';

/**
 * Builds email content from the Flutter notification payload.
 * Includes Google Maps link when phone GPS is present.
 */
function buildEmail(note) {
  const n = note || {};
  const lines = [
    'Smart Safety Helmet Emergency Alert',
    '',
    `Severity: ${n.severity ?? 'unknown'}`,
    `Trigger: ${n.trigger ?? 'unknown'}`,
    `Event ID: ${n.eventId ?? 'unknown'}`,
    `Latitude: ${n.latitude ?? 'unavailable'}`,
    `Longitude: ${n.longitude ?? 'unavailable'}`,
    `Maps: ${n.mapsUrl ?? 'unavailable'}`,
    `Occurred at: ${n.occurredAt ?? 'unavailable'}`,
    `Location source: ${n.locationSource ?? 'unavailable'}`,
  ];
  if (n.body) {
    lines.push('', `Message: ${n.body}`);
  }
  lines.push(
    '',
    'Prototype notification — verify before treating as a real emergency.',
  );
  return { subject: SUBJECT, text: lines.join('\n') };
}

module.exports = { SUBJECT, buildEmail };
