'use strict';

const { buildEmail } = require('./message');
const { resolveRecipients } = require('./recipient');

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 1_000_000) {
        reject(new Error('payload too large'));
        req.destroy();
      }
    });
    req.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
      } catch (error) {
        reject(new Error('invalid JSON'));
      }
    });
    req.on('error', reject);
  });
}

function createHandler({ configuredRecipient, sendEmail, store, logger = console }) {
  return async function handler(req, res) {
    const send = (status, body) => {
      res.writeHead(status, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(body));
    };

    if (req.method === 'GET' && req.url === '/health') {
      send(200, { status: 'ok' });
      return;
    }

    if (req.method !== 'POST' || req.url !== '/notify') {
      send(404, { error: 'not found' });
      return;
    }

    let note;
    try {
      note = await readJsonBody(req);
    } catch (error) {
      send(400, { error: error.message });
      return;
    }

    if (!note || note.type !== 'smartSafetyHelmetEmergency' || !note.eventId) {
      send(400, { error: 'invalid notification payload' });
      return;
    }

    const resolved = resolveRecipients(configuredRecipient, note.recipients);
    if (!resolved.ok) {
      logger.error(`No usable recipients (${resolved.reason}); not sending.`);
      send(500, { error: 'recipient not configured' });
      return;
    }

    const key =
      typeof note.idempotencyKey === 'string' && note.idempotencyKey.length > 0
        ? note.idempotencyKey
        : note.eventId;

    if (key && store.has(key)) {
      logger.info(`Duplicate notification ${key} ignored.`);
      send(200, { status: 'duplicate-skipped' });
      return;
    }

    const { subject, text } = buildEmail(note);

    try {
      for (const to of resolved.recipients) {
        await sendEmail({ to, subject, text });
      }
      if (key) {
        store.add(key);
      }
      logger.info(
        `Email sent (notification ${key}) to ${resolved.recipients.length} recipient(s) via ${resolved.source}.`,
      );
      send(200, { status: 'sent', count: resolved.recipients.length });
    } catch (error) {
      logger.error(
        `Email send failed (notification ${key}): ${
          error && error.message ? error.message : error
        }`,
      );
      send(502, { status: 'send-failed' });
    }
  };
}

module.exports = { createHandler, readJsonBody };
