const Career = require('../models/Career');

/**
 * Weighted scoring for career recommendations.
 *
 * All weights live in this one config object so the balance of the algorithm
 * can be tuned in a single place, and so it can be explained and justified
 * without reading the scoring code. The values add up to 100, which means a
 * perfect match on every component scores exactly 100%.
 */
const RECOMMENDATION_WEIGHTS = {
	interests: 35, // what the student says they enjoy       - the strongest signal
	stream: 20, // whether their A/L stream fits the career
	subjects: 10, // individual A/L subjects, a finer-grained version of stream
	personality: 20, // Analytical / Creative / Social / Practical / Leadership / Organized
	workStyle: 15, // office, remote, fieldwork, laboratory, team-based, independent
};

// How many scoring components exist in total (currently five). Derived from the
// weights so it stays correct if a component is ever added or removed.
const TOTAL_SCORING_COMPONENTS = Object.keys(RECOMMENDATION_WEIGHTS).length;

/**
 * The shape of the input this service scores against.
 *
 * It is a deliberately plain object rather than a Student document, because
 * the Student module is built separately. Today it is filled in by the
 * recommendation form in the app; once real student profiles are available it
 * can be built straight from a Student record (the field names and the allowed
 * values already match the Student model and data/careerOptions.js) without
 * changing any of the scoring logic below.
 *
 * @typedef  {Object}   StudentProfileInput
 * @property {string}   [stream]          One of AL_STREAMS, e.g. 'Science'
 * @property {string[]} [subjects]        A/L subjects, e.g. ['Biology', 'Chemistry']
 * @property {string[]} [interests]       Free-form interests, e.g. ['technology']
 * @property {string}   [personalityType] One of PERSONALITY_TYPES, e.g. 'Analytical'
 * @property {string}   [workStyle]       One of WORK_STYLES, e.g. 'Remote'
 */

/** Lower-cases and trims a list so comparisons ignore case and stray spacing. */
function normaliseList(values) {
	if (!Array.isArray(values)) return [];
	return values.filter((value) => typeof value === 'string').map((value) => value.trim().toLowerCase()).filter(Boolean);
}

/** Lower-cases and trims a single value. */
function normaliseValue(value) {
	return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

/** How many of the student's answers this career covers, as a ratio from 0 to 1. */
function overlapRatio(studentValues, careerValues) {
	if (studentValues.length === 0) return { ratio: 0, matches: [] };
	const careerSet = new Set(careerValues);
	const matches = studentValues.filter((value) => careerSet.has(value));
	return { ratio: matches.length / studentValues.length, matches };
}

/**
 * Normalises a profile once and records which of the five components the
 * student actually answered. Shared by the scorer and by the answered-count so
 * both always agree on what counts as an answer.
 */
function readProfile(profile = {}) {
	const interests = normaliseList(profile.interests);
	const subjects = normaliseList(profile.subjects);
	const stream = normaliseValue(profile.stream);
	const personalityType = normaliseValue(profile.personalityType);
	const workStyle = normaliseValue(profile.workStyle);

	return {
		interests,
		subjects,
		stream,
		personalityType,
		workStyle,
		answered: {
			interests: interests.length > 0,
			stream: Boolean(stream),
			subjects: subjects.length > 0,
			personality: Boolean(personalityType),
			workStyle: Boolean(workStyle),
		},
	};
}

/**
 * How many of the five scoring components the student answered.
 *
 * The results screen shows this as a confidence note ("Based on 3 of 5
 * answers"), so a high percentage from a half-filled form is not mistaken for
 * a stronger result than it is.
 *
 * @param   {StudentProfileInput} profile
 * @returns {number} 0 to TOTAL_SCORING_COMPONENTS
 */
function countAnsweredComponents(profile = {}) {
	return Object.values(readProfile(profile).answered).filter(Boolean).length;
}

/**
 * Scores a single career against one student profile.
 *
 * Only the components the student actually answered take part in the result,
 * and the weights are shared out across those components. A student who fills
 * in nothing but their interests still gets a meaningful percentage, instead of
 * being capped at 35% because the other four components scored zero.
 *
 * @param   {Object}              career
 * @param   {StudentProfileInput} profile
 * @returns {{ score: number, breakdown: Object, reasons: string[] }}
 */
function scoreCareer(career, profile) {
	const { interests, subjects, stream, personalityType, workStyle, answered: isAnswered } = readProfile(profile);

	const interestResult = overlapRatio(interests, normaliseList(career.interestTags));
	const subjectResult = overlapRatio(subjects, normaliseList(career.alSubjects));
	// Matched against the career's own values, which are also used in the
	// reasons below so the wording always shows the proper casing from the
	// career record rather than whatever the student happened to type.
	const matchedStream = stream ? (career.recommendedStreams || []).find((value) => normaliseValue(value) === stream) : undefined;
	const matchedPersonality = personalityType ? (career.personalityTypes || []).find((value) => normaliseValue(value) === personalityType) : undefined;
	const matchedWorkStyle = workStyle ? (career.workStyles || []).find((value) => normaliseValue(value) === workStyle) : undefined;
	const streamMatched = Boolean(matchedStream);
	const personalityMatched = Boolean(matchedPersonality);
	const workStyleMatched = Boolean(matchedWorkStyle);

	const components = [
		{ key: 'interests', weight: RECOMMENDATION_WEIGHTS.interests, answered: isAnswered.interests, ratio: interestResult.ratio },
		{ key: 'stream', weight: RECOMMENDATION_WEIGHTS.stream, answered: isAnswered.stream, ratio: streamMatched ? 1 : 0 },
		{ key: 'subjects', weight: RECOMMENDATION_WEIGHTS.subjects, answered: isAnswered.subjects, ratio: subjectResult.ratio },
		{ key: 'personality', weight: RECOMMENDATION_WEIGHTS.personality, answered: isAnswered.personality, ratio: personalityMatched ? 1 : 0 },
		{ key: 'workStyle', weight: RECOMMENDATION_WEIGHTS.workStyle, answered: isAnswered.workStyle, ratio: workStyleMatched ? 1 : 0 },
	];

	const answered = components.filter((component) => component.answered);
	const availableWeight = answered.reduce((total, component) => total + component.weight, 0);

	// An empty profile cannot rank anything, so every career scores 0 rather
	// than dividing by zero.
	const earned = answered.reduce((total, component) => total + component.ratio * component.weight, 0);
	const score = availableWeight === 0 ? 0 : Math.round((earned / availableWeight) * 100);

	// Per-component contribution, so the UI can explain where a score came from.
	const breakdown = Object.fromEntries(
		components.map((component) => [
			component.key,
			{
				answered: component.answered,
				matched: Math.round(component.ratio * 100),
				points: component.answered ? Math.round(component.ratio * component.weight) : 0,
				maxPoints: component.answered ? component.weight : 0,
			},
		]),
	);

	// Short human-readable reasons, shown on the results screen so a student
	// understands why a career was suggested rather than seeing only a number.
	const reasons = [];
	if (interestResult.matches.length > 0) {
		reasons.push(`Matches ${interestResult.matches.length} of your interests`);
	}
	if (streamMatched) reasons.push(`Suits the ${matchedStream} stream`);
	if (subjectResult.matches.length > 0) {
		reasons.push(`Uses your A/L subjects (${subjectResult.matches.length} matching)`);
	}
	// Phrased without "a"/"an" so every personality type reads correctly.
	if (personalityMatched) reasons.push(`Matches your ${matchedPersonality} personality type`);
	if (workStyleMatched) reasons.push(`Offers ${matchedWorkStyle} work`);

	return { score, breakdown, reasons };
}

/**
 * Ranks every stored career against a student profile, best match first.
 *
 * @param   {StudentProfileInput} profile
 * @param   {{ limit?: number }}  [options]
 * @returns {Promise<Array<{ career: Object, matchPercentage: number, breakdown: Object, reasons: string[] }>>}
 */
async function recommendCareers(profile = {}, options = {}) {
	const careers = await Career.find();

	const ranked = careers
		.map((career) => {
			const { score, breakdown, reasons } = scoreCareer(career, profile);
			return { career, matchPercentage: score, breakdown, reasons };
		})
		// Highest score first; careers on the same score fall back to alphabetical
		// order so the list is stable between identical requests.
		.sort((a, b) => b.matchPercentage - a.matchPercentage || a.career.title.localeCompare(b.career.title));

	return options.limit ? ranked.slice(0, options.limit) : ranked;
}

module.exports = { RECOMMENDATION_WEIGHTS, TOTAL_SCORING_COMPONENTS, countAnsweredComponents, scoreCareer, recommendCareers };
