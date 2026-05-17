-- =============================================
-- TRMBase 配件自动保存/加载系统
-- 
-- 保存路径: data/trm_weapon_base/preset/save_attachment/{武器类名}/save.json
-- 保存时机: EquipAttachment / UnEquipAttachment
-- 加载时机: 初始化 / Deploy
-- =============================================

local PRESET_ROOT = "trm_weapon_base/preset/save_attachment/"

--- 装上所有定义了 Default 的配件
function SWEP:EquipDefaultAttachments()
    if not SERVER then return end
    if not self.Attachments then return end
    if not self.CurrentAttachments then
        self.CurrentAttachments = {}
    end
    for i, slot in ipairs(self.Attachments) do
        if slot.Default and BASE_TRM_ATTS[slot.Default] then
            local slotKey = tostring(i)
            self.CurrentAttachments[slotKey] = {Class = slot.Default}
        end
    end
end

--- 把当前武器的配件配置保存为 JSON
function SWEP:SaveAttachmentPreset()
    if not SERVER then return end
    local class = self:GetClass()
    if not class or class == "" then return end
    local data = {}
    if self.Attachments then
        for i = 1, #self.Attachments do
            local slotKey = tostring(i)
            local entry = self.CurrentAttachments and self.CurrentAttachments[slotKey]
            data[slotKey] = entry and entry.Class or "None"
        end
    end
    local path = PRESET_ROOT .. class .. "/save.json"
    file.CreateDir(PRESET_ROOT .. class)
    file.Write(path, util.TableToJSON(data))
    print("[TRMBase] Preset saved:", class, "(" .. tostring(table.Count(data)) .. " slots)")
end

--- 从 JSON 加载配件配置并应用到武器
function SWEP:LoadAttachmentPreset()
    if not SERVER then return end
    local class = self:GetClass()
    if not class or class == "" then return end

    local json = file.Read(PRESET_ROOT .. class .. "/save.json", "DATA")
    if not json or json == "" then return end

    local data = util.JSONToTable(json)
    if not data or not istable(data) then return end

    self.CurrentAttachments = self.CurrentAttachments or {}
    for slotKey in pairs(self.CurrentAttachments) do
        self.CurrentAttachments[slotKey] = nil
    end

    for slotKey, attClass in pairs(data) do
        local slotIndex = tonumber(slotKey)
        if slotIndex and self.Attachments and self.Attachments[slotIndex] then
            if attClass == "None" then continue end
            if BASE_TRM_ATTS and BASE_TRM_ATTS[attClass] then
                local slotCat = self.Attachments[slotIndex].Category
                local attCat = BASE_TRM_ATTS[attClass].Category
                if slotCat and attCat then
                    for _, cat in pairs(istable(slotCat) and slotCat or {slotCat}) do
                        if cat == attCat then
                            self.CurrentAttachments[slotKey] = {Class = attClass}
                            break
                        end
                    end
                end
            end
        end
    end

    -- 空槽位补默认
    for i, slot in ipairs(self.Attachments) do
        local slotKey = tostring(i)
        if (not self.CurrentAttachments[slotKey]  or not self.CurrentAttachments[slotKey].Class)  and slot.Default and BASE_TRM_ATTS[slot.Default] then
            self.CurrentAttachments[slotKey] = {Class = slot.Default}
        end
    end

    self:SyncAllAttachments()
end
