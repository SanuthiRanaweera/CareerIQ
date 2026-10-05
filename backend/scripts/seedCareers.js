require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const mongoose = require('mongoose');
const { connectDatabase } = require('../config/database');
const Career = require('../models/Career');

/**
 * Seeds the careers collection with realistic Sri Lankan career data.
 *
 * Run with:   node scripts/seedCareers.js
 *             node scripts/seedCareers.js --fresh   (removes all careers first)
 *
 * Careers are matched on title and upserted, so the script is safe to run more
 * than once: re-running updates the seeded careers in place instead of creating
 * duplicates, and leaves any career added through the admin screen untouched.
 *
 * Salary figures are monthly gross amounts in LKR and reflect typical Sri Lankan
 * market ranges from entry level to experienced level in each field.
 */

const CAREERS = [
	{
		title: 'Software Engineer',
		category: 'Information Technology',
		description:
			'Designs, builds and maintains the software behind web, mobile and enterprise systems. One of the strongest growth areas in Sri Lanka, with a large export-driven industry based in Colombo.',
		whatYouDo: [
			'Write, test and review code for new features',
			'Break business requirements down into technical tasks',
			'Fix defects and improve the performance of existing systems',
			'Work daily with designers, testers and product owners',
		],
		requiredSkills: ['Programming', 'Problem solving', 'Databases', 'Version control (Git)', 'Teamwork'],
		recommendedStreams: ['Technology', 'Mathematics'],
		alSubjects: ['Combined Mathematics', 'Physics', 'ICT', 'Engineering Technology'],
		salaryRange: { min: 150000, max: 500000 },
		jobOutlook: 'Very High',
		industryOpportunities: [
			'Software export companies in Colombo and Galle',
			'Banking and insurance IT divisions',
			'Remote work for overseas clients',
			'Technology startups and freelancing',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Technology or Mathematics stream', description: 'Take Combined Mathematics, Physics or ICT at A/L.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'BSc in Software Engineering or Computer Science', description: 'State universities such as Moratuwa, Colombo School of Computing or UCSC, or a recognised private institute.', durationLabel: '3-4 years' },
			{ order: 3, stage: 'Skills', title: 'Build practical coding skills', description: 'Learn a main language, a framework, Git and SQL, and publish personal projects.', durationLabel: 'Ongoing' },
			{ order: 4, stage: 'Internship', title: 'Software engineering intern', description: 'Six-month placement, usually in the final year of the degree.', durationLabel: '6 months' },
			{ order: 5, stage: 'Entry Job', title: 'Associate Software Engineer', description: 'First full-time role, working on an existing product under supervision.', durationLabel: '1-2 years' },
			{ order: 6, stage: 'Senior Role', title: 'Senior Engineer, Tech Lead or Architect', description: 'Lead a team, design systems and mentor junior engineers.', durationLabel: '5+ years' },
		],
		interestTags: ['technology', 'computers', 'problem solving', 'software', 'mathematics'],
		personalityTypes: ['Analytical', 'Practical'],
		workStyles: ['Office-based', 'Remote', 'Team-based'],
		relatedCourseKeywords: ['software engineering', 'computer science', 'information technology'],
	},
	{
		title: 'Data Scientist',
		category: 'Information Technology',
		description:
			'Turns large volumes of data into decisions using statistics and machine learning. A newer field in Sri Lanka but growing quickly in banking, telecommunications and retail.',
		whatYouDo: [
			'Clean and explore large data sets',
			'Build and evaluate predictive models',
			'Present findings to business teams through dashboards and reports',
			'Work with engineers to deploy models into production',
		],
		requiredSkills: ['Statistics', 'Python', 'Machine learning', 'Data visualisation', 'Critical thinking'],
		recommendedStreams: ['Mathematics', 'Technology', 'Science'],
		alSubjects: ['Combined Mathematics', 'Physics', 'ICT', 'Statistics'],
		salaryRange: { min: 200000, max: 650000 },
		jobOutlook: 'Very High',
		industryOpportunities: [
			'Commercial banks and insurance companies',
			'Telecommunication operators',
			'Large retail and logistics groups',
			'Overseas remote contracts',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Mathematics or Technology stream', description: 'A strong mathematics background matters more here than in most IT careers.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'BSc in Statistics, Data Science, Computer Science or Mathematics', description: 'Offered by Colombo, Peradeniya, Sri Jayewardenepura and several private institutes.', durationLabel: '3-4 years' },
			{ order: 3, stage: 'Skills', title: 'Learn the data toolkit', description: 'Python, pandas, SQL, machine learning libraries and a visualisation tool such as Power BI.', durationLabel: 'Ongoing' },
			{ order: 4, stage: 'Internship', title: 'Data analyst intern', description: 'Work on real reporting and dashboard problems inside a business.', durationLabel: '6 months' },
			{ order: 5, stage: 'Entry Job', title: 'Data Analyst or Junior Data Scientist', description: 'Analyse business data and support senior modelling work.', durationLabel: '2-3 years' },
			{ order: 6, stage: 'Senior Role', title: 'Senior Data Scientist or Head of Analytics', description: 'Own the analytics strategy and lead a team of analysts.', durationLabel: '5+ years' },
		],
		interestTags: ['data', 'mathematics', 'research', 'technology', 'problem solving'],
		personalityTypes: ['Analytical'],
		workStyles: ['Office-based', 'Remote', 'Independent'],
		relatedCourseKeywords: ['data science', 'statistics', 'artificial intelligence'],
	},
	{
		title: 'Civil Engineer',
		category: 'Engineering & Construction',
		description:
			'Plans, designs and supervises the construction of roads, bridges, buildings and water systems. Central to Sri Lankan infrastructure development and a well-respected chartered profession.',
		whatYouDo: [
			'Prepare designs, drawings and structural calculations',
			'Estimate quantities, materials and project costs',
			'Supervise work on construction sites and check quality',
			'Make sure projects meet safety regulations and deadlines',
		],
		requiredSkills: ['Technical drawing', 'AutoCAD', 'Structural analysis', 'Project management', 'Site supervision'],
		recommendedStreams: ['Mathematics', 'Technology'],
		alSubjects: ['Combined Mathematics', 'Physics', 'Chemistry', 'Engineering Technology'],
		salaryRange: { min: 120000, max: 400000 },
		jobOutlook: 'High',
		industryOpportunities: [
			'Road Development Authority and other state bodies',
			'Private construction and contracting firms',
			'Consultancy and design practices',
			'Middle East construction projects',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Mathematics stream', description: 'Combined Mathematics and Physics are required for engineering faculties.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'BSc Engineering (Civil)', description: 'University of Moratuwa, Peradeniya, Ruhuna or Jaffna through the Z-score system.', durationLabel: '4 years' },
			{ order: 3, stage: 'Skills', title: 'Design software and site knowledge', description: 'AutoCAD, Revit, structural analysis tools and reading site drawings.', durationLabel: 'Ongoing' },
			{ order: 4, stage: 'Internship', title: 'Engineering trainee on site', description: 'Mandatory industrial training as part of the degree.', durationLabel: '6-12 months' },
			{ order: 5, stage: 'Entry Job', title: 'Graduate Civil Engineer', description: 'Work under a chartered engineer on live projects.', durationLabel: '2-3 years' },
			{ order: 6, stage: 'Senior Role', title: 'Chartered Engineer or Project Manager', description: 'Gain IESL chartered status and take responsibility for whole projects.', durationLabel: '5-8 years' },
		],
		interestTags: ['construction', 'design', 'mathematics', 'problem solving', 'infrastructure'],
		personalityTypes: ['Analytical', 'Practical'],
		workStyles: ['Fieldwork', 'Office-based', 'Team-based'],
		relatedCourseKeywords: ['civil engineering', 'construction management', 'quantity surveying'],
	},
	{
		title: 'Medical Doctor',
		category: 'Healthcare & Medicine',
		description:
			'Diagnoses and treats illness, and cares for patients in hospitals and clinics. Entry is highly competitive through the Biology stream, and the training is long but the profession carries great respect and security.',
		whatYouDo: [
			'Examine patients and diagnose medical conditions',
			'Prescribe treatment and carry out procedures',
			'Keep accurate clinical records and review progress',
			'Explain conditions and treatment clearly to patients and families',
		],
		requiredSkills: ['Clinical knowledge', 'Attention to detail', 'Communication', 'Decision making under pressure', 'Empathy'],
		recommendedStreams: ['Science'],
		alSubjects: ['Biology', 'Chemistry', 'Physics'],
		salaryRange: { min: 150000, max: 600000 },
		jobOutlook: 'Very High',
		industryOpportunities: [
			'Government hospitals across all districts',
			'Private hospitals and channel practice',
			'Postgraduate specialisation through the PGIM',
			'Public health and research roles',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Biological Science stream', description: 'Biology, Chemistry and Physics, with a very high Z-score needed for selection.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'MBBS', description: 'Colombo, Peradeniya, Sri Jayewardenepura, Ruhuna, Kelaniya, Jaffna or Rajarata.', durationLabel: '5 years' },
			{ order: 3, stage: 'Skills', title: 'Clinical training', description: 'Ward rounds, clinical rotations and patient communication practice.', durationLabel: 'During degree' },
			{ order: 4, stage: 'Internship', title: 'Internship as a house officer', description: 'Compulsory paid internship in a teaching hospital.', durationLabel: '1 year' },
			{ order: 5, stage: 'Entry Job', title: 'Medical Officer', description: 'Appointed to a government hospital through the Ministry of Health.', durationLabel: '2-4 years' },
			{ order: 6, stage: 'Senior Role', title: 'Consultant or Specialist', description: 'Complete PGIM postgraduate training and overseas placement.', durationLabel: '8-12 years' },
		],
		interestTags: ['healthcare', 'biology', 'helping people', 'science', 'medicine'],
		personalityTypes: ['Analytical', 'Social'],
		workStyles: ['Team-based', 'Office-based'],
		relatedCourseKeywords: ['medicine', 'mbbs', 'health sciences'],
	},
	{
		title: 'Chartered Accountant',
		category: 'Finance & Banking',
		description:
			'Prepares and audits financial statements, advises on tax, and guides business decisions. The CA Sri Lanka qualification can be started straight after A/Ls and is valued in every industry.',
		whatYouDo: [
			'Prepare and review financial statements',
			'Carry out audits and check financial controls',
			'Handle tax computations and statutory filings',
			'Advise management on budgets and financial planning',
		],
		requiredSkills: ['Accounting standards', 'Auditing', 'Taxation', 'Excel', 'Attention to detail'],
		recommendedStreams: ['Commerce'],
		alSubjects: ['Accounting', 'Business Studies', 'Economics'],
		salaryRange: { min: 150000, max: 550000 },
		jobOutlook: 'High',
		industryOpportunities: [
			'Audit firms including the Big Four in Colombo',
			'Finance departments of large corporates',
			'Banking and financial services',
			'Overseas opportunities with a recognised qualification',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Commerce stream', description: 'Accounting, Business Studies and Economics give the strongest start.', durationLabel: '2 years' },
			{ order: 2, stage: 'Professional Qualification', title: 'CA Sri Lanka, ACCA or CIMA', description: 'Can be started directly after A/Ls, often alongside a degree.', durationLabel: '3-5 years' },
			{ order: 3, stage: 'Skills', title: 'Accounting systems and reporting', description: 'Excel, QuickBooks or SAP, and current reporting standards.', durationLabel: 'Ongoing' },
			{ order: 4, stage: 'Internship', title: 'Audit trainee', description: 'Training contract at an audit firm, which also counts towards the qualification.', durationLabel: '3 years' },
			{ order: 5, stage: 'Entry Job', title: 'Audit Associate or Accounts Executive', description: 'Handle client audits and monthly reporting.', durationLabel: '2-3 years' },
			{ order: 6, stage: 'Senior Role', title: 'Finance Manager, Audit Manager or CFO', description: 'Lead the finance function of an organisation.', durationLabel: '8+ years' },
		],
		interestTags: ['finance', 'business', 'accounting', 'numbers', 'economics'],
		personalityTypes: ['Analytical', 'Organized'],
		workStyles: ['Office-based', 'Team-based'],
		relatedCourseKeywords: ['accounting', 'finance', 'business administration'],
	},
	{
		title: 'Digital Marketing Specialist',
		category: 'Marketing & Media',
		description:
			'Grows brands online through social media, search and paid advertising. Demand has risen sharply in Sri Lanka as businesses move spending from print and television to digital channels.',
		whatYouDo: [
			'Plan and run social media and advertising campaigns',
			'Create content calendars and brief designers',
			'Track performance using analytics tools',
			'Adjust campaigns based on engagement and conversion data',
		],
		requiredSkills: ['Social media marketing', 'Content writing', 'SEO', 'Google Analytics', 'Creativity'],
		recommendedStreams: ['Commerce', 'Arts', 'Technology'],
		alSubjects: ['Business Studies', 'Economics', 'Media Studies', 'ICT'],
		salaryRange: { min: 80000, max: 300000 },
		jobOutlook: 'High',
		industryOpportunities: [
			'Digital and advertising agencies in Colombo',
			'In-house marketing teams',
			'E-commerce and retail brands',
			'Freelance and remote contracts',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Commerce or Arts stream', description: 'Business Studies, Economics or Media Studies suit this path well.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'Degree or diploma in Marketing or Mass Communication', description: 'SLIM, CIM, Kelaniya or Sri Jayewardenepura are common routes.', durationLabel: '2-4 years' },
			{ order: 3, stage: 'Skills', title: 'Hands-on digital skills', description: 'Meta Ads, Google Ads, SEO, Canva and analytics dashboards.', durationLabel: '6-12 months' },
			{ order: 4, stage: 'Internship', title: 'Marketing intern at an agency', description: 'Real campaign experience and a portfolio of published work.', durationLabel: '3-6 months' },
			{ order: 5, stage: 'Entry Job', title: 'Digital Marketing Executive', description: 'Run day-to-day campaigns for one or more brands.', durationLabel: '2-3 years' },
			{ order: 6, stage: 'Senior Role', title: 'Marketing Manager or Brand Manager', description: 'Own strategy and budget for a brand portfolio.', durationLabel: '5+ years' },
		],
		interestTags: ['marketing', 'social media', 'business', 'creativity', 'communication'],
		personalityTypes: ['Creative', 'Social'],
		workStyles: ['Office-based', 'Remote', 'Team-based'],
		relatedCourseKeywords: ['marketing', 'mass communication', 'digital media'],
	},
	{
		title: 'UI/UX Designer',
		category: 'Design & Creative',
		description:
			'Designs how apps and websites look and feel, so that people can use them easily. Combines creative work with research into real user behaviour, and is in steady demand across the Sri Lankan software industry.',
		whatYouDo: [
			'Research how users behave and what they struggle with',
			'Sketch wireframes and build interactive prototypes',
			'Design screens, components and design systems',
			'Test designs with users and refine them based on feedback',
		],
		requiredSkills: ['Figma', 'Wireframing', 'User research', 'Visual design', 'Usability principles'],
		recommendedStreams: ['Arts', 'Technology', 'Commerce'],
		alSubjects: ['Art', 'ICT', 'Media Studies'],
		salaryRange: { min: 100000, max: 350000 },
		jobOutlook: 'High',
		industryOpportunities: [
			'Software product companies',
			'Digital agencies and design studios',
			'Startups building their first product',
			'Freelance work for overseas clients',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Arts, Technology or Commerce stream', description: 'No single stream is required; a visual portfolio matters more.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'Degree or diploma in Design, Multimedia or HCI', description: 'University of Moratuwa, AOD, NIBM or an equivalent institute.', durationLabel: '2-4 years' },
			{ order: 3, stage: 'Skills', title: 'Build a design portfolio', description: 'Learn Figma, design systems and usability testing, and publish case studies.', durationLabel: '6-12 months' },
			{ order: 4, stage: 'Internship', title: 'Design intern', description: 'Work on real product screens alongside developers.', durationLabel: '3-6 months' },
			{ order: 5, stage: 'Entry Job', title: 'Junior UI/UX Designer', description: 'Design features within an existing product and design system.', durationLabel: '2-3 years' },
			{ order: 6, stage: 'Senior Role', title: 'Senior Designer or Product Design Lead', description: 'Own the design direction of a product and guide junior designers.', durationLabel: '5+ years' },
		],
		interestTags: ['design', 'creativity', 'technology', 'art', 'psychology'],
		personalityTypes: ['Creative', 'Analytical'],
		workStyles: ['Office-based', 'Remote', 'Team-based'],
		relatedCourseKeywords: ['design', 'multimedia', 'human computer interaction'],
	},
	{
		title: 'Tourism & Hospitality Manager',
		category: 'Tourism & Hospitality',
		description:
			'Runs hotel and travel operations so that guests have a good experience. Tourism is one of Sri Lankan largest foreign exchange earners, and management roles exist across the island rather than only in Colombo.',
		whatYouDo: [
			'Manage front office, housekeeping and food service teams',
			'Handle guest relations and resolve complaints',
			'Plan staffing, budgets and occupancy targets',
			'Maintain service and hygiene standards',
		],
		requiredSkills: ['Customer service', 'Team leadership', 'Communication', 'English and a second language', 'Operations planning'],
		recommendedStreams: ['Commerce', 'Arts'],
		alSubjects: ['Business Studies', 'Economics', 'Geography', 'Languages'],
		salaryRange: { min: 90000, max: 350000 },
		jobOutlook: 'High',
		industryOpportunities: [
			'Resort hotels in the south, hill country and east coast',
			'International hotel chains in Colombo',
			'Travel and tour operating companies',
			'Cruise lines and overseas hospitality roles',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Commerce or Arts stream', description: 'Strong English and communication skills matter most.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'Degree or diploma in Hospitality Management', description: 'SLITHM, Uva Wellassa, Sabaragamuwa or Rajarata.', durationLabel: '2-4 years' },
			{ order: 3, stage: 'Skills', title: 'Service and language skills', description: 'Hotel systems, food and beverage standards, and a second language.', durationLabel: 'Ongoing' },
			{ order: 4, stage: 'Internship', title: 'Hotel industrial training', description: 'Rotate through front office, housekeeping and food and beverage.', durationLabel: '6-12 months' },
			{ order: 5, stage: 'Entry Job', title: 'Guest Relations or Operations Executive', description: 'Supervise a shift or a section of hotel operations.', durationLabel: '2-4 years' },
			{ order: 6, stage: 'Senior Role', title: 'Hotel Manager or General Manager', description: 'Take responsibility for the whole property and its profitability.', durationLabel: '8+ years' },
		],
		interestTags: ['tourism', 'hospitality', 'travel', 'helping people', 'communication'],
		personalityTypes: ['Social', 'Leadership', 'Organized'],
		workStyles: ['Team-based', 'Fieldwork'],
		relatedCourseKeywords: ['tourism management', 'hospitality management', 'hotel management'],
	},
	{
		title: 'Attorney-at-Law',
		category: 'Law & Legal Services',
		description:
			'Advises clients on the law and represents them in court. Sri Lanka offers two routes into the profession: a law degree, or the Sri Lanka Law College examinations taken directly after A/Ls.',
		whatYouDo: [
			'Advise clients on their legal position and options',
			'Draft contracts, pleadings and legal opinions',
			'Research case law and statutes',
			'Appear before courts and tribunals on behalf of clients',
		],
		requiredSkills: ['Legal research', 'Written and oral advocacy', 'Analytical reasoning', 'Negotiation', 'Attention to detail'],
		recommendedStreams: ['Arts', 'Commerce'],
		alSubjects: ['Political Science', 'Economics', 'Logic', 'Languages'],
		salaryRange: { min: 80000, max: 400000 },
		jobOutlook: 'Medium',
		industryOpportunities: [
			'Private practice in the unofficial bar',
			'Corporate legal departments',
			'Attorney General Department and the judiciary',
			'Legal consultancy and compliance roles',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Arts or Commerce stream', description: 'Strong language and reasoning subjects help considerably.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'LLB degree or Sri Lanka Law College entrance', description: 'Colombo, Peradeniya, Jaffna or the Open University, or Law College directly.', durationLabel: '3-4 years' },
			{ order: 3, stage: 'Skills', title: 'Legal drafting and research', description: 'Case law research, drafting practice and courtroom observation.', durationLabel: 'Ongoing' },
			{ order: 4, stage: 'Internship', title: 'Apprenticeship under a senior attorney', description: 'Compulsory pupillage before being called to the bar.', durationLabel: '6-12 months' },
			{ order: 5, stage: 'Entry Job', title: 'Junior Attorney-at-Law', description: 'Take on junior briefs and assist in chambers.', durationLabel: '3-5 years' },
			{ order: 6, stage: 'Senior Role', title: 'Senior Counsel, Partner or Judge', description: "Build a specialised practice or enter the judicial service.", durationLabel: '10+ years' },
		],
		interestTags: ['law', 'justice', 'debate', 'research', 'writing'],
		personalityTypes: ['Analytical', 'Social', 'Organized'],
		workStyles: ['Office-based', 'Independent'],
		relatedCourseKeywords: ['law', 'llb', 'legal studies'],
	},
	{
		title: 'Agricultural Officer',
		category: 'Agriculture & Environment',
		description:
			'Supports farmers with crop science, soil management and modern techniques to improve yields. An important role across rural Sri Lanka, combining laboratory and field work with community advisory duties.',
		whatYouDo: [
			'Advise farmers on crop selection, soil and pest management',
			'Run field trials and collect agricultural data',
			'Conduct training programmes for farming communities',
			'Prepare reports for government agricultural programmes',
		],
		requiredSkills: ['Crop science', 'Soil analysis', 'Field research', 'Community communication', 'Report writing'],
		recommendedStreams: ['Science'],
		alSubjects: ['Biology', 'Chemistry', 'Agricultural Science'],
		salaryRange: { min: 70000, max: 220000 },
		jobOutlook: 'Medium',
		industryOpportunities: [
			'Department of Agriculture and provincial councils',
			'Plantation companies and agri-exporters',
			'Agricultural input and seed companies',
			'Research institutes and NGOs',
		],
		pathway: [
			{ order: 1, stage: 'A/L Stream', title: 'Biological Science stream', description: 'Biology and Chemistry, or Agricultural Science where it is offered.', durationLabel: '2 years' },
			{ order: 2, stage: 'Degree', title: 'BSc in Agriculture', description: 'Peradeniya, Ruhuna, Rajarata, Wayamba or Sabaragamuwa.', durationLabel: '4 years' },
			{ order: 3, stage: 'Skills', title: 'Field and laboratory techniques', description: 'Soil testing, crop trials, data collection and extension methods.', durationLabel: 'Ongoing' },
			{ order: 4, stage: 'Internship', title: 'In-plant training at a farm or research station', description: 'Practical placement during the degree programme.', durationLabel: '6 months' },
			{ order: 5, stage: 'Entry Job', title: 'Agriculture Instructor or Field Officer', description: 'Work directly with farming communities in a divisional area.', durationLabel: '2-4 years' },
			{ order: 6, stage: 'Senior Role', title: 'Agricultural Officer or Research Scientist', description: 'Lead regional programmes or specialise through postgraduate research.', durationLabel: '6+ years' },
		],
		interestTags: ['agriculture', 'environment', 'biology', 'nature', 'research'],
		personalityTypes: ['Practical', 'Analytical', 'Social'],
		workStyles: ['Fieldwork', 'Laboratory'],
		relatedCourseKeywords: ['agriculture', 'agricultural science', 'plantation management'],
	},
];

async function seedCareers() {
	const fresh = process.argv.includes('--fresh');

	try {
		await connectDatabase();

		if (fresh) {
			const removed = await Career.deleteMany({});
			console.log(`--fresh: removed ${removed.deletedCount} existing career(s)`);
		}

		let created = 0;
		let updated = 0;

		for (const career of CAREERS) {
			// Upsert on title so re-running the script never creates duplicates.
			// runValidators keeps seed data held to the same rules as the API.
			const result = await Career.updateOne({ title: career.title }, { $set: career }, {
				upsert: true,
				runValidators: true,
				setDefaultsOnInsert: true,
			});
			if (result.upsertedCount) created += 1;
			else updated += 1;
			console.log(`  ${result.upsertedCount ? 'created' : 'updated'}  ${career.title}`);
		}

		console.log('\n=========================================');
		console.log('   Career seeding complete               ');
		console.log('=========================================');
		console.log(`   Created: ${created}`);
		console.log(`   Updated: ${updated}`);
		console.log(`   Total careers in database: ${await Career.countDocuments()}`);
		console.log('=========================================\n');
	} catch (error) {
		console.error('Failed to seed careers:', error.message);
		process.exitCode = 1;
	} finally {
		await mongoose.disconnect();
	}
}

seedCareers();
