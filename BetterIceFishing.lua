local addonName, addon = ...
local internal = {
  -- Internal Settings for later use
	debug = false,
  clear_override = false,
	binding_set = false,
}

local bif_Frame = CreateFrame("frame")
local isDragonflight = select(4,GetBuildInfo()) > 99999
if not isDragonflight then return end

local soundSettingsBackup = {}
local SoundCVars = {
	"Sound_EnableAllSound",
	"Sound_EnableAmbience",
	"Sound_EnablePetSounds",
	"Sound_EnableSFX",
	"Sound_EnableSoundWhenGameIsInBG",
	"Sound_MasterVolume",
	"Sound_MusicVolume",
	"Sound_SFXVolume",
}

BINDING_NAME_BETTERICEFISHINGKEY = "Fish and Interact"
local binding = "BETTERICEFISHINGKEY"

function addon:DebugPrint(text)
  if internal.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000BIF Debug\[|r"..text.."|cffff8000\]")
  end
end

function addon:GetFishingCastID()
  return 377895
end

function addon:GetFishingName()
  return GetSpellInfo(377895)
end

function addon:GetUnitID()
  local guid = UnitGUID("mouseover") or ""
	return tonumber(guid:match("-(%d+)-%x+$"), 10) or 0
end

local function IsTaintable()
  return (InCombatLockdown() or (UnitAffectingCombat("player") or UnitAffectingCombat("pet")))
end

function addon:IsFishing()
  local spellID = select(8, UnitChannelInfo("player"))
  if spellID == self:GetFishingCastID() then
    return true
  end
  return false
end

function addon:AllowIceFishing()
  if IsPlayerMoving() or IsMounted() or IsFlying() or IsFalling() or IsStealthed() or IsSwimming() or IsSubmerged() or (not HasFullControl()) or UnitHasVehicleUI("player") then
    return false
  end

	if IsInInstance() and (GetNumGroupMembers() > 1) then
		return false
	end

  if (UnitChannelInfo("player") ~= nil) then
    return false
  end

  return true
end

local cachedSoftTargetInteract = GetCVar("SoftTargetInteract");
local cachedSoftTargetInteractArc = GetCVar("SoftTargetInteractArc");
local cachedSoftTargetInteractRange = GetCVar("SoftTargetInteractRange");
local cachedSoftTargetIconGameObject = GetCVar("SoftTargetIconGameObject");
local cachedSoftTargetIconInteract= GetCVar("SoftTargetIconInteract");

function addon:ResetCVars()
  addon:EnhanceSounds()
  SetCVar("SoftTargetInteract", cachedSoftTargetInteract);
  SetCVar("SoftTargetInteractArc", cachedSoftTargetInteractArc);
  SetCVar("SoftTargetInteractRange", cachedSoftTargetInteractRange);
  SetCVar("SoftTargetIconInteract", cachedSoftTargetIconInteract);
  SetCVar("SoftTargetIconGameObject", cachedSoftTargetIconGameObject);
end

function addon:SetCVars()
  addon:EnhanceSounds(true)
  cachedSoftTargetInteract = GetCVar("SoftTargetInteract");
  cachedSoftTargetInteractArc = GetCVar("SoftTargetInteractArc");
  cachedSoftTargetInteractRange = GetCVar("SoftTargetInteractRange");
  cachedSoftTargetIconGameObject = GetCVar("SoftTargetIconGameObject");
  cachedSoftTargetIconInteract = GetCVar("SoftTargetIconInteract");
  SetCVar("SoftTargetInteract", 3);
  SetCVar("SoftTargetInteractArc", 2);
  SetCVar("SoftTargetInteractRange", 15);
  SetCVar("SoftTargetIconGameObject", BetterIceFishingDB.objectIconDisabled and 0 or 1);
  SetCVar("SoftTargetIconInteract", BetterIceFishingDB.objectIconDisabled and 0 or 1);
end

function addon:IsMouseOverIceFishingHole()
	local guid = UnitGUID("mouseover") or ""
	local id = tonumber(guid:match("-(%d+)-%x+$"), 10)
	return id and (id == 192631 or id == 197596)
end

function addon:SetInteractMouseOver()
	if IsAddOnLoaded("BetterFishing") and BetterIceFishingDB.useBetterFishingKey then
		binding = "BETTERFISHINGKEY"
	else
		binding = "BETTERICEFISHINGKEY"
	end
	local key1, key2 = GetBindingKey(binding)
	if key1 then
		SetOverrideBinding(bif_Frame, true, key1, "INTERACTMOUSEOVER")
	end
	if key2 then
		SetOverrideBinding(bif_Frame, true, key2, "INTERACTMOUSEOVER")
	end
	internal.binding_set = true
end

function addon:SetInteractTarget()
	if IsAddOnLoaded("BetterFishing") and BetterIceFishingDB.useBetterFishingKey then
		binding = "BETTERFISHINGKEY"
	else
		binding = "BETTERICEFISHINGKEY"
	end
	local key1, key2 = GetBindingKey(binding)
	if key1 then
		SetOverrideBinding(bif_Frame, true, key1, "INTERACTTARGET")
	end
	if key2 then
		SetOverrideBinding(bif_Frame, true, key2, "INTERACTTARGET")
	end
	internal.binding_set = true
end

function addon:SecureClearBindings()
	if not IsTaintable() then
		ClearOverrideBindings(bif_Frame)
		internal.binding_set = false
		addon:DebugPrint("Binding cleared!")
	else
		internal.clear_override = true;
	end
end

function addon:OnEvent(event, ...)
  if event == "ADDON_LOADED" then
		-- Event: ADDON_LOADED
		local loadedAddOn = ...
		if loadedAddOn == addonName then
			BetterIceFishingDB = BetterIceFishingDB or {};
			addon:CreateSettings()
			if IsAddOnLoaded("BetterFishing") and BetterIceFishingDB.useBetterFishingKey then
				binding = "BETTERFISHINGKEY"
			else
				binding = "BETTERICEFISHINGKEY"
			end
		end
  elseif event == "PLAYER_REGEN_ENABLED" then
		-- Event: PLAYER_REGEN_ENABLED
    if internal.clear_override then
      ClearOverrideBindings(bif_Frame)
      internal.clear_override = false
			internal.binding_set = false
			addon:DebugPrint("Binding cleared (Override)!")
    end
	elseif event == "CURSOR_CHANGED" then
		if (UnitChannelInfo("player") ~= nil) or (not internal.binding_set) then return end
		C_Timer.After(0.25, function(self)
			if (not addon:IsMouseOverIceFishingHole())  then
				addon:SecureClearBindings()
			end
		end)
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		-- Event: UPDATE_MOUSEOVER_UNIT
		if (not addon:AllowIceFishing()) or IsTaintable() then return end
		local guid = UnitGUID("mouseover") or ""
		local id = tonumber(guid:match("-(%d+)-%x+$"), 10) or 0
		if id and (id == 192631 or id == 197596) then
			addon:SetInteractMouseOver()
			addon:DebugPrint("Ice Fishing Hole found...")
			addon:DebugPrint("Set Binding to: Interact with Mouseover")
		end
  elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		-- Event: UNIT_SPELLCAST_CHANNEL_START
    local unit,_,spellID = ...
    if unit == "player" and spellID == self:GetFishingCastID() then
			addon:SetCVars()
			if IsTaintable() then return end
      addon:SetInteractTarget()
			addon:DebugPrint("Set Binding to: Interact with Target")
    end
  elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		-- Event: UNIT_SPELLCAST_CHANNEL_STOP
    local unit,_,spellID = ...
    if unit == "player" and spellID == self:GetFishingCastID() then
      addon:ResetCVars()
			if addon:IsMouseOverIceFishingHole() then
				if not IsTaintable() then
					addon:SetInteractMouseOver()
					addon:DebugPrint("Set Binding to: Interact with Mouseover")
				else
					internal.clear_override = true;
				end
			else
				addon:SecureClearBindings()
			end
    end
  elseif event == "PLAYER_LOGOUT" then
		-- Event: PLAYER_LOGOUT
    addon:ResetCVars()
  elseif event == "CVAR_UPDATE" then
		-- Event: CVAR_UPDATE
    if self:IsFishing() then return end
    for i = 1, #SoundCVars do
      if SoundCVars[i] == ... then
        soundSettingsBackup[SoundCVars[i]] = GetCVar(...);
      end
    end
  end
end

bif_Frame:SetScript("OnEvent", function(self, ...)
	addon:OnEvent(...)
end)

FrameUtil.RegisterFrameForEvents(bif_Frame, {
  "ADDON_LOADED",
  "CURSOR_CHANGED",
  "PLAYER_REGEN_ENABLED",
  "UNIT_SPELLCAST_CHANNEL_START",
  "UNIT_SPELLCAST_CHANNEL_STOP",
  "UPDATE_MOUSEOVER_UNIT",
  "CVAR_UPDATE",
  "PLAYER_LOGOUT"
})

function addon:EnhanceSounds(enable)
  if not BetterIceFishingDB.enhanceSounds then return end

  if not enable then
    for i = 1, #SoundCVars do
      if soundSettingsBackup[SoundCVars[i]] then
        SetCVar(SoundCVars[i], soundSettingsBackup[SoundCVars[i]])
      end
    end
  else
    for i = 1, #SoundCVars do
      soundSettingsBackup[SoundCVars[i]] = GetCVar(SoundCVars[i])
      SetCVar(SoundCVars[i], 0)
    end
    SetCVar("Sound_EnableAmbience", 0)
    SetCVar("Sound_MusicVolume", 0)
    SetCVar("Sound_EnablePetSounds", 0)

    SetCVar("Sound_EnableSFX", 1)
    SetCVar("Sound_EnableSoundWhenGameIsInBG", 1)
    SetCVar("Sound_EnableAllSound", 1)
    BetterIceFishingDB.enhanceSoundsScale = BetterIceFishingDB.enhanceSoundsScale or 1
    SetCVar("Sound_SFXVolume", BetterIceFishingDB.enhanceSoundsScale)
    SetCVar("Sound_MasterVolume", BetterIceFishingDB.enhanceSoundsScale)
  end
end

function addon:CreateSettings()
  local optionsFrame
	optionsFrame = CreateFrame("Frame")
	category, layout = Settings.RegisterCanvasLayoutCategory(optionsFrame, "|rBetter |cff00a2e8Ice|r Fishing|r |Tinterface/cursor/crosshair/fishing:18:18:0:0|t");
	category.ID = "BetterIceFishing";
	Settings.RegisterAddOnCategory(category);

  local header = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
  header:SetPoint("TOPLEFT", 7, -22)
  header:SetText("Better |cff00a2e8Ice|r Fishing")

  local function makeCheckButton(text)
    local checkBox
    checkBox = CreateFrame("CheckButton", addonName.."CheckBox", optionsFrame, "SettingsCheckBoxTemplate")
    checkBox.text = checkBox:CreateFontString(addonName.."CheckBoxText", "ARTWORK", "GameFontNormal")
    checkBox.text:SetText(text)
    checkBox.text:SetPoint("LEFT", checkBox, "RIGHT", 4, 0)

    return checkBox
  end

	local sTable = {
    { option = "enhanceSounds", text = "Enhance Sounds" },
    { option = "objectIconDisabled", text = "Disable icon above bobber (visibility varies for nameplate addons)" },
    { option = "useBetterFishingKey", text = "Use Keybinding from \"Better Fishing\""},
  }

  local prevCheckButton
  for i, info in ipairs(sTable) do
		if not (info.option == "useBetterFishingKey" and (not IsAddOnLoaded("BetterFishing"))) then
			local checkButton = makeCheckButton(info.text)
			if not prevCheckButton then
				checkButton:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -16)
			else
				checkButton:SetPoint("TOPLEFT", prevCheckButton, "BOTTOMLEFT", 0, 0)
			end
			checkButton:SetChecked(BetterIceFishingDB[info.option])
			checkButton:SetScript("OnClick", function()
				BetterIceFishingDB[info.option] = not BetterIceFishingDB[info.option]
				checkButton:SetChecked(BetterIceFishingDB[info.option])
			end)

			prevCheckButton = checkButton
		end
  end
	local function FormatPercentageRound(value)
		return FormatPercentage(value, true);
	end

	local right = MinimalSliderWithSteppersMixin.Label.Right
	local slider = CreateFrame("Slider", addonName.."Slider", optionsFrame, "MinimalSliderWithSteppersTemplate")
	local formatters = {}
	formatters[right] = CreateMinimalSliderFormatter(right, FormatPercentageRound);
	slider:Init(BetterIceFishingDB.enhanceSoundsScale or 1, 0, 1, 20, formatters)
	slider:SetPoint("LEFT", addonName.."CheckBoxText", "RIGHT", 10, 0)
	local function OnValueChanged(_, value)
		BetterIceFishingDB.enhanceSoundsScale = value
	end
	slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, OnValueChanged)
end


_G['SLASH_' .. addonName .. 'Options' .. 1] = '/bif'
_G['SLASH_' .. addonName .. 'Options' .. 2] = '/bettericefishing'
SlashCmdList[addonName .. 'Options'] = function(msg)
	if not msg or type(msg) ~= "string" or msg == "" then
		Settings.OpenToCategory("BetterIceFishing")
	else
		local cmd, arg = strsplit(" ", msg:trim():lower()) -- Try splitting by space
		if cmd == "debug" then
			internal.debug = not internal.debug
			DEFAULT_CHAT_FRAME:AddMessage("|cffff8000BIF Debug\[|r"..tostring(internal.debug).."|cffff8000\]")
		end
	end
end