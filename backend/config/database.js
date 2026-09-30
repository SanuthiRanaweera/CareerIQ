const dns = require('node:dns');
const mongoose = require('mongoose');

dns.setServers(['1.1.1.1', '8.8.8.8']);
mongoose.set('bufferCommands', false);

function lookupMongoHost(hostname, options, callback) {
	if (typeof options === 'function') {
		callback = options;
		options = {};
	}

	const family = typeof options === 'number' ? options : options.family || 4;
	const resolve = family === 6 ? dns.promises.resolve6 : dns.promises.resolve4;
	resolve(hostname).then((addresses) => {
		const records = addresses.map((address) => ({ address, family }));
		if (options.all) return callback(null, records);
		callback(null, records[0].address, records[0].family);
	}, callback);
}

async function connectDatabase() {
	const mongoUri = process.env.MONGODB_URI;

	if (!mongoUri) {
		throw new Error('MONGODB_URI is not configured in the environment');
	}

	await mongoose.connect(mongoUri, {
		serverSelectionTimeoutMS: 10000,
		connectTimeoutMS: 10000,
		family: 4,
		lookup: lookupMongoHost,
		dbName: 'career_iq',
	});

	console.log('Connected to MongoDB');
}

function getDatabaseStatus() {
	return mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
}

module.exports = { connectDatabase, getDatabaseStatus };
