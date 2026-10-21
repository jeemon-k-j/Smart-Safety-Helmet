'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  buildEmail,
  SUBJECT,
  HEADING,
  formatSeverity,
  formatIncidentTimeIst,
} = require('../lib/message');

describe('formatSeverity', () => {
  it('accepts only low, medium, and high', () => {
    assert.equal(formatSeverity('low'), 'LOW');
    assert.equal(formatSeverity('medium'), 'MEDIUM');
    assert.equal(formatSeverity('high'), 'HIGH');
    assert.equal(formatSeverity('med'), 'MEDIUM');
    assert.equal(formatSeverity('severe'), 'UNAVAILABLE');
  });
});

describe('formatIncidentTimeIst', () => {
  it('formats UTC timestamps as 12-hour IST', () => {
    // 2026-04-01T12:00:00.000Z => 5:30:00 pm IST
    const formatted = formatIncidentTimeIst('2026-04-01T12:00:00.000Z');
    assert.match(formatted, /IST$/);
    assert.match(formatted, /5:30:00/i);
    assert.match(formatted, /pm/i);
    assert.doesNotMatch(formatted, /�/);
  });
});

describe('buildEmail', () => {
  it('builds a professional HTML and plain-text emergency alert', () => {
    const { subject, text, html } = buildEmail({
      severity: 'high',
      eventId: 'acc-1',
      latitude: 10.1,
      longitude: 76.2,
      mapsUrl: 'https://maps.google.com/?q=10.1,76.2',
      occurredAt: '2026-04-01T12:00:00.000Z',
      trigger: 'esp32Accident',
      locationSource: 'phoneGps',
    });

    assert.equal(subject, SUBJECT);
    assert.equal(subject, HEADING);

    assert.match(text, /SMART SAFETY HELMET — EMERGENCY ALERT/);
    assert.match(text, /Severity: HIGH/);
    assert.match(text, /Incident time:.*IST/);
    assert.match(text, /GPS coordinates: 10\.100000, 76\.200000/);
    assert.match(text, /https:\/\/maps\.google\.com\/\?q=10\.1,76\.2/);
    assert.doesNotMatch(text, /Event ID|acc-1|esp32Accident|phoneGps/i);
    assert.doesNotMatch(
      text,
      /\b(demo|simulated|simulation|test|prototype|academic)\b/i,
    );
    assert.doesNotMatch(text, /�/);

    assert.match(html, /charset=utf-8/i);
    assert.match(html, /SMART SAFETY HELMET — EMERGENCY ALERT/);
    assert.match(html, /Accident severity/i);
    assert.match(html, />\s*HIGH\s*</);
    assert.match(html, /#B71C1C/);
    assert.match(html, /10\.100000, 76\.200000/);
    assert.match(
      html,
      /href="https:\/\/maps\.google\.com\/\?q=10\.1,76\.2"/,
    );
    assert.match(html, /Open in Google Maps/);
    assert.doesNotMatch(html, /Event ID|acc-1|esp32Accident|phoneGps/i);
    assert.doesNotMatch(
      html,
      /\b(demo|simulated|simulation|test|prototype|academic)\b/i,
    );
    assert.doesNotMatch(html, /�/);
  });

  it('does not invent GPS coordinates when location is missing', () => {
    const { text, html } = buildEmail({
      severity: 'medium',
      eventId: 'acc-2',
      occurredAt: '2026-04-01T06:15:00.000Z',
    });
    assert.match(text, /GPS coordinates: Unavailable, Unavailable/);
    assert.match(text, /Location: Unavailable/);
    assert.match(html, /Unavailable/);
    assert.doesNotMatch(text, /12\.9716|77\.5946/);
    assert.doesNotMatch(html, /12\.9716|77\.5946/);
  });
});
