-- =============================================
-- TRMBase 配件自动保存/加载系统
-- 
-- 保存路径: data/trm_weapon_base/preset/save_attachment/{武器类名}/save.json
-- 保存时机: EquipAttachment / UnEquipAttachment
-- 加载时机: Deploy
-- =============================================

local PRESET_ROOT = "trm_weapon_base/preset/save_attachment/"

--- 装上所有定义了 Default 的配件
function SWEP:EquipDefaultAttachments()
    if not SERVER then return end
    if not self.Attachments then return end

    local changed = false
    for i, slot in ipairs(self.Attachments) do
        if slot.Default and BASE_TRM_ATTS[slot.Default] then
            local slotKey = tostring(i)
            if self.CurrentAttachments[slotKey] ~= slot.Default then
                self.CurrentAttachments[slotKey] = slot.Default
                changed = true
            end
        end
    end

    if changed then
        self:ChangeWeaponStats()
        print("[TRMBase] Default attachments applied")
    end
end

--- 把当前武器的配件配置保存为 JSON
function SWEP:SaveAttachmentPreset()
    if not SERVER then return end

    local class = self:GetClass()
    if not class or class == "" then return end

    -- 遍历所有武器槽位，空槽位也显式保存为 "None"
    local data = {}
    if self.Attachments then
        for i = 1, #self.Attachments do
            local slotKey = tostring(i)
            data[slotKey] = self.CurrentAttachments and self.CurrentAttachments[slotKey] or "None"
        end
    end

    local path = PRESET_ROOT .. class .. "/save.json"
    local json = util.TableToJSON(data)

    file.CreateDir(PRESET_ROOT .. class)
    file.Write(path, json)

    print("[TRMBase] Preset saved:", class, "(" .. tostring(table.Count(data)) .. " slots)")
end

--- 从 JSON 加载配件配置并应用到武器
function SWEP:LoadAttachmentPreset()
    if not SERVER then return end

    local class = self:GetClass()
    if not class or class == "" then return end

    local path = PRESET_ROOT .. class .. "/save.json"

    -- 没有保存过的配置 → 尝试装默认配件
    if not file.Exists(path, "DATA") then
        self:EquipDefaultAttachments()
        return
    end

    local json = file.Read(path, "DATA")
    if not json or json == "" then return end

    local data = util.JSONToTable(json)
    if not data or not istable(data) then return end

    -- 先清空所有槽位，再根据保存的数据恢复
    self.CurrentAttachments = self.CurrentAttachments or {}
    -- 先清空已有的（确保没在 JSON 里的槽位也被清掉）
    for slotKey, _ in pairs(self.CurrentAttachments) do
        self.CurrentAttachments[slotKey] = nil
    end

    for slotKey, attClass in pairs(data) do
        local slotIndex = tonumber(slotKey)
        if slotIndex and self.Attachments and self.Attachments[slotIndex] then
            if attClass == "None" then
                -- 显式保存为空，不做任何事（当前已经是 nil）
                continue
            end
            -- 检查这个配件类是否已加载
            if BASE_TRM_ATTS and BASE_TRM_ATTS[attClass] then
                -- 检查 Category 是否匹配
                local slotCat = self.Attachments[slotIndex].Category
                local attCat = BASE_TRM_ATTS[attClass].Category
                if slotCat and attCat then
                    local match = false
                    for _, cat in ipairs(istable(slotCat) and slotCat or {slotCat}) do
                        if cat == attCat then
                            match = true
                            break
                        end
                    end
                    if match then
                        self.CurrentAttachments[slotKey] = attClass
                    end
                end
            end
        end
    end

    -- 第二遍：对于有空槽位但定义了 Default 的，查保存数据里有没有这个配件
    -- 不管存的时候在哪个槽位，只要有就直接装上
    for i, slot in ipairs(self.Attachments) do
        local slotKey = tostring(i)
        if not self.CurrentAttachments[slotKey] and slot.Default then
            -- 在保存的数据里查找这个 Default 配件
            for _, savedAttClass in pairs(data) do
                if savedAttClass == slot.Default then
                    self.CurrentAttachments[slotKey] = slot.Default
                    break
                end
            end
        end
    end

    -- 修改武器属性
    self:ChangeWeaponStats()

    -- 利用已有的 SyncAllAttachments 同步给客户端
    if self.GetOwner and IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
        self:SyncAllAttachments()
    end

    print("[TRMBase] Preset loaded:", class)
end
