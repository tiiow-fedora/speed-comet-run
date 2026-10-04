--!strict
-- Per-player, per-remote token bucket.

local RateLimit = {}

type Bucket = { tokens: number, last: number }
local buckets: { [Player]: { [string]: Bucket } } = {}

-- Allows `rate` calls per second with bursts up to `burst`.
function RateLimit.allow(player: Player, name: string, rate: number, burst: number): boolean
	local pb = buckets[player]
	if not pb then
		pb = {}
		buckets[player] = pb
	end
	local now = os.clock()
	local b = pb[name]
	if not b then
		b = { tokens = burst, last = now }
		pb[name] = b
	end
	b.tokens = math.min(burst, b.tokens + (now - b.last) * rate)
	b.last = now
	if b.tokens >= 1 then
		b.tokens -= 1
		return true
	end
	return false
end

function RateLimit.clear(player: Player)
	buckets[player] = nil
end

return RateLimit
