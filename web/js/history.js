// Past results, kept oldest first. Mirrors Sources/TalentFinderCore/ResultHistory.swift.
// A result is identified by its completedAt timestamp (an ISO string, so it sorts by time).

const byTime = (a, b) => (a.completedAt < b.completedAt ? -1 : a.completedAt > b.completedAt ? 1 : 0);

export function adding(result, history) {
  return [...history.filter((r) => r.completedAt !== result.completedAt), result].sort(byTime);
}

export function removing(id, history) {
  return history.filter((r) => r.completedAt !== id);
}

export function scoreFor(result, aptitude) {
  return result.scores.find((s) => s.aptitude === aptitude)?.score ?? 0;
}

/** How much each aptitude moved between the two most recent results, or null with fewer than two. */
export function latestChange(history, aptitudes) {
  if (history.length < 2) return null;
  const now = history[history.length - 1], before = history[history.length - 2];
  return Object.fromEntries(aptitudes.map((a) => [a, scoreFor(now, a) - scoreFor(before, a)]));
}

/** History to use on load. Earlier versions saved one result only; that becomes the first entry. */
export function migrate(savedHistory, oldResult) {
  if (Array.isArray(savedHistory)) return savedHistory.slice().sort(byTime);
  return oldResult ? [oldResult] : [];
}
