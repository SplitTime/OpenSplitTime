// Device-local store of watched effort ids, keyed by event group.
// All access is wrapped so environments without localStorage (private
// browsing modes, embedded webviews) degrade to no persistence.

const keyFor = (groupId) => `ost:watches:event-group:${groupId}`

export function watchedEffortIds(groupId) {
  try {
    const raw = localStorage.getItem(keyFor(groupId))
    const ids = raw ? JSON.parse(raw) : []
    return Array.isArray(ids) ? ids.map(Number).filter(Number.isFinite) : []
  } catch {
    return []
  }
}

export function effortWatched(groupId, effortId) {
  return watchedEffortIds(groupId).includes(Number(effortId))
}

export function toggleWatchedEffort(groupId, effortId) {
  const id = Number(effortId)
  const ids = watchedEffortIds(groupId)
  const updated = ids.includes(id) ? ids.filter((existing) => existing !== id) : [...ids, id]
  write(groupId, updated)
  return updated
}

export function mergeWatchedEfforts(groupId, effortIds) {
  const incoming = effortIds.map(Number).filter(Number.isFinite)
  const updated = [...new Set([...watchedEffortIds(groupId), ...incoming])]
  write(groupId, updated)
  return updated
}

export function clearWatchedEfforts(groupId) {
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
