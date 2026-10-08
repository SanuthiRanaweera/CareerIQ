require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const mongoose = require('mongoose');
const { connectDatabase } = require('../config/database');
const Course = require('../models/Course');

const SAMPLE_COURSES = [
	{
		title: 'BSc in Computer Science',
		university: 'University of Colombo School of Computing',
		stream: 'Mathematics',
		degreeType: "Bachelor's Degree",
		description: 'Sample catalogue entry for undergraduate computer science study, including programming, algorithms, databases, and software systems.',
		durationYears: 3,
		subjects: ['Combined Mathematics', 'Physics', 'Information & Communication Technology'],
		careerPaths: ['Software Engineer', 'Systems Analyst', 'Data Analyst'],
		website: 'ucsc.cmb.ac.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
	{
		title: 'BSc Engineering (Electrical Engineering)',
		university: 'University of Moratuwa',
		stream: 'Mathematics',
		degreeType: 'Engineering Degree',
		description: 'Sample engineering programme covering electrical systems, electronics, control, and power engineering.',
		durationYears: 4,
		subjects: ['Combined Mathematics', 'Physics', 'Chemistry'],
		careerPaths: ['Electrical Engineer', 'Electronics Engineer', 'Control Systems Engineer'],
		website: 'uom.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
	{
		title: 'MBBS (Medicine)',
		university: 'University of Colombo',
		stream: 'Science',
		degreeType: 'Medical Degree',
		description: 'Sample medical degree entry covering foundational medical sciences and clinical training.',
		durationYears: 5,
		subjects: ['Biology', 'Chemistry', 'Physics'],
		careerPaths: ['Medical Officer', 'General Practitioner', 'Medical Specialist'],
		website: 'med.cmb.ac.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
	{
		title: 'BSc in Biological Science',
		university: 'University of Peradeniya',
		stream: 'Science',
		degreeType: "Bachelor's Degree",
		description: 'Sample science programme exploring biology, chemistry, laboratory methods, and research.',
		durationYears: 3,
		subjects: ['Biology', 'Chemistry', 'Physics'],
		careerPaths: ['Laboratory Scientist', 'Research Assistant', 'Science Educator'],
		website: 'pdn.ac.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
	{
		title: 'BCom in Accounting and Finance',
		university: 'University of Sri Jayewardenepura',
		stream: 'Commerce',
		degreeType: "Bachelor's Degree",
		description: 'Sample commerce programme covering accounting, financial management, business, and economics.',
		durationYears: 4,
		subjects: ['Accounting', 'Business Studies', 'Economics'],
		careerPaths: ['Accountant', 'Financial Analyst', 'Auditor'],
		website: 'sjp.ac.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
	{
		title: 'BBA in Business Administration',
		university: 'University of Kelaniya',
		stream: 'Commerce',
		degreeType: "Bachelor's Degree",
		description: 'Sample business programme introducing management, marketing, accounting, and organisational practice.',
		durationYears: 4,
		subjects: ['Business Studies', 'Economics', 'Accounting'],
		careerPaths: ['Business Analyst', 'Marketing Executive', 'Operations Manager'],
		website: 'kln.ac.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
	{
		title: 'BA in English',
		university: 'University of Kelaniya',
		stream: 'Arts',
		degreeType: 'Bachelor of Arts',
		description: 'Sample humanities programme focused on English language, literature, communication, and critical analysis.',
		durationYears: 3,
		subjects: ['English', 'Logic & Scientific Method', 'Communication & Media Studies'],
		careerPaths: ['Teacher', 'Writer', 'Communications Officer'],
		website: 'kln.ac.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
	{
		title: 'BSc in Engineering Technology',
		university: 'Uva Wellassa University',
		stream: 'Technology',
		degreeType: "Bachelor's Degree",
		description: 'Sample applied technology programme combining engineering practice, laboratory work, and technology systems.',
		durationYears: 4,
		subjects: ['Engineering Technology', 'Science for Technology', 'Information & Communication Technology'],
		careerPaths: ['Engineering Technologist', 'Technical Officer', 'Production Supervisor'],
		website: 'uwu.ac.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
	{
		title: 'BSc in Information Technology',
		university: 'Rajarata University of Sri Lanka',
		stream: 'Technology',
		degreeType: "Bachelor's Degree",
		description: 'Sample information technology programme covering software, networks, information systems, and IT project work.',
		durationYears: 4,
		subjects: ['Information & Communication Technology', 'Science for Technology', 'Engineering Technology'],
		careerPaths: ['IT Support Specialist', 'Software Developer', 'Network Administrator'],
		website: 'rjt.ac.lk',
		applicationUrl: 'https://www.ugc.ac.lk/',
	},
];

async function seedCourses() {
	try {
		await connectDatabase();
		let inserted = 0;
		for (const course of SAMPLE_COURSES) {
			const result = await Course.updateOne(
				{ title: course.title, university: course.university },
				{ $setOnInsert: course },
				{ upsert: true },
			);
			if (result.upsertedCount) inserted += 1;
		}
		console.log(`Course seed complete: ${inserted} inserted, ${SAMPLE_COURSES.length - inserted} already existed.`);
	} catch (error) {
		console.error('Course seed failed:', error.message);
		process.exitCode = 1;
	} finally {
		await mongoose.disconnect();
	}
}

if (require.main === module) seedCourses();

module.exports = { SAMPLE_COURSES, seedCourses };
