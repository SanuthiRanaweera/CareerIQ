require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const bcrypt = require('bcrypt');
const mongoose = require('mongoose');
const { connectDatabase } = require('../config/database');
const User = require('../models/User');
const Student = require('../models/Student');

async function createAdmin() {
	try {
		await connectDatabase();

		const adminEmail = (process.env.ADMIN_EMAIL || process.argv[2] || 'admin@careeriq.lk').toLowerCase().trim();
		const adminPassword = process.env.ADMIN_PASSWORD || process.argv[3] || 'Admin1234!';
		const adminName = process.env.ADMIN_NAME || process.argv[4] || 'CareerIQ Admin';

		console.log(`Checking for admin account: ${adminEmail}`);

		const hashedPassword = await bcrypt.hash(adminPassword, 12);

		let user = await User.findOne({ email: adminEmail }).select('+password');

		if (user) {
			user.fullName = adminName;
			user.password = hashedPassword;
			user.role = 'admin';
			user.isEmailVerified = true;
			await user.save();
			console.log(`Updated existing user to Admin: ${adminEmail}`);
		} else {
			user = await User.create({
				fullName: adminName,
				email: adminEmail,
				password: hashedPassword,
				role: 'admin',
				isEmailVerified: true,
				authProvider: 'password',
			});
			console.log(`Created new Admin user: ${adminEmail}`);
		}

		// Also ensure a Student profile exists so that logging in via any endpoint works seamlessly
		let student = await Student.findOne({ userId: user._id });
		if (!student) {
			student = await Student.create({
				userId: user._id,
				fullName: adminName,
				email: adminEmail,
				school: 'CareerIQ Administration',
				district: 'Colombo',
				stream: 'Technology',
				alYear: 2025,
			});
			console.log('Created linked student profile for admin.');
		}

		console.log('\n=========================================');
		console.log('   Admin Account Ready!                  ');
		console.log('=========================================');
		console.log(`   Email:    ${adminEmail}`);
		console.log(`   Password: ${adminPassword}`);
		console.log(`   Role:     ${user.role}`);
		console.log('=========================================\n');
	} catch (error) {
		console.error('Failed to create admin user:', error);
		process.exit(1);
	} finally {
		await mongoose.disconnect();
		process.exit(0);
	}
}

createAdmin();
