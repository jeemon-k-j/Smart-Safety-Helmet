'use strict';

/**
 * Resolves recipients: prefer emergency contact emails from the app payload;
 * otherwise fall back to the single configured TEST_EMAIL (DeepCrash style).
 */
function resolveRecipients(configuredFallback, payloadRecipients) {
  const fromPayload = [];
  if (Array.isArray(payloadRecipients)) {
    for (const raw of payloadRecipients) {
      const email = String(raw || '').trim();
      if (email && email.includes('@') && !email.includes(',')) {
        fromPayload.push(email);
      }
    }
  }
  if (fromPayload.length > 0) {
    return { ok: true, recipients: [...new Set(fromPayload)], source: 'payload' };
  }

  const value = (configuredFallback || '').trim();
  if (!value) {
    return { ok: false, reason: 'missing' };
  }
  if (value.includes(',') || value.includes(';')) {
    return { ok: false, reason: 'multiple' };
  }
  return { ok: true, recipients: [value], source: 'test_email' };
}

module.exports = { resolveRecipients };
