--[[
	AdminServer.lua
	ALL server-side logic for the Admin Panel in a single Script.
	Place in ServerScriptService.

	Contains (inline):
		- Permission_Service
		- Security_Service
		- Rate_Limiter
		- Log_Service
		- Moderation_Service
		- Player_Manager
		- Settings_Service
		- Remote_Handler
		- Entry point / bootstrap

	This replaces the entire ServerScriptService/AdminPanel/ folder.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared module (Types, Constants, Remotes)
local Shared = require(ReplicatedStorage:WaitForChild("AdminPanel_Shared"))
local Constants = Shared.Constants

-- ============================================================================
-- SECTION 1: PERMISSION SERVICE
-- ============================================================================

local PermissionService = {}

-- Configure starting admins here. Replace 0 with real UserIds.
-- Example: [12345678] = "Owner",
local DEFAULT_WHITELIST: { [number]: string } = {
	 [9600993493] = "Owner",
}

local whitelist: { [number]: string } = {}
local permissionInitialized = false

local function levelOf(role: string?): number
	if role == nil then return 0 end
	local level = Constants.ROLE_LEVELS[role :: any]
	return level or 0
end

function PermissionService.init()
	if permissionInitialized then return end
	for userId, role in pairs(DEFAULT_WHITELIST) do
		whitelist[userId] = role
	end
	permissionInitialized = true
end

function PermissionService.isAdmin(userId: number): boolean
	return whitelist[userId] ~= nil
end

function PermissionService.getRole(userId: number): string?
	return whitelist[userId]
end

function PermissionService.hasPermission(userId: number, action: string): boolean
	local role = whitelist[userId]
	if role == nil then return false end
	local requiredRole = Constants.ACTION_PERMISSIONS[action]
	if requiredRole == nil then return false end
	return levelOf(role) >= levelOf(requiredRole)
end

function PermissionService.getRoleLevel(role: string): number
	return levelOf(role)
end

function PermissionService.getPermittedActions(role: string): { string }
	local roleLevel = levelOf(role)
	local permitted: { string } = {}
	if roleLevel <= 0 then return permitted end
	for action, requiredRole in pairs(Constants.ACTION_PERMISSIONS) do
		if roleLevel >= levelOf(requiredRole) then
			table.insert(permitted, action)
		end
	end
	return permitted
end

function PermissionService.addAdmin(userId: number, role: string)
	whitelist[userId] = role
end

function PermissionService.removeAdmin(userId: number)
	whitelist[userId] = nil
end

-- ============================================================================
-- SECTION 2: SECURITY SERVICE
-- ============================================================================

local SecurityService = {}

local BLOCK_THRESHOLD: number = Constants.SECURITY_BLOCK_THRESHOLD
local BLOCK_DURATION: number = Constants.SECURITY_BLOCK_DURATION
local MAX_STRING: number = Constants.MAX_STRING_INPUT
local MAX_REASON: number = Constants.MAX_REASON_LENGTH
local VIOLATION_WINDOW: number = 30

local securitySessions: { [number]: Shared.SessionData } = {}
local securityViolationTimestamps: { [number]: { number } } = {}
local securityInitialized = false
local securityPlayerRemovingConn: RBXScriptConnection? = nil

-- Per-action payload schemas
type FieldKind = "number" | "string" | "boolean" | "Vector3" | "string_array"
type FieldSpec = { name: string, kind: FieldKind, maxLength: number? }

local SCHEMAS: { [string]: { FieldSpec } } = {
	kick = {
		{ name = "targetUserId", kind = "number" },
		{ name = "reason", kind = "string", maxLength = MAX_REASON },
	},
	ban = {
		{ name = "targetUserId", kind = "number" },
		{ name = "duration", kind = "number" },
		{ name = "reason", kind = "string", maxLength = MAX_REASON },
	},
	mute = {
		{ name = "targetUserId", kind = "number" },
		{ name = "duration", kind = "number" },
	},
	unmute = { { name = "targetUserId", kind = "number" } },
	freeze = { { name = "targetUserId", kind = "number" } },
	unfreeze = { { name = "targetUserId", kind = "number" } },
	teleport = {
		{ name = "targetUserId", kind = "number" },
		{ name = "destination", kind = "Vector3" },
	},
	spectate = { { name = "targetUserId", kind = "number" } },
	give_tools = {
		{ name = "targetUserId", kind = "number" },
		{ name = "toolNames", kind = "string_array", maxLength = MAX_STRING },
	},
}

local function isAllowedControlByte(byte: number): boolean
	return byte == 0x09 or byte == 0x0A or byte == 0x0D
end

local function stringPassesContentChecks(input: string): boolean
	if string.find(input, "\0", 1, true) ~= nil then return false end
	for i = 1, #input do
		local byte = string.byte(input, i)
		if byte < 0x20 and not isAllowedControlByte(byte) then return false end
	end
	return true
end

function SecurityService.validateString(input: string, maxLength: number?): boolean
	if typeof(input) ~= "string" then return false end
	local limit = maxLength or MAX_STRING
	if #input > limit then return false end
	return stringPassesContentChecks(input)
end

local function validateField(payload: { [string]: any }, spec: FieldSpec): (boolean, string?)
	local value = payload[spec.name]
	if value == nil then return false, string.format("missing field '%s'", spec.name) end

	if spec.kind == "number" then
		if typeof(value) ~= "number" then return false, string.format("field '%s' must be a number", spec.name) end
		if value ~= value or value == math.huge or value == -math.huge then
			return false, string.format("field '%s' is not a finite number", spec.name)
		end
		return true, nil
	elseif spec.kind == "boolean" then
		if typeof(value) ~= "boolean" then return false, string.format("field '%s' must be a boolean", spec.name) end
		return true, nil
	elseif spec.kind == "string" then
		if typeof(value) ~= "string" then return false, string.format("field '%s' must be a string", spec.name) end
		if not SecurityService.validateString(value :: string, spec.maxLength) then
			return false, string.format("field '%s' failed string validation", spec.name)
		end
		return true, nil
	elseif spec.kind == "Vector3" then
		if typeof(value) ~= "Vector3" then return false, string.format("field '%s' must be a Vector3", spec.name) end
		local v = value :: Vector3
		for _, c in ipairs({ v.X, v.Y, v.Z }) do
			if c ~= c or c == math.huge or c == -math.huge then
				return false, string.format("field '%s' has non-finite component", spec.name)
			end
		end
		return true, nil
	elseif spec.kind == "string_array" then
		if typeof(value) ~= "table" then return false, string.format("field '%s' must be a table", spec.name) end
		for index, item in ipairs(value :: { any }) do
			if typeof(item) ~= "string" then
				return false, string.format("field '%s'[%d] must be a string", spec.name, index)
			end
			if not SecurityService.validateString(item :: string, spec.maxLength) then
				return false, string.format("field '%s'[%d] failed string validation", spec.name, index)
			end
		end
		return true, nil
	end
	return false, string.format("unknown field kind '%s'", tostring(spec.kind))
end

function SecurityService.init()
	if securityInitialized then return end
	securitySessions = {}
	securityViolationTimestamps = {}
	securityInitialized = true
	if securityPlayerRemovingConn then
		securityPlayerRemovingConn:Disconnect()
	end
	securityPlayerRemovingConn = Players.PlayerRemoving:Connect(function(player: Player)
		SecurityService.cleanupPlayer(player.UserId)
	end)
end

function SecurityService.generateSessionToken(player: Player): string
	local token = HttpService:GenerateGUID(false)
	local existing = securitySessions[player.UserId]
	if existing then
		existing.token = token
		existing.createdAt = os.time()
	else
		securitySessions[player.UserId] = {
			token = token,
			createdAt = os.time(),
			violations = 0,
			blockedUntil = nil,
		}
	end
	return token
end

function SecurityService.validateToken(player: Player, token: string): boolean
	if typeof(token) ~= "string" or token == "" then return false end
	local session = securitySessions[player.UserId]
	if not session then return false end
	return session.token == token
end

function SecurityService.validatePayload(action: string, payload: { [string]: any }): (boolean, string?)
	if typeof(action) ~= "string" or action == "" then return false, "invalid action" end
	if typeof(payload) ~= "table" then return false, "payload must be a table" end
	local schema = SCHEMAS[action]
	if not schema then return false, string.format("unknown action '%s'", action) end
	for _, spec in ipairs(schema) do
		local ok, err = validateField(payload, spec)
		if not ok then return false, err end
	end
	return true, nil
end

function SecurityService.recordViolation(player: Player, action: string, reason: string)
	local userId = player.UserId
	local now = os.time()
	local session = securitySessions[userId]
	if not session then
		session = { token = "", createdAt = now, violations = 0, blockedUntil = nil }
		securitySessions[userId] = session
	end
	local timestamps = securityViolationTimestamps[userId]
	if not timestamps then
		timestamps = {}
		securityViolationTimestamps[userId] = timestamps
	end
	table.insert(timestamps, now)
	local cutoff = now - VIOLATION_WINDOW
	local pruned: { number } = {}
	for _, ts in ipairs(timestamps) do
		if ts >= cutoff then table.insert(pruned, ts) end
	end
	securityViolationTimestamps[userId] = pruned
	session.violations = #pruned
	if session.violations >= BLOCK_THRESHOLD then
		session.blockedUntil = now + BLOCK_DURATION
		securityViolationTimestamps[userId] = {}
		session.violations = 0
	end
end

function SecurityService.isBlocked(player: Player): boolean
	local session = securitySessions[player.UserId]
	if not session then return false end
	local blockedUntil = session.blockedUntil
	if not blockedUntil then return false end
	if os.time() < blockedUntil then return true end
	session.blockedUntil = nil
	return false
end

function SecurityService.cleanupPlayer(userId: number)
	securitySessions[userId] = nil
	securityViolationTimestamps[userId] = nil
end

-- ============================================================================
-- SECTION 3: RATE LIMITER
-- ============================================================================

local RateLimiter = {}

local rateDataByUserId: { [number]: Shared.RateData } = {}
local windowViolationRecorded: { [number]: boolean } = {}
local rateLimiterInitialized = false
local rateLimiterConn: RBXScriptConnection? = nil
local SIXTY_SECONDS = 60

local function rateNow(): number return os.clock() end

local function newRateData(): Shared.RateData
	return {
		windowStart = rateNow(),
		requestCount = 0,
		windowViolations = 0,
		violationTimestamps = {},
		suspendedUntil = nil,
	}
end

local function getRateData(userId: number): Shared.RateData
	local data = rateDataByUserId[userId]
	if data == nil then
		data = newRateData()
		rateDataByUserId[userId] = data
	end
	return data
end

local function pruneRateViolations(data: Shared.RateData, currentTime: number)
	local kept: { number } = {}
	for _, ts in ipairs(data.violationTimestamps) do
		if currentTime - ts < SIXTY_SECONDS then table.insert(kept, ts) end
	end
	data.violationTimestamps = kept
	data.windowViolations = #kept
end

local function clearRateCounters(data: Shared.RateData, currentTime: number)
	data.windowStart = currentTime
	data.requestCount = 0
	data.windowViolations = 0
	data.violationTimestamps = {}
	data.suspendedUntil = nil
end

local function advanceRateState(userId: number, data: Shared.RateData, currentTime: number)
	if data.suspendedUntil ~= nil and currentTime >= data.suspendedUntil then
		clearRateCounters(data, currentTime)
		windowViolationRecorded[userId] = nil
	end
	if data.suspendedUntil == nil then
		if currentTime - data.windowStart >= Constants.WINDOW_DURATION then
			data.windowStart = currentTime
			data.requestCount = 0
			windowViolationRecorded[userId] = nil
		end
	end
	pruneRateViolations(data, currentTime)
end

function RateLimiter.init()
	if rateLimiterInitialized then return end
	rateLimiterInitialized = true
	rateLimiterConn = Players.PlayerRemoving:Connect(function(player: Player)
		rateDataByUserId[player.UserId] = nil
		windowViolationRecorded[player.UserId] = nil
	end)
end

function RateLimiter.checkRate(player: Player): (boolean, string?)
	local userId = player.UserId
	local data = getRateData(userId)
	local currentTime = rateNow()
	advanceRateState(userId, data, currentTime)
	if data.suspendedUntil ~= nil then return false, "suspended" end
	if data.requestCount >= Constants.MAX_REQUESTS_PER_WINDOW then
		if not windowViolationRecorded[userId] then
			windowViolationRecorded[userId] = true
			table.insert(data.violationTimestamps, currentTime)
			pruneRateViolations(data, currentTime)
			if data.windowViolations >= Constants.VIOLATION_THRESHOLD then
				data.suspendedUntil = currentTime + Constants.SUSPENSION_DURATION
				return false, "suspended"
			end
		end
		return false, "throttled"
	end
	return true, nil
end

function RateLimiter.recordRequest(player: Player)
	local userId = player.UserId
	local data = getRateData(userId)
	local currentTime = rateNow()
	advanceRateState(userId, data, currentTime)
	if data.suspendedUntil ~= nil then return end
	data.requestCount += 1
end

function RateLimiter.isSuspended(player: Player): boolean
	local data = rateDataByUserId[player.UserId]
	if data == nil then return false end
	if data.suspendedUntil == nil then return false end
	return rateNow() < data.suspendedUntil
end

function RateLimiter.reset(player: Player)
	local userId = player.UserId
	clearRateCounters(getRateData(userId), rateNow())
	windowViolationRecorded[userId] = nil
end


-- ============================================================================
-- SECTION 4: LOG SERVICE
-- ============================================================================

local LogService = {}

local logBuffer: { Shared.LogEntry } = {}
local logNextId: number = 1
local logWebhookUrl: string? = nil
local logInitialized = false

local MAX_LOG_ENTRIES: number = Constants.MAX_LOG_ENTRIES
local LOG_ENTRIES_PER_PAGE: number = Constants.LOG_ENTRIES_PER_PAGE

local function logMatchesFilter(entry: Shared.LogEntry, filter: Shared.LogFilter): boolean
	if filter.category ~= nil and entry.category ~= filter.category then return false end
	if filter.adminUserId ~= nil and entry.adminUserId ~= filter.adminUserId then return false end
	if filter.actionType ~= nil and entry.actionType ~= filter.actionType then return false end
	return true
end

local function getFilteredLogEntries(filter: Shared.LogFilter?): { Shared.LogEntry }
	local results: { Shared.LogEntry } = {}
	for i = #logBuffer, 1, -1 do
		local entry = logBuffer[i]
		if filter == nil or logMatchesFilter(entry, filter) then
			table.insert(results, entry)
		end
	end
	return results
end

local function sendToWebhook(entry: Shared.LogEntry)
	if logWebhookUrl == nil or logWebhookUrl == "" then return end
	local payload = HttpService:JSONEncode({
		id = entry.id, timestamp = entry.timestamp, category = entry.category,
		adminUserId = entry.adminUserId, adminUsername = entry.adminUsername,
		actionType = entry.actionType, target = entry.target, context = entry.context,
	})
	pcall(function()
		HttpService:PostAsync(logWebhookUrl :: string, payload, Enum.HttpContentType.ApplicationJson, false)
	end)
end

function LogService.init()
	if logInitialized then return end
	logBuffer = {}
	logNextId = 1
	logWebhookUrl = nil
	logInitialized = true
end

function LogService.log(entry: Shared.LogEntry)
	entry.id = logNextId
	logNextId += 1
	if entry.timestamp == 0 or entry.timestamp == nil then entry.timestamp = os.time() end
	if #logBuffer >= MAX_LOG_ENTRIES then table.remove(logBuffer, 1) end
	table.insert(logBuffer, entry)
	sendToWebhook(entry)
end

function LogService.getEntries(page: number, filter: Shared.LogFilter?): { Shared.LogEntry }
	if page < 1 then page = 1 end
	local filtered = getFilteredLogEntries(filter)
	local startIndex = (page - 1) * LOG_ENTRIES_PER_PAGE + 1
	local endIndex = math.min(page * LOG_ENTRIES_PER_PAGE, #filtered)
	if startIndex > #filtered then return {} end
	local results: { Shared.LogEntry } = {}
	for i = startIndex, endIndex do table.insert(results, filtered[i]) end
	return results
end

function LogService.getPageCount(filter: Shared.LogFilter?): number
	local filtered = getFilteredLogEntries(filter)
	if #filtered == 0 then return 0 end
	return math.ceil(#filtered / LOG_ENTRIES_PER_PAGE)
end

function LogService.setWebhookUrl(url: string?)
	logWebhookUrl = url
end

-- ============================================================================
-- SECTION 5: MODERATION SERVICE
-- ============================================================================

local ModerationService = {}

type MuteRecord = {
	targetUserId: number,
	duration: number,
	issuedAt: number,
	issuerId: number,
}

local modBanStore: DataStore? = nil
local modMutes: { [number]: MuteRecord } = {}
local modLog: { Shared.ModLogEntry } = {}
local modInitialized = false

local MOD_LOG_PER_PAGE: number = Constants.MOD_LOG_PER_PAGE

local VALID_BAN_DURATIONS: { number } = {
	Constants.BAN_1_HOUR, Constants.BAN_24_HOURS, Constants.BAN_7_DAYS,
	Constants.BAN_30_DAYS, Constants.BAN_PERMANENT,
}
local VALID_MUTE_DURATIONS: { number } = {
	Constants.MUTE_5_MIN, Constants.MUTE_30_MIN, Constants.MUTE_1_HOUR,
	Constants.MUTE_24_HOURS, Constants.MUTE_7_DAYS,
}

local function isValidBanDuration(duration: number): boolean
	for _, v in ipairs(VALID_BAN_DURATIONS) do if duration == v then return true end end
	return false
end

local function isValidMuteDuration(duration: number): boolean
	for _, v in ipairs(VALID_MUTE_DURATIONS) do if duration == v then return true end end
	return false
end

local function getBanKey(userId: number): string
	return "ban_" .. tostring(userId)
end

local function resolveUsername(userId: number): string
	local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	return if ok and name then name else "Unknown"
end

local function filterModLog(log: { Shared.ModLogEntry }, filter: Shared.ModLogFilter?): { Shared.ModLogEntry }
	if not filter then return log end
	local filtered: { Shared.ModLogEntry } = {}
	for _, entry in ipairs(log) do
		local matches = true
		if filter.actionType and filter.actionType ~= "" and entry.actionType ~= filter.actionType then matches = false end
		if matches and filter.adminUserId and entry.adminUserId ~= filter.adminUserId then matches = false end
		if matches then table.insert(filtered, entry) end
	end
	return filtered
end

local function addModLogEntry(entry: Shared.ModLogEntry)
	table.insert(modLog, 1, entry)
end

function ModerationService.init()
	if modInitialized then return end
	modMutes = {}
	modLog = {}
	modInitialized = true
	local ok, store = pcall(function() return DataStoreService:GetDataStore("AdminPanel_Bans") end)
	if ok and store then modBanStore = store
	else modBanStore = nil; warn("[ModerationService] Failed to acquire DataStore.") end
end

function ModerationService.issueBan(targetUserId: number, duration: number, reason: string, issuerId: number): Shared.ActionResult
	if not isValidBanDuration(duration) then
		return { success = false, error = "Invalid ban duration", errorCode = "INVALID_DURATION" }
	end
	if #reason > Constants.MAX_REASON_LENGTH then
		return { success = false, error = "Reason too long", errorCode = "REASON_TOO_LONG" }
	end
	local now = os.time()
	local banData = { reason = reason, duration = duration, issuedAt = now, issuerId = issuerId }
	if modBanStore then
		local ok, err = pcall(function() (modBanStore :: DataStore):SetAsync(getBanKey(targetUserId), banData) end)
		if not ok then return { success = false, error = "Failed to persist ban: " .. tostring(err), errorCode = "DATASTORE_ERROR" } end
	else
		return { success = false, error = "DataStore unavailable", errorCode = "DATASTORE_UNAVAILABLE" }
	end
	addModLogEntry({
		timestamp = now, actionType = "ban", adminUserId = issuerId,
		adminUsername = resolveUsername(issuerId), targetUserId = targetUserId,
		targetUsername = resolveUsername(targetUserId), reason = reason, duration = duration,
	})
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		local msg = if duration == Constants.BAN_PERMANENT
			then "You have been permanently banned. Reason: " .. reason
			else string.format("You have been banned for %d seconds. Reason: %s", duration, reason)
		targetPlayer:Kick(msg)
	end
	return { success = true, data = { targetUserId = targetUserId, duration = duration, reason = reason } }
end

function ModerationService.revokeBan(targetUserId: number): Shared.ActionResult
	if not modBanStore then return { success = false, error = "DataStore unavailable", errorCode = "DATASTORE_UNAVAILABLE" } end
	local ok, err = pcall(function() (modBanStore :: DataStore):RemoveAsync(getBanKey(targetUserId)) end)
	if not ok then return { success = false, error = "Failed to revoke ban: " .. tostring(err), errorCode = "DATASTORE_ERROR" } end
	addModLogEntry({
		timestamp = os.time(), actionType = "unban", adminUserId = 0,
		adminUsername = "System", targetUserId = targetUserId,
		targetUsername = resolveUsername(targetUserId), reason = "Ban revoked",
	})
	return { success = true, data = { targetUserId = targetUserId } }
end

function ModerationService.isBanned(userId: number): (boolean, Shared.BanRecord?)
	if not modBanStore then return false, nil end
	local ok, data = pcall(function() return (modBanStore :: DataStore):GetAsync(getBanKey(userId)) end)
	if not ok or not data then return false, nil end
	local banData = data :: { [string]: any }
	local record: Shared.BanRecord = {
		targetUserId = userId, reason = banData.reason or "", duration = banData.duration or 0,
		issuedAt = banData.issuedAt or 0, issuerId = banData.issuerId or 0,
	}
	if record.duration == Constants.BAN_PERMANENT then return true, record end
	if os.time() >= record.issuedAt + record.duration then
		pcall(function() (modBanStore :: DataStore):RemoveAsync(getBanKey(userId)) end)
		return false, nil
	end
	return true, record
end

function ModerationService.issueMute(targetUserId: number, duration: number, issuerId: number): Shared.ActionResult
	if not isValidMuteDuration(duration) then
		return { success = false, error = "Invalid mute duration", errorCode = "INVALID_DURATION" }
	end
	local now = os.time()
	modMutes[targetUserId] = { targetUserId = targetUserId, duration = duration, issuedAt = now, issuerId = issuerId }
	addModLogEntry({
		timestamp = now, actionType = "mute", adminUserId = issuerId,
		adminUsername = resolveUsername(issuerId), targetUserId = targetUserId,
		targetUsername = resolveUsername(targetUserId), duration = duration,
	})
	return { success = true, data = { targetUserId = targetUserId, duration = duration } }
end

function ModerationService.isMuted(userId: number): boolean
	local rec = modMutes[userId]
	if not rec then return false end
	if os.time() >= rec.issuedAt + rec.duration then modMutes[userId] = nil; return false end
	return true
end

function ModerationService.getModLog(page: number, filter: Shared.ModLogFilter?): { Shared.ModLogEntry }
	if page < 1 then page = 1 end
	local entries = filterModLog(modLog, filter)
	local startIndex = (page - 1) * MOD_LOG_PER_PAGE + 1
	local endIndex = math.min(startIndex + MOD_LOG_PER_PAGE - 1, #entries)
	if startIndex > #entries then return {} end
	local result: { Shared.ModLogEntry } = {}
	for i = startIndex, endIndex do table.insert(result, entries[i]) end
	return result
end

function ModerationService.getModLogPageCount(filter: Shared.ModLogFilter?): number
	local entries = filterModLog(modLog, filter)
	if #entries == 0 then return 0 end
	return math.ceil(#entries / MOD_LOG_PER_PAGE)
end


-- ============================================================================
-- SECTION 6: PLAYER MANAGER
-- ============================================================================

local PlayerManager = {}

local frozenPlayers: { [number]: boolean } = {}
local playerManagerInitialized = false

local function isConnected(player: Player): boolean
	return player.Parent ~= nil
end

local function getHumanoidRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then return nil end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function PlayerManager.init()
	if playerManagerInitialized then return end
	frozenPlayers = {}
	playerManagerInitialized = true
end

function PlayerManager.kick(target: Player, reason: string): Shared.ActionResult
	if not isConnected(target) then
		return { success = false, error = "Target player is no longer connected", errorCode = "target_disconnected" }
	end
	target:Kick(reason)
	return { success = true, data = { targetUserId = target.UserId, targetUsername = target.Name, action = "kick", reason = reason } }
end

function PlayerManager.ban(targetUserId: number, duration: number, reason: string, issuerId: number): Shared.ActionResult
	return ModerationService.issueBan(targetUserId, duration, reason, issuerId)
end

function PlayerManager.mute(target: Player, duration: number): Shared.ActionResult
	if not isConnected(target) then
		return { success = false, error = "Target player is no longer connected", errorCode = "target_disconnected" }
	end
	return ModerationService.issueMute(target.UserId, duration, 0)
end

function PlayerManager.unmute(target: Player): Shared.ActionResult
	if not isConnected(target) then
		return { success = false, error = "Target player is no longer connected", errorCode = "target_disconnected" }
	end
	-- Clear mute
	if ModerationService.isMuted(target.UserId) then
		modMutes[target.UserId] = nil
		return { success = true, data = { targetUserId = target.UserId, targetUsername = target.Name, action = "unmute" } }
	end
	return { success = false, error = "Player is not currently muted", errorCode = "not_muted" }
end

function PlayerManager.freeze(target: Player): Shared.ActionResult
	if not isConnected(target) then
		return { success = false, error = "Target player is no longer connected", errorCode = "target_disconnected" }
	end
	local rootPart = getHumanoidRootPart(target)
	if not rootPart then
		return { success = false, error = "Target has no HumanoidRootPart", errorCode = "no_character" }
	end
	rootPart.Anchored = true
	frozenPlayers[target.UserId] = true
	return { success = true, data = { targetUserId = target.UserId, targetUsername = target.Name, action = "freeze" } }
end

function PlayerManager.unfreeze(target: Player): Shared.ActionResult
	if not isConnected(target) then
		return { success = false, error = "Target player is no longer connected", errorCode = "target_disconnected" }
	end
	local rootPart = getHumanoidRootPart(target)
	if not rootPart then
		return { success = false, error = "Target has no HumanoidRootPart", errorCode = "no_character" }
	end
	rootPart.Anchored = false
	frozenPlayers[target.UserId] = nil
	return { success = true, data = { targetUserId = target.UserId, targetUsername = target.Name, action = "unfreeze" } }
end

function PlayerManager.teleport(target: Player, destination: Vector3): Shared.ActionResult
	if not isConnected(target) then
		return { success = false, error = "Target player is no longer connected", errorCode = "target_disconnected" }
	end
	local rootPart = getHumanoidRootPart(target)
	if not rootPart then
		return { success = false, error = "Target has no HumanoidRootPart", errorCode = "no_character" }
	end
	rootPart.CFrame = CFrame.new(destination)
	return { success = true, data = { targetUserId = target.UserId, targetUsername = target.Name, action = "teleport", destination = { X = destination.X, Y = destination.Y, Z = destination.Z } } }
end

function PlayerManager.spectate(admin: Player, target: Player): Shared.ActionResult
	if not isConnected(target) then
		return { success = false, error = "Target player is no longer connected", errorCode = "target_disconnected" }
	end
	if not isConnected(admin) then
		return { success = false, error = "Admin player is no longer connected", errorCode = "admin_disconnected" }
	end
	local targetCharacter = target.Character
	if not targetCharacter then
		return { success = false, error = "Target has no character", errorCode = "no_character" }
	end
	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return { success = false, error = "Target has no Humanoid", errorCode = "no_character" }
	end
	admin.CameraSubject = humanoid
	return { success = true, data = { adminUserId = admin.UserId, targetUserId = target.UserId, targetUsername = target.Name, action = "spectate" } }
end

function PlayerManager.giveTools(target: Player, toolNames: { string }): Shared.ActionResult
	if not isConnected(target) then
		return { success = false, error = "Target player is no longer connected", errorCode = "target_disconnected" }
	end
	local backpack = target:FindFirstChildOfClass("Backpack")
	if not backpack then
		return { success = false, error = "Target has no Backpack", errorCode = "no_backpack" }
	end
	local toolsFolder: Instance = ServerStorage:FindFirstChild("Tools") or ServerStorage
	local givenTools: { string } = {}
	local failedTools: { string } = {}
	for _, toolName in ipairs(toolNames) do
		local toolTemplate = toolsFolder:FindFirstChild(toolName)
		if toolTemplate and toolTemplate:IsA("Tool") then
			local clone = toolTemplate:Clone()
			clone.Parent = backpack
			table.insert(givenTools, toolName)
		else
			table.insert(failedTools, toolName)
		end
	end
	if #givenTools == 0 and #failedTools > 0 then
		return { success = false, error = "No valid tools found: " .. table.concat(failedTools, ", "), errorCode = "tools_not_found" }
	end
	return { success = true, data = { targetUserId = target.UserId, targetUsername = target.Name, action = "give_tools", givenTools = givenTools, failedTools = failedTools } }
end

function PlayerManager.getPlayerInfo(target: Player): Shared.PlayerInfo
	local position: Vector3? = nil
	local rootPart = getHumanoidRootPart(target)
	if rootPart then position = rootPart.Position end
	local ping: number = 0
	local success, result = pcall(function() return target:GetNetworkPing() end)
	if success then ping = result end
	return { username = target.Name, userId = target.UserId, accountAge = target.AccountAge, joinTime = os.time(), ping = ping, position = position }
end

-- ============================================================================
-- SECTION 7: SETTINGS SERVICE
-- ============================================================================

local SettingsService = {}

local settingsDataStore: DataStore? = nil
local settingsInitialized = false
local SETTINGS_DATASTORE_NAME = "AdminPanel_Settings"
local SETTINGS_KEY_PREFIX = "settings_"
local MIN_NOTIFICATION_DURATION = 3
local MAX_NOTIFICATION_DURATION = 15
local VALID_SIDEBAR_STATES: { [string]: boolean } = { expanded = true, collapsed = true }
local VALID_KEYBIND_ACTIONS: { [string]: boolean } = { togglePanel = true, commandPalette = true }

local function createDefaultSettings(): Shared.AdminSettings
	return {
		accentColor = Color3.fromRGB(70, 115, 255),
		glassmorphism = false,
		notificationDuration = 5,
		sidebarDefaultState = "expanded",
		keybinds = { togglePanel = Enum.KeyCode.F2, commandPalette = Enum.KeyCode.K },
	}
end

local function serializeColor3(color: Color3): { number }
	return { color.R, color.G, color.B }
end

local function deserializeColor3(data: any): Color3?
	if typeof(data) ~= "table" then return nil end
	local arr = data :: { any }
	if #arr < 3 then return nil end
	local r, g, b = arr[1], arr[2], arr[3]
	if typeof(r) ~= "number" or typeof(g) ~= "number" or typeof(b) ~= "number" then return nil end
	return Color3.new(math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
end

local function serializeKeyCode(keyCode: Enum.KeyCode): string
	return keyCode.Name
end

local function deserializeKeyCode(name: string): Enum.KeyCode?
	if typeof(name) ~= "string" then return nil end
	local success2, result2 = pcall(function() return (Enum.KeyCode :: any)[name] end)
	if success2 and result2 ~= nil then return result2 :: Enum.KeyCode end
	return nil
end

function SettingsService.init()
	if settingsInitialized then return end
	local ok, store = pcall(function() return DataStoreService:GetDataStore(SETTINGS_DATASTORE_NAME) end)
	if ok and store then settingsDataStore = store
	else settingsDataStore = nil; warn("[Settings_Service] Failed to initialize DataStore.") end
	settingsInitialized = true
end

function SettingsService.getDefaults(): Shared.AdminSettings
	return createDefaultSettings()
end

function SettingsService.validateSettings(settings: Shared.AdminSettings): (boolean, string?)
	if typeof(settings.accentColor) ~= "Color3" then return false, "accentColor must be a valid Color3" end
	if typeof(settings.glassmorphism) ~= "boolean" then return false, "glassmorphism must be a boolean" end
	if typeof(settings.notificationDuration) ~= "number" then return false, "notificationDuration must be a number" end
	if settings.notificationDuration < MIN_NOTIFICATION_DURATION or settings.notificationDuration > MAX_NOTIFICATION_DURATION then
		return false, string.format("notificationDuration must be between %d and %d", MIN_NOTIFICATION_DURATION, MAX_NOTIFICATION_DURATION)
	end
	if typeof(settings.sidebarDefaultState) ~= "string" then return false, "sidebarDefaultState must be a string" end
	if not VALID_SIDEBAR_STATES[settings.sidebarDefaultState] then return false, "sidebarDefaultState must be 'expanded' or 'collapsed'" end
	if typeof(settings.keybinds) ~= "table" then return false, "keybinds must be a table" end
	for action, keyCode in pairs(settings.keybinds) do
		if not VALID_KEYBIND_ACTIONS[action] then return false, string.format("unknown keybind action '%s'", tostring(action)) end
		if typeof(keyCode) ~= "EnumItem" then return false, string.format("keybind '%s' must be a valid Enum.KeyCode", tostring(action)) end
	end
	for action, _ in pairs(VALID_KEYBIND_ACTIONS) do
		if settings.keybinds[action] == nil then return false, string.format("missing keybind for action '%s'", action) end
	end
	return true, nil
end

function SettingsService.loadSettings(userId: number): (Shared.AdminSettings?, string?)
	if not settingsDataStore then return createDefaultSettings(), nil end
	local key = SETTINGS_KEY_PREFIX .. tostring(userId)
	local ok, result = pcall(function() return (settingsDataStore :: DataStore):GetAsync(key) end)
	if not ok then return createDefaultSettings(), "Failed to load settings" end
	if result == nil then return createDefaultSettings(), nil end
	if typeof(result) ~= "table" then return createDefaultSettings(), "Settings data corrupted" end
	local persisted = result :: { [string]: any }
	local accentColor = deserializeColor3(persisted.accentColor)
	if not accentColor then return createDefaultSettings(), "Invalid accent color" end
	if typeof(persisted.glassmorphism) ~= "boolean" then return createDefaultSettings(), nil end
	if typeof(persisted.notificationDuration) ~= "number" then return createDefaultSettings(), nil end
	if typeof(persisted.sidebarDefaultState) ~= "string" or not VALID_SIDEBAR_STATES[persisted.sidebarDefaultState] then
		return createDefaultSettings(), nil
	end
	local keybinds: { [string]: Enum.KeyCode } = {}
	local defaults = createDefaultSettings()
	if typeof(persisted.keybinds) == "table" then
		for action, keyCodeName in pairs(persisted.keybinds :: { [string]: string }) do
			if VALID_KEYBIND_ACTIONS[action] then
				local kc = deserializeKeyCode(keyCodeName)
				if kc then keybinds[action] = kc end
			end
		end
	end
	for action, _ in pairs(VALID_KEYBIND_ACTIONS) do
		if not keybinds[action] then keybinds[action] = defaults.keybinds[action] end
	end
	return {
		accentColor = accentColor :: Color3,
		glassmorphism = persisted.glassmorphism,
		notificationDuration = persisted.notificationDuration,
		sidebarDefaultState = persisted.sidebarDefaultState :: "expanded" | "collapsed",
		keybinds = keybinds,
	}, nil
end

function SettingsService.saveSettings(userId: number, settings: Shared.AdminSettings): (boolean, string?)
	local valid, validErr = SettingsService.validateSettings(settings)
	if not valid then return false, "Validation failed: " .. (validErr or "unknown") end
	if not settingsDataStore then return false, "DataStore unavailable" end
	local key = SETTINGS_KEY_PREFIX .. tostring(userId)
	local serializedKeybinds: { [string]: string } = {}
	for action, keyCode in pairs(settings.keybinds) do
		serializedKeybinds[action] = serializeKeyCode(keyCode)
	end
	local serialized = {
		version = 1,
		accentColor = serializeColor3(settings.accentColor),
		glassmorphism = settings.glassmorphism,
		notificationDuration = settings.notificationDuration,
		sidebarDefaultState = settings.sidebarDefaultState,
		keybinds = serializedKeybinds,
	}
	local ok, err = pcall(function() (settingsDataStore :: DataStore):SetAsync(key, serialized) end)
	if not ok then return false, "Failed to save settings: " .. tostring(err) end
	return true, nil
end


-- ============================================================================
-- SECTION 8: REMOTE HANDLER
-- ============================================================================

local RemoteHandler = {}

type ActionHandler = (player: Player, payload: { [string]: any }) -> Shared.ActionResult

local remoteHandlerInitialized = false
local remotes: Shared.Remotes = nil :: any
local actionHandlers: { [string]: ActionHandler } = {}
local connectedAdmins: { [number]: boolean } = {}
local serverStartTime: number = os.clock()
local statsLoopConnection: RBXScriptConnection? = nil

local function collectServerStats(): Shared.ServerStats
	local playerCount = #Players:GetPlayers()
	local maxPlayers = Players.MaxPlayers
	local serverFps: number = 60
	pcall(function() serverFps = workspace:GetRealPhysicsFPS() end)
	local memoryUsage: number = 0
	pcall(function() memoryUsage = (game:GetService("Stats") :: any):GetTotalMemoryUsageMb() end)
	local totalPing: number = 0
	local pingCount: number = 0
	for _, p in ipairs(Players:GetPlayers()) do
		local ok2, ping = pcall(function() return p:GetNetworkPing() end)
		if ok2 then totalPing += ping; pingCount += 1 end
	end
	local averagePing: number = if pingCount > 0 then (totalPing / pingCount) * 1000 else 0
	local uptime: number = os.clock() - serverStartTime
	local moderationCount: number = 0
	pcall(function() moderationCount = ModerationService.getModLogPageCount(nil) * Constants.MOD_LOG_PER_PAGE end)
	return {
		playerCount = playerCount, maxPlayers = maxPlayers, serverFps = math.floor(serverFps),
		averagePing = math.floor(averagePing), memoryUsage = math.floor(memoryUsage),
		uptime = math.floor(uptime), moderationCount = moderationCount,
	}
end

local function logAction(player: Player, actionType: string, category: Shared.LogCategory, target: string?, context: { [string]: any }?)
	LogService.log({
		id = 0, timestamp = os.time(), category = category,
		adminUserId = player.UserId, adminUsername = player.Name,
		actionType = actionType, target = target, context = context,
	} :: Shared.LogEntry)
end

local function registerDefaultActions()
	actionHandlers["kick"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId :: number)
		if not targetPlayer then return { success = false, error = "Target not in server", errorCode = "target_not_found" } end
		local result = PlayerManager.kick(targetPlayer, payload.reason :: string)
		if result.success then logAction(player, "kick", "player_action", tostring(payload.targetUserId), { reason = payload.reason, targetUsername = targetPlayer.Name }) end
		return result
	end

	actionHandlers["ban"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local result = PlayerManager.ban(payload.targetUserId :: number, payload.duration :: number, payload.reason :: string, player.UserId)
		if result.success then logAction(player, "ban", "moderation", tostring(payload.targetUserId), { reason = payload.reason, duration = payload.duration }) end
		return result
	end

	actionHandlers["mute"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId :: number)
		if not targetPlayer then return { success = false, error = "Target not in server", errorCode = "target_not_found" } end
		local result = PlayerManager.mute(targetPlayer, payload.duration :: number)
		if result.success then logAction(player, "mute", "moderation", tostring(payload.targetUserId), { duration = payload.duration }) end
		return result
	end

	actionHandlers["unmute"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId :: number)
		if not targetPlayer then return { success = false, error = "Target not in server", errorCode = "target_not_found" } end
		local result = PlayerManager.unmute(targetPlayer)
		if result.success then logAction(player, "unmute", "moderation", tostring(payload.targetUserId), nil) end
		return result
	end

	actionHandlers["freeze"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId :: number)
		if not targetPlayer then return { success = false, error = "Target not in server", errorCode = "target_not_found" } end
		local result = PlayerManager.freeze(targetPlayer)
		if result.success then logAction(player, "freeze", "player_action", tostring(payload.targetUserId), nil) end
		return result
	end

	actionHandlers["unfreeze"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId :: number)
		if not targetPlayer then return { success = false, error = "Target not in server", errorCode = "target_not_found" } end
		local result = PlayerManager.unfreeze(targetPlayer)
		if result.success then logAction(player, "unfreeze", "player_action", tostring(payload.targetUserId), nil) end
		return result
	end

	actionHandlers["teleport"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId :: number)
		if not targetPlayer then return { success = false, error = "Target not in server", errorCode = "target_not_found" } end
		local result = PlayerManager.teleport(targetPlayer, payload.destination :: Vector3)
		if result.success then logAction(player, "teleport", "player_action", tostring(payload.targetUserId), { destination = { X = (payload.destination :: Vector3).X, Y = (payload.destination :: Vector3).Y, Z = (payload.destination :: Vector3).Z } }) end
		return result
	end

	actionHandlers["spectate"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId :: number)
		if not targetPlayer then return { success = false, error = "Target not in server", errorCode = "target_not_found" } end
		local result = PlayerManager.spectate(player, targetPlayer)
		if result.success then logAction(player, "spectate", "player_action", tostring(payload.targetUserId), nil) end
		return result
	end

	actionHandlers["give_tools"] = function(player: Player, payload: { [string]: any }): Shared.ActionResult
		local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId :: number)
		if not targetPlayer then return { success = false, error = "Target not in server", errorCode = "target_not_found" } end
		local result = PlayerManager.giveTools(targetPlayer, payload.toolNames :: { string })
		if result.success then logAction(player, "give_tools", "player_action", tostring(payload.targetUserId), { toolNames = payload.toolNames }) end
		return result
	end
end

local function handleRequest(player: Player, action: string, payload: { [string]: any }, token: string): Shared.ActionResult
	if not PermissionService.isAdmin(player.UserId) then
		logAction(player, action, "security_event", nil, { reason = "not_whitelisted" })
		return { success = false, error = "Access denied", errorCode = "not_whitelisted" }
	end
	local rateOk, rateReason = RateLimiter.checkRate(player)
	if not rateOk then
		logAction(player, action, "security_event", nil, { reason = "rate_limited", detail = rateReason })
		return { success = false, error = "Rate limited: " .. (rateReason or "throttled"), errorCode = "rate_limited" }
	end
	RateLimiter.recordRequest(player)
	if SecurityService.isBlocked(player) then
		logAction(player, action, "security_event", nil, { reason = "security_blocked" })
		return { success = false, error = "Access temporarily blocked", errorCode = "security_blocked" }
	end
	if not SecurityService.validateToken(player, token) then
		SecurityService.recordViolation(player, action, "invalid_token")
		logAction(player, action, "security_event", nil, { reason = "invalid_token" })
		return { success = false, error = "Invalid session token", errorCode = "invalid_token" }
	end
	local payloadOk, payloadErr = SecurityService.validatePayload(action, payload)
	if not payloadOk then
		SecurityService.recordViolation(player, action, "invalid_payload: " .. (payloadErr or ""))
		logAction(player, action, "security_event", nil, { reason = "invalid_payload", detail = payloadErr })
		return { success = false, error = "Invalid payload: " .. (payloadErr or "unknown"), errorCode = "invalid_payload" }
	end
	if not PermissionService.hasPermission(player.UserId, action) then
		logAction(player, action, "security_event", nil, { reason = "insufficient_permissions" })
		return { success = false, error = "Insufficient permissions", errorCode = "insufficient_permissions" }
	end
	local handler = actionHandlers[action]
	if not handler then return { success = false, error = "Unknown action: " .. action, errorCode = "unknown_action" } end
	return handler(player, payload)
end

local function startStatsPushLoop()
	local elapsed: number = 0
	statsLoopConnection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < Constants.STATS_UPDATE_INTERVAL then return end
		elapsed = 0
		local hasAdmins = false
		for _ in pairs(connectedAdmins) do hasAdmins = true; break end
		if not hasAdmins then return end
		local stats = collectServerStats()
		for userId in pairs(connectedAdmins) do
			local adminPlayer = Players:GetPlayerByUserId(userId)
			if adminPlayer then
				remotes.Stats_Update:FireClient(adminPlayer, stats)
			else
				connectedAdmins[userId] = nil
			end
		end
	end)
end

function RemoteHandler.fireAccessRevoked(player: Player)
	connectedAdmins[player.UserId] = nil
	remotes.Access_Revoked:FireClient(player)
	logAction(player, "access_revoked", "security_event", tostring(player.UserId), nil)
end

function RemoteHandler.init()
	if remoteHandlerInitialized then return end
	remoteHandlerInitialized = true
	remotes = Shared.getRemotes()
	registerDefaultActions()

	remotes.Admin_Request.OnServerEvent:Connect(function(player: Player, action: any, payload: any, token: any)
		if typeof(action) ~= "string" then return end
		if typeof(payload) ~= "table" then payload = {} end
		if typeof(token) ~= "string" then token = "" end
		local result = handleRequest(player, action, payload, token)
		remotes.Admin_Response:FireClient(player, result)
	end)

	remotes.Panel_Init.OnServerInvoke = function(player: Player): any
		if not PermissionService.isAdmin(player.UserId) then
			logAction(player, "panel_init", "security_event", nil, { reason = "not_whitelisted" })
			return nil
		end
		local token = SecurityService.generateSessionToken(player)
		local role = PermissionService.getRole(player.UserId)
		if not role then return nil end
		local settings, _ = SettingsService.loadSettings(player.UserId)
		local permittedActions = PermissionService.getPermittedActions(role)
		connectedAdmins[player.UserId] = true
		logAction(player, "panel_init", "system_event", nil, { role = role })
		return { token = token, role = role, settings = settings, permittedActions = permittedActions }
	end

	remotes.Get_Players.OnServerInvoke = function(player: Player, token: any): any
		if typeof(token) ~= "string" or not SecurityService.validateToken(player, token :: string) then
			SecurityService.recordViolation(player, "get_players", "invalid_token"); return nil
		end
		if not PermissionService.isAdmin(player.UserId) then return nil end
		local playerList: { Shared.PlayerInfo } = {}
		for _, p in ipairs(Players:GetPlayers()) do table.insert(playerList, PlayerManager.getPlayerInfo(p)) end
		return playerList
	end

	remotes.Get_ModLog.OnServerInvoke = function(player: Player, token: any, page: any, filter: any): any
		if typeof(token) ~= "string" or not SecurityService.validateToken(player, token :: string) then
			SecurityService.recordViolation(player, "get_modlog", "invalid_token"); return nil
		end
		if not PermissionService.isAdmin(player.UserId) then return nil end
		local pageNum: number = if typeof(page) == "number" and page >= 1 then math.floor(page) else 1
		local modFilter: Shared.ModLogFilter? = if typeof(filter) == "table" then filter :: Shared.ModLogFilter else nil
		return { entries = ModerationService.getModLog(pageNum, modFilter), page = pageNum, pageCount = ModerationService.getModLogPageCount(modFilter) }
	end

	remotes.Get_Logs.OnServerInvoke = function(player: Player, token: any, page: any, filter: any): any
		if typeof(token) ~= "string" or not SecurityService.validateToken(player, token :: string) then
			SecurityService.recordViolation(player, "get_logs", "invalid_token"); return nil
		end
		if not PermissionService.isAdmin(player.UserId) then return nil end
		local pageNum: number = if typeof(page) == "number" and page >= 1 then math.floor(page) else 1
		local logFilter: Shared.LogFilter? = if typeof(filter) == "table" then filter :: Shared.LogFilter else nil
		return { entries = LogService.getEntries(pageNum, logFilter), page = pageNum, pageCount = LogService.getPageCount(logFilter) }
	end

	remotes.Save_Settings.OnServerInvoke = function(player: Player, token: any, settings: any): any
		if typeof(token) ~= "string" or not SecurityService.validateToken(player, token :: string) then
			SecurityService.recordViolation(player, "save_settings", "invalid_token")
			return { success = false, error = "Invalid session token", errorCode = "invalid_token" }
		end
		if not PermissionService.isAdmin(player.UserId) then
			return { success = false, error = "Access denied", errorCode = "not_whitelisted" }
		end
		if typeof(settings) ~= "table" then
			return { success = false, error = "Invalid settings data", errorCode = "invalid_settings" }
		end
		local valid, validErr = SettingsService.validateSettings(settings :: Shared.AdminSettings)
		if not valid then return { success = false, error = validErr or "Invalid settings", errorCode = "validation_failed" } end
		local saveOk, saveErr = SettingsService.saveSettings(player.UserId, settings :: Shared.AdminSettings)
		if not saveOk then return { success = false, error = saveErr or "Save failed", errorCode = "save_failed" } end
		logAction(player, "save_settings", "system_event", nil, nil)
		return { success = true }
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		connectedAdmins[player.UserId] = nil
	end)

	startStatsPushLoop()
end

-- ============================================================================
-- SECTION 9: ENTRY POINT / BOOTSTRAP
-- ============================================================================

PermissionService.init()
SecurityService.init()
RateLimiter.init()
LogService.init()
ModerationService.init()
PlayerManager.init()
SettingsService.init()
RemoteHandler.init()

-- PlayerAdded: ban check and admin detection
local function onPlayerAdded(player: Player)
	local isBanned, banRecord = ModerationService.isBanned(player.UserId)
	if isBanned and banRecord then
		local reason = banRecord.reason or "No reason provided"
		local kickMessage: string
		if banRecord.duration == Constants.BAN_PERMANENT then
			kickMessage = string.format("You are permanently banned from this server.\nReason: %s", reason)
		else
			local now = os.time()
			local expiresAt = banRecord.issuedAt + banRecord.duration
			local remaining = math.max(0, expiresAt - now)
			local hours = math.floor(remaining / 3600)
			local minutes = math.floor((remaining % 3600) / 60)
			local durationStr: string
			if hours > 24 then durationStr = string.format("%d day(s)", math.floor(hours / 24))
			elseif hours > 0 then durationStr = string.format("%d hour(s), %d minute(s)", hours, minutes)
			else durationStr = string.format("%d minute(s)", minutes) end
			kickMessage = string.format("You are banned from this server.\nReason: %s\nRemaining: %s", reason, durationStr)
		end
		player:Kick(kickMessage)
		return
	end
	-- Admin detection: session init happens via Panel_Init RemoteFunction
end

local function onPlayerRemoving(_player: Player)
	-- Cleanup handled by individual services
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players who joined before this script ran (Studio fast-start)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
