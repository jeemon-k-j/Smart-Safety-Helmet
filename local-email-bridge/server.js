'use strict';

/**
 * Local SMTP email bridge (adapted from DeepCrash).
 * Holds SMTP credentials server-side. Flutter posts JSON to POST /notify.
 *
 * Load secrets from a git-ignored `.env` via: npm start
 * (uses Node --env-file; never commit real credentials).
 */

const http = require('node:http');
const nodemailer = require('nodemailer');

const { createHandler } = require('./lib/handler');
const { createMemoryStore } = require('./lib/store');

const HOST = process.env.BRIDGE_HOST || '0.0.0.0';
const PORT = Number(process.env.BRIDGE_PORT || 3000);

// Prefer EMERGENCY_RECIPIENT; keep TEST_EMAIL as a compatible alias.
const EMERGENCY_RECIPIENT =
  process.env.EMERGENCY_RECIPIENT || process.env.TEST_EMAIL || '';

const SMTP_HOST = process.env.SMTP_HOST;
const SMTP_PORT = Number(process.env.SMTP_PORT || 465);
const SMTP_USER = process.env.SMTP_USER;
// Prefer SMTP_PASSWORD; accept SMTP_PASS as an alias.
const SMTP_PASSWORD = process.env.SMTP_PASSWORD || process.env.SMTP_PASS || '';

const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: SMTP_PORT,
  secure: SMTP_PORT === 465,
  auth: { user: SMTP_USER, pass: SMTP_PASSWORD },
});

const sendEmail = async ({ to, subject, text, html }) => {
  await transporter.sendMail({
    from: SMTP_USER,
    to,
    subject,
    text,
    html,
  });
};

const handler = createHandler({
  configuredRecipient: EMERGENCY_RECIPIENT,
  sendEmail,
  store: createMemoryStore(),
  logger: console,
});

const server = http.createServer((req, res) => {
  handler(req, res).catch(() => {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'internal error' }));
  });
});

server.listen(PORT, HOST, () => {
  console.log(`Smart Safety Helmet email bridge on http://${HOST}:${PORT}`);
  console.log(
    `Emergency recipient: ${EMERGENCY_RECIPIENT ? 'configured' : 'NOT SET'}`,
  );
  console.log(
    `SMTP: ${SMTP_HOST || 'NOT SET'}:${SMTP_PORT} user=${
      SMTP_USER ? 'configured' : 'NOT SET'
    }`,
  );
});
