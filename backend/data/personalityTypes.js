const PERSONALITY_TYPES = {
	analytical: {
		name: 'Analytical Explorer',
		strengths: ['Problem solving', 'Logical thinking', 'Research ability'],
		careers: ['Software Engineer', 'Data Scientist', 'AI Engineer', 'Researcher'],
	},
	creative: {
		name: 'Creative Innovator',
		strengths: ['Creative thinking', 'Original ideas', 'Design sense'],
		careers: ['UI/UX Designer', 'Architect', 'Product Designer', 'Content Creator'],
	},
	social: {
		name: 'People Supporter',
		strengths: ['Communication', 'Empathy', 'Teamwork'],
		careers: ['Teacher', 'Doctor', 'Counselor', 'HR Manager'],
	},
	leadership: {
		name: 'Strategic Leader',
		strengths: ['Decision making', 'Responsibility', 'Planning'],
		careers: ['Entrepreneur', 'Project Manager', 'Business Manager'],
	},
	practical: {
		name: 'Technical Builder',
		strengths: ['Hands-on skills', 'Practical thinking', 'Building things'],
		careers: ['Engineer', 'Developer', 'Technician'],
	},
	organized: {
		name: 'Structured Planner',
		strengths: ['Organization', 'Attention to detail', 'Time management'],
		careers: ['Accountant', 'Business Analyst', 'Administrator'],
	},
};

module.exports = PERSONALITY_TYPES;
