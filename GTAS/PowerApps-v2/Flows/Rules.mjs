// Executable policy reference for the flow implementation and acceptance checks.
// This module is not automatically executed by Power Automate.
export function requireCondition(condition, message) {
  if (!condition) throw new Error(message);
}
const normalized = value => String(value || '').trim().toLowerCase();
export function day(value) {
  requireCondition(/^\d{4}-\d{2}-\d{2}$/.test(value), 'Invalid ISO date');
  const timestamp = Date.parse(value + 'T00:00:00Z');
  requireCondition(Number.isFinite(timestamp) && new Date(timestamp).toISOString().slice(0, 10) === value, 'Invalid calendar date');
  return timestamp / 86400000;
}
function amount(value) {
  requireCondition(typeof value === 'number' && Number.isFinite(value) && value >= 0, 'Amounts must be finite and nonnegative');
  return value;
}
const rounded = value => Math.round((value + Number.EPSILON) * 100) / 100;
export function hasRole(actor, programKey, permission) {
  return actor.assignments.some(entry => entry.enabled && entry.programKey === programKey && entry[permission] === true);
}
export function canRead(actor, request) {
  return normalized(actor.email) === normalized(request.ownerEmail) ||
    hasRole(actor, request.programKey, 'coordinate') ||
    hasRole(actor, request.programKey, 'report') ||
    normalized(actor.email) === normalized(request.assignedEmail);
}
export function calculate(snapshot, rates, policy) {
  const h = snapshot.header;
  requireCondition(policy?.enabled && policy.programKey === h.programKey, 'Program policy unavailable');
  const departure = day(h.departure), end = day(h.returnDate);
  requireCondition(['Same-Day', 'Overnight'].includes(h.tripType), 'Invalid trip type');
  requireCondition(h.tripType === 'Same-Day' ? departure === end : departure < end, 'Invalid trip dates');
  const stops = [...snapshot.destinations].sort((a, b) => a.start.localeCompare(b.start));
  requireCondition(stops.length && stops[0].start === h.departure, 'Itinerary must begin on departure date');
  requireCondition(new Set(stops.map(s => s.start)).size === stops.length, 'Duplicate destination date');
  let lodging = 0, mie = 0;
  for (const [i, stop] of stops.entries()) {
    requireCondition(stop.city?.trim() && stop.region?.trim(), 'Destination required');
    const start = day(stop.start);
    requireCondition(start >= departure && start <= end, 'Destination outside trip dates');
    if (h.tripType === 'Same-Day') continue;
    const next = i + 1 < stops.length ? day(stops[i + 1].start) : end + 1;
    const rate = rates.find(rate => rate.id === stop.rateId);
    requireCondition(rate && rate.currency === 'USD' && rate.source, 'Approved USD rate required');
    requireCondition(normalized(rate.city) === normalized(stop.city) && normalized(rate.region) === normalized(stop.region), 'Rate locality mismatch');
    requireCondition(start >= day(rate.effectiveFrom) && next - 1 <= day(rate.effectiveTo), 'Rate does not cover destination dates');
    requireCondition(amount(stop.quote) <= amount(rate.lodging) || stop.justification?.trim(), 'Above-rate justification required');
    lodging += Math.max(0, Math.min(next, end) - start) * amount(rate.lodging);
    const fraction = next - start - (start === departure ? .25 : 0) - (next === end + 1 ? .25 : 0);
    mie += fraction * amount(rate.mie);
  }
  if (h.tripType === 'Same-Day') {
    requireCondition(typeof policy.sameDayMieAllowed === 'boolean', 'Same-day policy requires a decision');
    mie = policy.sameDayMieAllowed ? amount(policy.sameDayMieAmount) : 0;
  }
  let transportation = 0;
  if (h.air) {
    requireCondition(['Parking', 'Uber', 'Taxi', 'Shuttle', 'Dropped Off', 'Public Transit'].includes(h.airportMethod), 'Invalid airport transportation');
    transportation += amount(h.airfare) + (h.airportMethod === 'Dropped Off'
      ? amount(h.dropMiles) * amount(policy.mileageRate) : amount(h.airportCost));
  }
  if (h.pov) transportation += amount(h.miles) * amount(policy.mileageRate);
  if (h.rental) transportation += amount(h.rentalCost) + amount(h.fuel);
  if (h.rail) transportation += amount(h.railCost);
  if (h.pov || h.rental) transportation += amount(h.tolls);
  const extras = amount(h.registration) + amount(h.misc) +
    (h.tripType === 'Overnight' ? amount(h.hotelParking) + amount(h.resortFees) : 0);
  const parts = {lodging: rounded(lodging), mie: rounded(mie), transportation: rounded(transportation), extras: rounded(extras)};
  return {...parts, total: rounded(Object.values(parts).reduce((sum, n) => sum + n, 0))};
}
export function validateSubmission(actor, snapshot, rates, policy, existing = null) {
  const h = snapshot.header;
  requireCondition(snapshot.schemaVersion === 2, 'Unsupported payload version');
  requireCondition(actor.email && actor.assignments, 'Authenticated actor required');
  requireCondition(h.traveler?.trim() && h.supervisor?.trim() && h.purpose?.trim() && h.programKey?.trim(), 'Required fields missing');
  const email = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  requireCondition(email.test(h.ownerEmail), 'Traveler sign-in email required');
  requireCondition(!h.contactEmail || email.test(h.contactEmail), 'Contact email invalid');
  requireCondition(['GDIT', 'Subcontractor'].includes(h.organization), 'Organization invalid');
  requireCondition(h.organization !== 'Subcontractor' || h.company?.trim(), 'Subcontractor company required');
  requireCondition(['Domestic', 'International'].includes(h.region), 'Travel region invalid');
  const categories = h.categories.split(',').map(x => x.trim());
  requireCondition(categories.length && categories.every(x => ['Conference', 'Meeting', 'Site Visit', 'Training', 'Other'].includes(x)), 'Travel category invalid');
  requireCondition(normalized(h.ownerEmail) === normalized(actor.email) || hasRole(actor, h.programKey, 'coordinate'), 'Cannot submit for another traveler');
  if (existing) {
    requireCondition(existing.status === 'Returned' && existing.cycle === snapshot.expectedCycle, 'Stale or non-returned revision');
    requireCondition(existing.id === snapshot.parentRequestId && normalized(existing.ownerEmail) === normalized(h.ownerEmail) && existing.programKey === h.programKey, 'Revision ownership or program changed');
  } else requireCondition(snapshot.parentRequestId === 0 && snapshot.expectedCycle === 0, 'Missing parent request');
  return calculate(snapshot, rates, policy);
}
export function decision(actor, request, payload, routing) {
  requireCondition(request.cycle === payload.expectedCycle && request.status === payload.expectedStage, 'Stale decision');
  requireCondition(normalized(actor.email) === normalized(request.assignedEmail), 'Decision is not assigned to this user');
  const next = {'Program Manager': 'IT OPS', 'Coordinator Review': 'IT OPS', 'IT OPS': 'COR', 'COR': 'Approved'};
  requireCondition(next[request.status], 'Request is not awaiting a decision');
  let status;
  switch (payload.outcome) {
    case 'Approve': status = next[request.status]; break;
    case 'Return': status = 'Returned'; break;
    case 'Reject': status = 'Rejected'; break;
    case 'Delegate':
      requireCondition(request.status === 'Program Manager', 'Only Program Manager can delegate');
      status = 'Coordinator Review'; break;
    default: throw new Error('Invalid decision');
  }
  requireCondition(routing.itOps && routing.cor && normalized(routing.itOps) !== normalized(routing.cor), 'Distinct IT OPS and COR assignments required');
  const targets = {'IT OPS': routing.itOps, 'COR': routing.cor, 'Coordinator Review': routing.coordinator};
  requireCondition(!targets[status] || emailPresent(targets[status]), 'Assignment missing');
  if (status === 'Coordinator Review') requireCondition(emailPresent(routing.coordinator), 'Coordinator assignment missing');
  return {status, assignedEmail: targets[status] || '', comment: String(payload.comment || '')};
}
function emailPresent(value) { return typeof value === 'string' && value.includes('@'); }
export function closeout(actor, request, operation, payload, today) {
  requireCondition(hasRole(actor, request.programKey, 'coordinate'), 'Coordinator access required');
  requireCondition(request.cycle === payload.expectedCycle, 'Stale request cycle');
  if (operation === 'Complete') {
    requireCondition(request.status === 'Approved' && day(request.returnDate) <= day(today), 'Travel has not concluded');
    return {status: 'Travel Completed'};
  }
  requireCondition(operation === 'Close' && request.status === 'Travel Completed', 'Invalid closeout state');
  requireCondition(day(payload.posted) <= day(today) && day(payload.posted) >= day(request.returnDate), 'Posting date outside allowed range');
  return {status: 'Closed', actual: amount(payload.actual), posted: payload.posted, notes: String(payload.notes || '')};
}
