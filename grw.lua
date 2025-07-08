local addonName = "grw"
GRW_DB = GRW_DB or {}
local previousMembers = {}
local pendingAction = nil

-- Utility
local function DebugPrint(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[" .. addonName .. "]|r " .. msg)
end

-- Table length helper
local function TableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Capture current guild members into a table
local function GetCurrentGuildMembers()
    local members = {}
	
    local totalMembers = GetNumGuildMembers()
	
    DebugPrint("Scanning guild roster: " .. totalMembers .. " total members")
    for i = 1, totalMembers do
        local name = GetGuildRosterInfo(i)
        if name then
            members[name] = true
        end
    end
    return members
end

-- Save current members to SavedVariables
local function WriteDownCurrentMembersToSavedVariables()
    GRW_DB = GetCurrentGuildMembers()
    DebugPrint("Saved current guild members: " .. TableLength(GRW_DB))
end

-- Compare current guild members with saved data
local function CompareGuildRoster()
    local current = GetCurrentGuildMembers()
    local previous = GRW_DB or {}
    local added, removed = 0, 0

    for name in pairs(current) do
        if not previous[name] then
            DebugPrint("+++++ Player joined: " .. name)
            added = added + 1
        end
    end

    for name in pairs(previous) do
        if not current[name] then
            DebugPrint("----- Player left: " .. name)
            removed = removed + 1
        end
    end

    if added == 0 and removed == 0 then
        DebugPrint("No changes detected.")
    end
end

local function EnsureShowOffline()
    if SetGuildRosterShowOffline and GetGuildRosterShowOffline then
        if not GetGuildRosterShowOffline() then
            SetGuildRosterShowOffline(true)
        end
    end
end

-- Event handler
local function OnEvent()
    if event == "ADDON_LOADED" and arg1 == addonName then
        DebugPrint("Loaded. Use /grw write or /grw check.")
        previousMembers = GRW_DB or {}
    elseif event == "GUILD_ROSTER_UPDATE" and pendingAction then
        if pendingAction == "write" then
            WriteDownCurrentMembersToSavedVariables()
        elseif pendingAction == "check" then
            CompareGuildRoster()
        end
        pendingAction = nil
    end
end

-- Create the frame and register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:SetScript("OnEvent", OnEvent)

-- Slash commands
SLASH_GRW1 = "/grw"
SlashCmdList["GRW"] = function(args)
   if args == "write" then
        DebugPrint("Requesting roster to save current members...")
        pendingAction = "write"
		EnsureShowOffline()
        GuildRoster()
    elseif args == "check" then
        DebugPrint("Requesting roster to compare members...")
        pendingAction = "check"
		EnsureShowOffline()
        GuildRoster()
    else
        DebugPrint("Usage:")
        DebugPrint("/grw write  - Save current guild members")
        DebugPrint("/grw check  - Check for member changes")
    end
end
