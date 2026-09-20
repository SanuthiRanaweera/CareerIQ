const CATEGORIES = ['analytical', 'creative', 'social', 'leadership', 'practical', 'organized'];

const ANSWER_SCORES = {
	'Strongly Agree': 5,
	Agree: 4,
	Neutral: 3,
	Disagree: 2,
	'Strongly Disagree': 1,
};

const ANSWER_OPTIONS = Object.entries(ANSWER_SCORES).map(([label, value]) => ({ label, value }));

// category is intentionally never exposed via the public questions API
const QUESTIONS = [
	{ id: 'q1', text: 'I enjoy solving challenging problems that require logical thinking.', category: 'analytical', weight: 1 },
	{ id: 'q2', text: 'I like learning how technology, software, or machines work.', category: 'analytical', weight: 1 },
	{ id: 'q3', text: 'I enjoy analyzing information and finding solutions.', category: 'analytical', weight: 1 },
	{ id: 'q4', text: 'I like researching topics to understand them deeply.', category: 'analytical', weight: 1 },
	{ id: 'q5', text: 'I enjoy creating new ideas and trying different approaches.', category: 'creative', weight: 1 },
	{ id: 'q6', text: 'I enjoy designing things such as graphics, interfaces, or creative projects.', category: 'creative', weight: 1 },
	{ id: 'q7', text: 'I like finding creative solutions when facing problems.', category: 'creative', weight: 1 },
	{ id: 'q8', text: 'I enjoy helping people solve their problems.', category: 'social', weight: 1 },
	{ id: 'q9', text: 'I like explaining ideas and teaching others.', category: 'social', weight: 1 },
	{ id: 'q10', text: 'I enjoy working with different people as part of a team.', category: 'social', weight: 1 },
	{ id: 'q11', text: "I am interested in understanding people's thoughts and behaviors.", category: 'social', weight: 1 },
	{ id: 'q12', text: 'I like taking responsibility when working with others.', category: 'leadership', weight: 1 },
	{ id: 'q13', text: 'I enjoy organizing events, activities, or projects.', category: 'leadership', weight: 1 },
	{ id: 'q14', text: 'I like making decisions and planning future goals.', category: 'leadership', weight: 1 },
	{ id: 'q15', text: 'I am interested in starting my own business or leading a team.', category: 'leadership', weight: 1 },
	{ id: 'q16', text: 'I enjoy building, testing, or creating practical things.', category: 'practical', weight: 1 },
	{ id: 'q17', text: 'I prefer learning through experiments and practical activities.', category: 'practical', weight: 1 },
	{ id: 'q18', text: 'I enjoy understanding how products, systems, or machines are developed.', category: 'practical', weight: 1 },
	{ id: 'q19', text: 'I like planning my work and managing my time effectively.', category: 'organized', weight: 1 },
	{ id: 'q20', text: 'I pay attention to small details and try to complete tasks accurately.', category: 'organized', weight: 1 },
];

module.exports = { QUESTIONS, ANSWER_SCORES, ANSWER_OPTIONS, CATEGORIES };
