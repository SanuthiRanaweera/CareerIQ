const tls = require('node:tls');

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
		socket.write(`From: CareerIQ <${username}>\r\nTo: ${email}\r\nSubject: Your CareerIQ verification code\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n<h2>Welcome to CareerIQ, ${fullName}</h2><p>Your email verification code is:</p><h1 style="letter-spacing: 8px">${otp}</h1><p>This code expires in 10 minutes.</p>\r\n.\r\n`);
		const sent = await readResponse(socket);
		if (sent.code !== 250) throw new Error(`Gmail SMTP error ${sent.code}: ${sent.text}`);
		await command(socket, 'QUIT', [221]);
	} finally {
		socket.setTimeout(0);
		socket.end();
	}
}

module.exports = { sendVerificationEmail };