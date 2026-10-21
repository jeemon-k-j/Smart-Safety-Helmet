'use strict';

/**
 * Resolves the single emergency recipient from bridge configuration
 * (EMERGENCY_RECIPIENT or TEST_EMAIL). Payload contact lists are ignored so
 * delivery always goes to the configured address.
 */
function resolveRecipients(configuredRecipient, _payloadRecipients) {
  const value = (configuredRecipient || '').trim();
  if (!value) {
    return { ok: false, reason: 'missing' };
  }
  if (value.includes(',') || value.includes(';')) {
    return { ok: false, reason: 'multiple' };
  }
  if (!value.includes('@')) {
    return { ok: false, reason: 'invalid' };
  }
  return {
    ok: true,
    recipients: [value],
    source: 'configured_recipient',
  };
}

module.exports = { resolveRecipients };
