'use strict';

/**
 * Local development SMTP email bridge (adapted from DeepCrash).
 * Holds SMTP credentials server-side. Flutter posts JSON to POST /notify.
 */

const http = require('node:http');
const nodemailer = require('nodemailer');

const { createHandler } = require('./lib/handler');
const { createMemoryStore } = require('./lib/store');

const HOST = process.env.BRIDGE_HOST || '0.0.0.0';
const PORT = Number(process.env.BRIDGE_PORT || 3000);

const TEST_EMAIL = process.env.TEST_EMAIL;
const SMTP_HOST = process.env.SMTP_HOST;
const SMTP_PORT = Number(process.env.SMTP_PORT || 587);
const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASSWORD = process.env.SMTP_PASSWORD;

const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: SMTP_PORT,
  secure: SMTP_PORT === 465,
  auth: { user: SMTP_USER, pass: SMTP_PASSWORD },
});

const sendEmail = async ({ to, subject, text }) => {
  await transporter.sendMail({ from: SMTP_USER, to, subject, text });
};

const handler = createHandler({
  configuredRecipient: TEST_EMAIL,
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
    `TEST_EMAIL fallback: ${TEST_EMAIL ? 'configured' : 'NOT SET'}`,
  );
});
