local E, _, V, P, G = unpack(ElvUI)
local EP = E.Libs.EP
local addonName, addon = ...

local _G = _G
local find = string.find
local GetAddOnMetadata = GetAddOnMetadata
local GetBuildInfo = GetBuildInfo
local select = select
local tonumber = tonumber

local TXUI = E:NewModule(addonName, "AceConsole-3.0", "AceTimer-3.0", "AceHook-3.0")

V.TXUI = {}
P.TXUI = {}
G.TXUI = {}

local F = {}
local I = {}

addon[1] = TXUI
addon[2] = F
addon[3] = E
addon[4] = I
addon[5] = V.TXUI
addon[6] = P.TXUI
addon[7] = G.TXUI
_G[addonName] = addon

TXUI.AddOnName = addonName
TXUI.GitHash = GetAddOnMetadata(addonName, "X-GitHash")
TXUI.DevRelease = false
TXUI.DevTag = ""
TXUI.DelayedWorldEntered = false
TXUI.MetaFlavor = GetAddOnMetadata(addonName, "X-Flavor")
TXUI.ClientBuildVersion = select(4, GetBuildInfo())

TXUI.IsClassic = TXUI.MetaFlavor == "Vanilla"
TXUI.IsTBC = TXUI.MetaFlavor == "TBC"
TXUI.IsWrath = TXUI.MetaFlavor == "Wrath"
TXUI.IsRetail = TXUI.MetaFlavor == "Mainline"

TXUI.IsDragonflight = TXUI.IsRetail and TXUI.ClientBuildVersion >= 100000
TXUI.IsShadowlands = TXUI.IsRetail and not TXUI.IsDragonflight
TXUI.IsWrathOrRetail = TXUI.IsRetail or TXUI.IsWrathClassic

TXUI.Modules = {}
TXUI.Modules.Changelog = TXUI:NewModule("Changelog", "AceEvent-3.0", "AceTimer-3.0")
TXUI.Modules.Options = TXUI:NewModule("Options")
TXUI.Modules.Skins = TXUI:NewModule("Skins", "AceHook-3.0", "AceEvent-3.0")

-- Initialization
function TXUI:Initialize()
  -- Don't init second time
  if self.initialized then return end

  -- Set correct flavor
  local flavorMap = {
    ["Vanilla"] = I.Enum.Flavor.CLASSIC,
    ["TBC"] = I.Enum.Flavor.TBC,
    ["Wrath"] = I.Enum.Flavor.WRATH,
    ["Mainline"] = I.Enum.Flavor.RETAIL,
  }

  self.Flavor = flavorMap[self.MetaFlavor] or I.Enum.Flavor.RETAIL

  -- Set Log level
  self.LogLevel = 3

  -- Call pre init for ourselfs
  self:ModulePreInitialize(self)

  -- Mark dev release
  if self.GitHash then
    if find(self.GitHash, "alpha") then
      self.DevTag = F.String.Error("[ALPHA]")
    elseif find(self.GitHash, "beta") then
      self.DevTag = F.String.Error("[BETA]")
    elseif find(self.GitHash, "project%-version") then
      self.GitHash = "DEV" -- will be filled by changelog
      self.DevTag = F.String.Error("[DEV]")
    end

    self.DevRelease = (self.DevTag ~= "")
    self.LogLevel = 4
  end

  -- Check required ElvUI Version
  local ElvUIVersion = tonumber(E.version)
  local RequiredVersion = tonumber(GetAddOnMetadata(self.AddOnName, "X-ElvUIVersion"))

  -- ElvUI's version check
  if ElvUIVersion < 1 or (ElvUIVersion < RequiredVersion) then
    E:Delay(2, function()
      E:StaticPopup_Show("ELVUI_UPDATE_AVAILABLE")
    end)
    return
  end

  -- Check for non Wrath, non Retail
  if not self.IsRetail and not self.IsWrath then return end

  -- Check for DF if not Dev version
  if self.IsDragonflight and not self.DevRelease then return end

  -- Force ElvUI Setup to hide
  E.private.install_complete = E.version

  -- Set the correct tables for Flavor
  if self.IsWrath then
    I.HearthstoneData = I.HearthstoneData_Wrath
    I.InterruptSpellMap = I.InterruptSpellMap_Wrath
  end

  -- Lets go!
  self:InitializeModules()

  -- Register Plugin
  EP:RegisterPlugin(self.AddOnName, function()
    return self:GetModule("Options"):OptionsCallback()
  end)

  -- Monitor ElvUI Profile updated
  E.data.RegisterCallback(self, "OnProfileChanged", "UpdateProfiles")
  E.data.RegisterCallback(self, "OnProfileCopied", "UpdateProfiles")
  E.data.RegisterCallback(self, "OnProfileReset", "UpdateProfiles")
end

EP:HookInitialize(TXUI, TXUI.Initialize)
