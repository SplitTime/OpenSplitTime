// Device-local store of highlighted effort ids, keyed by event group.
// All access is wrapped so environments without localStorage (private
// browsing modes, embedded webviews) degrade to no persistence.

const keyFor = (groupId) => `ost:highlights:event-group:${groupId}`

export function highlightedEffortIds(groupId) {
  try {
    const raw = localStorage.getItem(keyFor(groupId))
    const ids = raw ? JSON.parse(raw) : []
    return Array.isArray(ids) ? ids.map(Number).filter(Number.isFinite) : []
  } catch {
    return []
  }
}

export function effortHighlighted(groupId, effortId) {
  return highlightedEffortIds(groupId).includes(Number(effortId))
}

export function toggleHighlightedEffort(groupId, effortId) {
  const id = Number(effortId)
  const ids = highlightedEffortIds(groupId)
  const updated = ids.includes(id) ? ids.filter((existing) => existing !== id) : [...ids, id]
  write(groupId, updated)
  return updated
}

export function mergeHighlightedEfforts(groupId, effortIds) {
  const incoming = effortIds.map(Number).filter(Number.isFinite)
  const updated = [...new Set([...highlightedEffortIds(groupId), ...incoming])]
  write(groupId, updated)
  return updated
}

export function clearHighlightedEfforts(groupId) {
  try {
    localStorage.removeItem(keyFor(groupId))
  } catch {
    // no persistence available
  }
}

function write(groupId, ids) {
  try {
    localStorage.setItem(keyFor(groupId), JSON.stringify(ids))
  } catch {
    // no persistence available
  }
}
