const dns = require('node:dns');
const mongoose = require('mongoose');

dns.setServers(['8.8.8.8', '1.1.1.1']);

async function connectDatabase() {
	const mongoUri = process.env.MONGODB_URI;

	if (!mongoUri) {
		throw new Error('MONGODB_URI is not configured in the environment');
	}

	await mongoose.connect(mongoUri, {
		serverSelectionTimeoutMS: 10000,
		connectTimeoutMS: 10000,
		family: 4,
		dbName: 'career_iq',
	});

	console.log('Connected to MongoDB');
}

function getDatabaseStatus() {
	return mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
}

module.exports = { connectDatabase, getDatabaseStatus };
