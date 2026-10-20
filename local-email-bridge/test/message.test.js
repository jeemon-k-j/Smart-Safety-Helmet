'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { buildEmail, SUBJECT } = require('../lib/message');

describe('buildEmail', () => {
  it('includes maps link and severity', () => {
    const { subject, text } = buildEmail({
      severity: 'high',
      eventId: 'acc-1',
      latitude: 10.1,
      longitude: 76.2,
      mapsUrl: 'https://maps.google.com/?q=10.1,76.2',
      occurredAt: '2026-04-01T12:00:00.000Z',
      trigger: 'esp32Accident',
    });
    assert.equal(subject, SUBJECT);
    assert.match(text, /Severity: high/);
    assert.match(text, /maps\.google\.com/);
    assert.match(text, /acc-1/);
  });
});
