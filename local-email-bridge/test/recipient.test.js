'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { resolveRecipients } = require('../lib/recipient');

describe('resolveRecipients', () => {
  it('uses the single configured emergency recipient', () => {
    const result = resolveRecipients('emergency@example.com', [
      'a@example.com',
      'b@example.com',
    ]);
    assert.equal(result.ok, true);
    assert.deepEqual(result.recipients, ['emergency@example.com']);
    assert.equal(result.source, 'configured_recipient');
  });

  it('ignores empty payload and still uses configured recipient', () => {
    const result = resolveRecipients('fallback@example.com', []);
    assert.equal(result.ok, true);
    assert.deepEqual(result.recipients, ['fallback@example.com']);
    assert.equal(result.source, 'configured_recipient');
  });

  it('fails when no recipient is configured', () => {
    const result = resolveRecipients('', ['a@example.com']);
    assert.equal(result.ok, false);
    assert.equal(result.reason, 'missing');
  });
});
