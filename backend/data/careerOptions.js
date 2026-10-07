/**
 * Shared option lists for the Career module.
 *
 * Kept in one file so the Career model, the recommendation service and the
 * admin/recommendation forms in the Flutter app all validate against exactly
 * the same vocabulary. Follows the same pattern as data/personalityTypes.js.
 */

// A/L streams offered in Sri Lankan schools. Deliberately identical to the
// `stream` enum on the Student model, so that recommendation input can later be
// populated straight from a real student profile without any value mapping.
const AL_STREAMS = ['Science', 'Mathematics', 'Commerce', 'Arts', 'Technology'];

// Personality categories produced by the personality test. The test stores its
// scores in lowercase keys (see data/personalityTypes.js); these are the
// display-cased equivalents used for career tagging and matching.
const PERSONALITY_TYPES = ['Analytical', 'Creative', 'Social', 'Leadership', 'Practical', 'Organized'];

// How a person spends a typical working day in this career. Used both as a
// career tag and as the "preferred work style" answer in the recommendation form.
const WORK_STYLES = ['Office-based', 'Remote', 'Fieldwork', 'Laboratory', 'Team-based', 'Independent'];

// Demand for this career in the Sri Lankan job market over the coming years.
const JOB_OUTLOOKS = ['Very High', 'High', 'Medium', 'Low'];

module.exports = { AL_STREAMS, PERSONALITY_TYPES, WORK_STYLES, JOB_OUTLOOKS };
