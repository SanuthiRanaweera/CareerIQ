const tls = require('node:tls');
const fs = require('node:fs');
const path = require('node:path');

function readResponse(socket) {
	return new Promise((resolve, reject) => {
		let buffer = '';
		const onData = (chunk) => {
			buffer += chunk.toString();
			const lines = buffer.split(/\r?\n/).filter(Boolean);
			const last = lines.at(-1);
			if (last && /^\d{3} /.test(last)) {
				socket.removeListener('data', onData);
				resolve({ code: Number(last.slice(0, 3)), text: lines.join('\n') });
			}
		};
		socket.on('data', onData);
		socket.once('error', reject);
	});
}

async function command(socket, value, expected = [250]) {
	socket.write(`${value}\r\n`);
	const response = await readResponse(socket);
	if (!expected.includes(response.code)) {
		if (response.code === 535) {
			throw new Error('Gmail rejected GMAIL_USER or GMAIL_APP_PASSWORD. Generate a new Gmail App Password and update backend/.env.');
		}
		throw new Error(`Gmail SMTP error ${response.code}: ${response.text}`);
	}
}

async function sendVerificationEmail({ email, fullName, otp }) {
	const username = process.env.GMAIL_USER;
	const password = process.env.GMAIL_APP_PASSWORD;
	if (!username || !password) throw new Error('GMAIL_USER and GMAIL_APP_PASSWORD are required in backend/.env');

	const socket = tls.connect({ host: 'smtp.gmail.com', port: 465, servername: 'smtp.gmail.com', timeout: 15000 });
	try {
		await readResponse(socket);
		await command(socket, 'EHLO careeriq.local');
		await command(socket, 'AUTH LOGIN', [334]);
		await command(socket, Buffer.from(username).toString('base64'), [334]);
		await command(socket, Buffer.from(password.replace(/\s/g, '')).toString('base64'), [235]);
		await command(socket, `MAIL FROM:<${username}>`);
		await command(socket, `RCPT TO:<${email}>`);
		await command(socket, 'DATA', [354]);
		const logoPath = path.resolve(__dirname, '../../frontend/flutter_app/Assets/logo.jpeg');
		const logo = fs.readFileSync(logoPath).toString('base64');
		const boundary = `CareerIQ_${Date.now()}`;
		const message = [
			`From: CareerIQ <${username}>`,
			`To: ${email}`,
			'Subject: Your CareerIQ verification code',
			'MIME-Version: 1.0',
			`Content-Type: multipart/related; boundary="${boundary}"`,
			'',
			`--${boundary}`,
			'Content-Type: text/html; charset=UTF-8',
			'',
			`<div style="font-family:Arial,sans-serif;max-width:520px;padding:24px;color:#172323"><img src="cid:careeriq-logo" alt="CareerIQ" style="width:180px;height:auto"><h2>Welcome to CareerIQ, ${fullName}</h2><p>Your email verification code is:</p><h1 style="letter-spacing:8px;color:#0B6E69">${otp}</h1><p>This code expires in 10 minutes.</p></div>`,
			'',
			`--${boundary}`,
			'Content-Type: image/jpeg; name="careeriq-logo.jpeg"',
			'Content-Transfer-Encoding: base64',
			'Content-ID: <careeriq-logo>',
			'Content-Disposition: inline; filename="careeriq-logo.jpeg"',
			'',
			logo.match(/.{1,76}/g).join('\r\n'),
			`--${boundary}--`,
			'',
		].join('\r\n');
		socket.write(`${message}\r\n.\r\n`);
		const sent = await readResponse(socket);
		if (sent.code !== 250) throw new Error(`Gmail SMTP error ${sent.code}: ${sent.text}`);
		await command(socket, 'QUIT', [221]);
	} finally {
		socket.setTimeout(0);
		socket.end();
	}
}

async function sendUniversityOtpEmail({ universityName, email, otp }) {
	const username = process.env.GMAIL_USER;
	const password = process.env.GMAIL_APP_PASSWORD;
	if (!username || !password) throw new Error('GMAIL_USER and GMAIL_APP_PASSWORD are required in backend/.env');

	const socket = tls.connect({ host: 'smtp.gmail.com', port: 465, servername: 'smtp.gmail.com', timeout: 15000 });
	try {
		await readResponse(socket);
		await command(socket, 'EHLO careeriq.local');
		await command(socket, 'AUTH LOGIN', [334]);
		await command(socket, Buffer.from(username).toString('base64'), [334]);
		await command(socket, Buffer.from(password.replace(/\s/g, '')).toString('base64'), [235]);
		await command(socket, `MAIL FROM:<${username}>`);
		await command(socket, `RCPT TO:<${email}>`);
		await command(socket, 'DATA', [354]);
		const message = [
			`From: CareerIQ <${username}>`,
			`To: ${email}`,
			'Subject: CareerIQ University Login Verification Code',
			'MIME-Version: 1.0',
			'Content-Type: text/html; charset=UTF-8',
			'',
			`<div style="font-family:Arial,sans-serif;max-width:520px;padding:24px;color:#172323"><h2>Hello ${universityName},</h2><p>Your CareerIQ verification code is:</p><h1 style="letter-spacing:8px;color:#0B6E69">${otp}</h1><p>This code will expire in 5 minutes.</p><p>If you did not request this code, please contact the CareerIQ administrator.</p></div>`,
		].join('\r\n');
		socket.write(`${message}\r\n.\r\n`);
		const sent = await readResponse(socket);
		if (sent.code !== 250) throw new Error(`Gmail SMTP error ${sent.code}: ${sent.text}`);
		await command(socket, 'QUIT', [221]);
	} finally {
		socket.setTimeout(0);
		socket.end();
	}
}

async function sendUniversityAccountCreatedEmail({ email, universityName, password }) {
	const username = process.env.GMAIL_USER;
	const passwordEnv = process.env.GMAIL_APP_PASSWORD;
	if (!username || !passwordEnv) throw new Error('GMAIL_USER and GMAIL_APP_PASSWORD are required in backend/.env');

	const socket = tls.connect({ host: 'smtp.gmail.com', port: 465, servername: 'smtp.gmail.com', timeout: 15000 });
	try {
		await readResponse(socket);
		await command(socket, 'EHLO careeriq.local');
		await command(socket, 'AUTH LOGIN', [334]);
		await command(socket, Buffer.from(username).toString('base64'), [334]);
		await command(socket, Buffer.from(passwordEnv.replace(/\s/g, '')).toString('base64'), [235]);
		await command(socket, `MAIL FROM:<${username}>`);
		await command(socket, `RCPT TO:<${email}>`);
		await command(socket, 'DATA', [354]);
		const message = [
			`From: CareerIQ <${username}>`,
			`To: ${email}`,
			'Subject: CareerIQ Account Created',
			'MIME-Version: 1.0',
			'Content-Type: text/html; charset=UTF-8',
			'',
			`<div style="font-family:Arial,sans-serif;max-width:520px;padding:24px;color:#172323"><h2>University account created successfully</h2><p>Your CareerIQ account has been created.</p><p><strong>Email:</strong> ${email}</p><p><strong>Temporary Password:</strong> ${password}</p><p>Please log in and complete the verification flow to set a secure password.</p></div>`,
		].join('\r\n');
		socket.write(`${message}\r\n.\r\n`);
		const sent = await readResponse(socket);
		if (sent.code !== 250) throw new Error(`Gmail SMTP error ${sent.code}: ${sent.text}`);
		await command(socket, 'QUIT', [221]);
	} finally {
		socket.setTimeout(0);
		socket.end();
	}
}

async function sendUniversityRegistrationOtpEmail({ universityName, email, otp }) {
	const username = process.env.EMAIL_USER || process.env.GMAIL_USER;
	const password = process.env.EMAIL_PASSWORD || process.env.GMAIL_APP_PASSWORD;
	const host = process.env.EMAIL_HOST || 'smtp.gmail.com';
	const port = Number(process.env.EMAIL_PORT) || 465;
	const fromEmail = process.env.EMAIL_FROM || process.env.FROM_EMAIL || username;

	if (!username || !password) throw new Error('Email credentials are required in backend/.env');

	const socket = tls.connect({ host, port, servername: host, timeout: 15000 });
	try {
		await readResponse(socket);
		await command(socket, 'EHLO careeriq.local');
		await command(socket, 'AUTH LOGIN', [334]);
		await command(socket, Buffer.from(username).toString('base64'), [334]);
		await command(socket, Buffer.from(password.replace(/\s/g, '')).toString('base64'), [235]);
		await command(socket, `MAIL FROM:<${fromEmail}>`);
		await command(socket, `RCPT TO:<${email}>`);
		await command(socket, 'DATA', [354]);
		const message = [
			`From: CareerIQ <${fromEmail}>`,
			`To: ${email}`,
			'Subject: CareerIQ University Account Verification',
			'MIME-Version: 1.0',
			'Content-Type: text/html; charset=UTF-8',
			'',
			`<div style="font-family:Arial,sans-serif;max-width:560px;padding:24px;color:#1F2937;line-height:1.6">` +
			`<h2>Hello ${universityName},</h2>` +
			`<p>Your CareerIQ university account is being created by an administrator.</p>` +
			`<p>Your verification code is:</p>` +
			`<div style="background:#EFF6FF;border:1px solid #BFDBFE;padding:16px;text-align:center;border-radius:12px;margin:20px 0">` +
			`<h1 style="letter-spacing:10px;color:#2563EB;margin:0;font-size:32px">${otp}</h1>` +
			`</div>` +
			`<p><strong>This code expires in 5 minutes.</strong></p>` +
			`<p>If you did not expect this email, please contact the CareerIQ administrator.</p>` +
			`<br>` +
			`<p>Regards,<br><strong>CareerIQ Team</strong></p>` +
			`</div>`,
		].join('\r\n');
		socket.write(`${message}\r\n.\r\n`);
		const sent = await readResponse(socket);
		if (sent.code !== 250) throw new Error(`SMTP error ${sent.code}: ${sent.text}`);
		await command(socket, 'QUIT', [221]);
	} finally {
		socket.setTimeout(0);
		socket.end();
	}
}

module.exports = {
	sendVerificationEmail,
	sendUniversityOtpEmail,
	sendUniversityAccountCreatedEmail,
	sendUniversityRegistrationOtpEmail,
};