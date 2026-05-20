--[[
	AdminPanel_Shared.lua
	Combined shared module: Types + Constants + Remotes bootstrap.
	Place in ReplicatedStorage as a ModuleScript.

	This single module replaces:
		- ReplicatedStorage/Shared/Types.lua
		- ReplicatedStorage/Shared/Constants.lua
		- ReplicatedStorage/Shared/Remotes.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AdminPanel_Shared = {}

-- ============================================================================
-- SECTION 1: TYPES
-- ============================================================================

export type Role = "Owner" | "Super_Admin" | "Admin" | "Moderator"
export type TabName = "Dashboard" | "Players" | "Moderation" | "Server" | "Logs" | "Settings"
export type LogCategory = "player_action" | "moderation" | "security_event" | "system_event"
export type NotificationCategory = "success" | "error" | "warning" | "info"

export type ActionResult = {
	success: boolean,
	data: { [string]: any }?,
	error: string?,
	errorCode: string?,
}

export type ActionPayload = {
	action: string,
	target: number?,
	params: { [string]: any }?,
}

export type ServerStats = {
	playerCount: number,
	maxPlayers: number,
	serverFps: number,
	averagePing: number,
	memoryUsage: number,
	uptime: number,
	moderationCount: number,
}

export type PlayerInfo = {
	username: string,
	userId: number,
	accountAge: number,
	joinTime: number,
	ping: number,
	position: Vector3?,
}

export type AdminSettings = {
	accentColor: Color3,
	glassmorphism: boolean,
	notificationDuration: number,
	sidebarDefaultState: "expanded" | "collapsed",
	keybinds: { [string]: Enum.KeyCode },
}

export type BanRecord = {
	targetUserId: number,
	reason: string,
	duration: number,
	issuedAt: number,
	issuerId: number,
}

export type ModLogEntry = {
	timestamp: number,
	actionType: string,
	adminUserId: number,
	adminUsername: string,
	targetUserId: number?,
	targetUsername: string?,
	reason: string?,
	duration: number?,
}

export type ModLogFilter = {
	actionType: string?,
	adminUserId: number?,
}

export type LogEntry = {
	id: number,
	timestamp: number,
	category: LogCategory,
	adminUserId: number,
	adminUsername: string,
	actionType: string,
	target: string?,
	context: { [string]: any }?,
}

export type LogFilter = {
	category: LogCategory?,
	adminUserId: number?,
	actionType: string?,
}

export type StoredNotification = {
	id: number,
	category: NotificationCategory,
	message: string,
	timestamp: number,
	read: boolean,
}

export type NotificationConfig = {
	category: NotificationCategory,
	message: string,
	duration: number?,
}

export type ModalConfig = {
	title: string,
	message: string,
	confirmText: string?,
	cancelText: string?,
	destructive: boolean?,
}

export type CommandEntry = {
	name: string,
	icon: string,
	shortcut: string?,
	action: string,
	requiresTarget: boolean,
	minimumRole: Role,
}

export type SessionData = {
	token: string,
	createdAt: number,
	violations: number,
	blockedUntil: number?,
}

export type RateData = {
	windowStart: number,
	requestCount: number,
	windowViolations: number,
	violationTimestamps: { number },
	suspendedUntil: number?,
}

-- ============================================================================
-- SECTION 2: CONSTANTS
-- ============================================================================

export type RoleLevels = {
	Owner: number,
	Super_Admin: number,
	Admin: number,
	Moderator: number,
}

export type ActionPermissions = { [string]: Role }

AdminPanel_Shared.Constants = {
	-- Rate Limiting
	MAX_REQUESTS_PER_WINDOW = 15,
	WINDOW_DURATION = 10,
	VIOLATION_THRESHOLD = 3,
	SUSPENSION_DURATION = 30,
	SECURITY_BLOCK_THRESHOLD = 5,
	SECURITY_BLOCK_DURATION = 60,

	-- Logging
	MAX_LOG_ENTRIES = 1000,
	LOG_ENTRIES_PER_PAGE = 50,
	WEBHOOK_TIMEOUT = 5,

	-- Notifications
	MAX_STORED_NOTIFICATIONS = 50,
	MAX_UNREAD_DISPLAY = 9,

	-- Moderation
	MOD_LOG_PER_PAGE = 50,
	MAX_REASON_LENGTH = 500,
	MAX_STRING_INPUT = 200,

	-- UI
	STATS_UPDATE_INTERVAL = 3,
	STALE_DATA_TIMEOUT = 10,
	SEARCH_MAX_RESULTS = 10,
	USERNAME_MAX_DISPLAY = 20,

	-- Animation Durations (seconds)
	ANIM_VIEW_TRANSITION = 0.3,
	ANIM_FADE_HALF = 0.15,
	ANIM_NOTIFICATION_IN = 0.25,
	ANIM_NOTIFICATION_OUT = 0.2,
	ANIM_PANEL_OPEN = 0.35,
	ANIM_PANEL_CLOSE = 0.25,
	ANIM_MODAL = 0.2,
	ANIM_SIDEBAR_TOGGLE = 0.25,
	ANIM_HOVER = 0.15,
	ANIM_VALUE_TWEEN = 0.4,
	ANIM_COMMAND_PALETTE = 0.2,
	ANIM_TOOLTIP_SHOW = 0.4,
	ANIM_TOOLTIP_HIDE = 0.2,
	ANIM_DISMISS = 0.15,

	-- Ban Durations (seconds)
	BAN_1_HOUR = 3600,
	BAN_24_HOURS = 86400,
	BAN_7_DAYS = 604800,
	BAN_30_DAYS = 2592000,
	BAN_PERMANENT = -1,

	-- Mute Durations (seconds)
	MUTE_5_MIN = 300,
	MUTE_30_MIN = 1800,
	MUTE_1_HOUR = 3600,
	MUTE_24_HOURS = 86400,
	MUTE_7_DAYS = 604800,

	-- Role hierarchy levels (higher = more privileged)
	ROLE_LEVELS = {
		Owner = 4,
		Super_Admin = 3,
		Admin = 2,
		Moderator = 1,
	} :: RoleLevels,

	-- Action name -> minimum required role
	ACTION_PERMISSIONS = {
		mute = "Moderator",
		freeze = "Moderator",
		kick = "Admin",
		teleport = "Admin",
		give_tools = "Admin",
		spectate = "Admin",
		ban = "Super_Admin",
		server_command = "Super_Admin",
		manage_admins = "Owner",
	} :: ActionPermissions,
}

table.freeze(AdminPanel_Shared.Constants.ROLE_LEVELS)
table.freeze(AdminPanel_Shared.Constants.ACTION_PERMISSIONS)
table.freeze(AdminPanel_Shared.Constants)

-- ============================================================================
-- SECTION 3: REMOTES BOOTSTRAP
-- ============================================================================

type RemoteKind = "RemoteEvent" | "RemoteFunction"

type RemoteDef = {
	name: string,
	kind: RemoteKind,
}

local REMOTE_DEFS: { RemoteDef } = {
	{ name = "Admin_Request",  kind = "RemoteEvent" },
	{ name = "Admin_Response", kind = "RemoteEvent" },
	{ name = "Stats_Update",   kind = "RemoteEvent" },
	{ name = "Panel_Init",     kind = "RemoteFunction" },
	{ name = "Get_Players",    kind = "RemoteFunction" },
	{ name = "Get_ModLog",     kind = "RemoteFunction" },
	{ name = "Get_Logs",       kind = "RemoteFunction" },
	{ name = "Save_Settings",  kind = "RemoteFunction" },
	{ name = "Access_Revoked", kind = "RemoteEvent" },
}

export type Remotes = {
	Folder: Folder,
	Admin_Request: RemoteEvent,
	Admin_Response: RemoteEvent,
	Stats_Update: RemoteEvent,
	Panel_Init: RemoteFunction,
	Get_Players: RemoteFunction,
	Get_ModLog: RemoteFunction,
	Get_Logs: RemoteFunction,
	Save_Settings: RemoteFunction,
	Access_Revoked: RemoteEvent,
}

local FOLDER_NAME = "AdminPanel_Remotes"
local CLIENT_WAIT_TIMEOUT = 10

local function getOrCreateFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if folder == nil then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		assert(folder:IsA("Folder"), "ReplicatedStorage." .. FOLDER_NAME .. " exists but is not a Folder")
		return folder
	else
		local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, CLIENT_WAIT_TIMEOUT)
		assert(folder ~= nil, "Remotes folder did not replicate within " .. tostring(CLIENT_WAIT_TIMEOUT) .. "s")
		assert(folder:IsA("Folder"), "ReplicatedStorage." .. FOLDER_NAME .. " is not a Folder")
		return folder
	end
end

local function getOrCreateRemote(folder: Folder, def: RemoteDef): Instance
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(def.name)
		if existing ~= nil then
			assert(
				existing.ClassName == def.kind,
				string.format("Remote %q exists but has type %s, expected %s", def.name, existing.ClassName, def.kind)
			)
			return existing
		end
		local instance = Instance.new(def.kind)
		instance.Name = def.name
		instance.Parent = folder
		return instance
	else
		local instance = folder:WaitForChild(def.name, CLIENT_WAIT_TIMEOUT)
		assert(instance ~= nil, string.format("Remote %q did not replicate within %ds", def.name, CLIENT_WAIT_TIMEOUT))
		assert(
			instance.ClassName == def.kind,
			string.format("Remote %q replicated as %s, expected %s", def.name, instance.ClassName, def.kind)
		)
		return instance
	end
end

local function buildRemotes(): Remotes
	local folder = getOrCreateFolder()
	local result: { [string]: any } = { Folder = folder }
	for _, def in ipairs(REMOTE_DEFS) do
		result[def.name] = getOrCreateRemote(folder, def)
	end
	return (result :: any) :: Remotes
end

local cachedRemotes: Remotes? = nil

function AdminPanel_Shared.getRemotes(): Remotes
	if cachedRemotes == nil then
		cachedRemotes = buildRemotes()
	end
	return cachedRemotes :: Remotes
end

return AdminPanel_Shared
