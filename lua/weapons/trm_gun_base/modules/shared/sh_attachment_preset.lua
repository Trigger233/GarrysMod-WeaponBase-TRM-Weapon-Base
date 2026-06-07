local PRESET_ROOT = "trm_weapon_base/preset/save_attachment/"
local LOADOUT_ROOT = "trm_weapon_base/preset/loadouts/"
if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("TRMBase_LoadLoadout")
    util.AddNetworkString("TRMBase_SaveLoadout")
end
local function PresetSlot(slot)
    slot = math.floor(tonumber(slot) or 1)
    return math.Clamp(slot, 1, 5)
end

local function SerializeAttachments(weapon)
    local data = {}

    if weapon.Attachments then
        for i = 1, #weapon.Attachments do
            local slotKey = tostring(i)
            local entry = weapon.CurrentAttachments and weapon.CurrentAttachments[slotKey]
            data[i] = entry and entry.Class or "None"
        end
    end

    return data
end

local function ApplyAttachmentTable(weapon, data)
    if not data or not istable(data) then return false end

    weapon.CurrentAttachments = weapon.CurrentAttachments or {}
    weapon:EquipDefaultAttachments()

    for i, attClass in ipairs(data) do
        local slotKey = tostring(i)
        if weapon.Attachments and weapon.Attachments[i] and attClass ~= "None" and BASE_TRM_ATTS and BASE_TRM_ATTS[attClass] then
            weapon.CurrentAttachments[slotKey] = { Class = attClass }
        end
    end

    if weapon.BuildCustomizedGun then weapon:BuildCustomizedGun() end

    return true
end

function SWEP:EquipDefaultAttachments()
    if not SERVER then return end
    if not self.Attachments then return end

    self.CurrentAttachments = self.CurrentAttachments or {}
    for i, slot in ipairs(self.Attachments) do
        if slot.Default and BASE_TRM_ATTS[slot.Default] then
            self.CurrentAttachments[tostring(i)] = { Class = slot.Default }
        end
    end

    self:OnAttachmentChanged()
end

function SWEP:SaveAttachmentPreset()
    if not SERVER then return end

    local class = self:GetClass()
    if not class or class == "" then return end

    local path = PRESET_ROOT .. class .. "/save.json"
    file.CreateDir(PRESET_ROOT .. class)
    file.Write(path, util.TableToJSON(SerializeAttachments(self)))
end

function SWEP:LoadAttachmentPreset()
    if not SERVER then return end

    local class = self:GetClass()
    if not class or class == "" then return end

    local json = file.Read(PRESET_ROOT .. class .. "/save.json", "DATA")
    if not json or json == "" then return end

    local data = util.JSONToTable(json)
    ApplyAttachmentTable(self, data)
end

function SWEP:SaveAttachmentLoadout(slot)
    if not SERVER then return end

    local class = self:GetClass()
    if not class or class == "" then return end

    slot = PresetSlot(slot)
    local dir = LOADOUT_ROOT .. class
    local path = dir .. "/preset_" .. slot .. ".json"

    file.CreateDir(dir)
    file.Write(path, util.TableToJSON(SerializeAttachments(self), true))
end

function SWEP:LoadAttachmentLoadout(slot)
    if not SERVER then return false end

    local class = self:GetClass()
    if not class or class == "" then return false end

    slot = PresetSlot(slot)
    local path = LOADOUT_ROOT .. class .. "/preset_" .. slot .. ".json"
    local json = file.Read(path, "DATA")
    if not json or json == "" then return false end

    local data = util.JSONToTable(json)
    return ApplyAttachmentTable(self, data)
end

if SERVER then
    net.Receive("TRMBase_SaveLoadout", function(_, ply)
        local weapon = net.ReadEntity()
        local slot = net.ReadUInt(3)

        if not IsValid(ply) or not IsValid(weapon) or weapon:GetOwner() ~= ply then return end
        if not weapon.SaveAttachmentLoadout then return end

        weapon:SaveAttachmentLoadout(slot)
    end)

    net.Receive("TRMBase_LoadLoadout", function(_, ply)
        local weapon = net.ReadEntity()
        local slot = net.ReadUInt(3)

        if not IsValid(ply) or not IsValid(weapon) or weapon:GetOwner() ~= ply then return end
        if not weapon.LoadAttachmentLoadout then return end

        weapon:LoadAttachmentLoadout(slot)
    end)

    concommand.Add("trmbase_save_loadout", function(ply, _, args)
        if not IsValid(ply) then return end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) or not weapon.SaveAttachmentLoadout then return end

        weapon:SaveAttachmentLoadout(args and args[1] or 1)
    end)

    concommand.Add("trmbase_load_loadout", function(ply, _, args)
        if not IsValid(ply) then return end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) or not weapon.LoadAttachmentLoadout then return end

        weapon:LoadAttachmentLoadout(args and args[1] or 1)
    end)
end
