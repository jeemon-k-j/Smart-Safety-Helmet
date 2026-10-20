'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { resolveRecipients } = require('../lib/recipient');

describe('resolveRecipients', () => {
  it('prefers payload contacts', () => {
    const result = resolveRecipients('fallback@example.com', [
      'a@example.com',
      'b@example.com',
    ]);
    assert.equal(result.ok, true);
    assert.deepEqual(result.recipients, ['a@example.com', 'b@example.com']);
    assert.equal(result.source, 'payload');
  });

  it('falls back to TEST_EMAIL', () => {
    const result = resolveRecipients('fallback@example.com', []);
    assert.equal(result.ok, true);
    assert.deepEqual(result.recipients, ['fallback@example.com']);
    assert.equal(result.source, 'test_email');
  });
});
