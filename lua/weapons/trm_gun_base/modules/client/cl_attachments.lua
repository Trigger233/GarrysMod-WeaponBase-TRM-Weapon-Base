if SERVER then return end

local MENU_BG = Color(2, 4, 4, 86)
local BENCH_BG = Color(3, 6, 6, 122)
local PANEL_BG = Color(8, 13, 13, 150)
local PANEL_LINE = Color(105, 126, 126, 150)
local TEXT_MAIN = Color(230, 244, 241)
local TEXT_DIM = Color(184, 206, 202)
local ACCENT = Color(151, 222, 213)
local ACTIVE = Color(88, 185, 125)
local WARNING = Color(198, 74, 66)
local ZERO_VECTOR = Vector(0, 0, 0)
local ZERO_ANGLE = Angle(0, 0, 0)
local FONT_FAMILY = "Roboto"
surface.CreateFont("TRM_Mod_Title", {
    font = FONT_FAMILY,
    size = 28,
    weight = 700,
    antialias = true,
})

surface.CreateFont("TRM_Mod_Subtitle", {
    font = FONT_FAMILY,
    size = 18,
    weight = 650,
    antialias = true,
})

surface.CreateFont("TRM_Mod_Small", {
    font = FONT_FAMILY,
    size = 14,
    weight = 650,
    antialias = true,
})

surface.CreateFont("TRM_Mod_Tiny", {
    font = FONT_FAMILY,
    size = 12,
    weight = 600,
    antialias = true,
})

function SWEP:SendAttachmentToServer(slotKey, attID)
    if not (game.SinglePlayer() or CLIENT) then return end

    net.Start("TRMBase_Attachment")
    net.WriteEntity(self)
    net.WriteString(slotKey)
    net.WriteString(attID)
    net.SendToServer()
end

local function Phrase(text, fallback)
    if not text then return fallback or "" end
    if string.sub(tostring(text), 1, 1) ~= "#" then return text end

    local phrased = language.GetPhrase(text)
    if not phrased or phrased == text then return fallback or text end
    return phrased
end

local function SlotCategories(slot)
    if not slot or not slot.Category then return {} end
    return istable(slot.Category) and slot.Category or { slot.Category }
end

local function GetAttachmentsForSlot(slot)
    local cats = SlotCategories(slot)
    if #cats == 0 then return {} end

    local result = {}
    for attClass, attData in pairs(BASE_TRM_ATTS or {}) do
        if type(attData) ~= "table" then continue end
        if attData.Selectable == false then continue end
        if not attData.Category then continue end

        for _, cat in ipairs(cats) do
            if attData.Category == cat then
                result[#result + 1] = attClass
                break
            end
        end
    end

    table.sort(result, function(a, b)
        local ad = BASE_TRM_ATTS[a]
        local bd = BASE_TRM_ATTS[b]
        local an = Phrase(ad and ad.Name, a)
        local bn = Phrase(bd and bd.Name, b)
        return an < bn
    end)

    return result
end

local function AttachmentName(attClass)
    if not attClass or attClass == "None" then return Phrase("#TRMBase_None", "None") end
    local attData = BASE_TRM_ATTS and BASE_TRM_ATTS[attClass]
    return Phrase(attData and attData.Name, attClass)
end

local function CurrentAttachmentClass(weapon, slotIndex)
    local entry = weapon.CurrentAttachments and weapon.CurrentAttachments[tostring(slotIndex)]
    return entry and entry.Class
end

local function TrimText(font, text, maxWide)
    text = tostring(text or "")
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxWide then return text end

    local suffix = "..."
    for i = #text, 1, -1 do
        local trimmed = string.sub(text, 1, i) .. suffix
        if surface.GetTextSize(trimmed) <= maxWide then return trimmed end
    end

    return suffix
end

local function Num(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback or 0 end
    return value
end

local function Avg(value, maxCount)
    if type(value) ~= "table" then return Num(value) end

    local total = 0
    local count = 0
    for _, item in pairs(value) do
        if maxCount and count >= maxCount then break end
        total = total + Avg(item)
        count = count + 1
    end

    if count == 0 then return 0 end
    return total / count
end

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end

    seen = seen or {}
    if seen[value] then return seen[value] end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        if type(item) == "function" then
            copy[key] = item
        elseif isvector(item) then
            copy[key] = Vector(item.x, item.y, item.z)
        elseif isangle(item) then
            copy[key] = Angle(item.p, item.y, item.r)
        elseif type(item) == "table" then
            copy[key] = DeepCopy(item, seen)
        else
            copy[key] = item
        end
    end

    return copy
end

local function CopyWeaponStats(source)
    local stats = {}
    local keys = {
        "Primary",
        "Secondary",
        "Spread",
        "Aim",
        "Recoil",
        "VisualRecoil",
        "MoveSpeed",
        "Animations",
    }

    for _, key in ipairs(keys) do
        stats[key] = DeepCopy(source and source[key] or {})
    end

    return stats
end

local function ApplyAttachmentStats(target, attClass)
    if not target or not attClass then return end
    local attData = BASE_TRM_ATTS and BASE_TRM_ATTS[attClass]
    if attData and attData.ChangeWeaponStats then
        pcall(attData.ChangeWeaponStats, attData, target)
    end
end

local function BuildStatCopies(weapon)
    if not IsValid(weapon) then return nil, nil end

    local def = weapons.Get(weapon:GetClass()) or weapon
    local base = CopyWeaponStats(def)
    local sim = CopyWeaponStats(def)

    for i, slot in ipairs(weapon.Attachments or {}) do
        if slot.Default then
            ApplyAttachmentStats(base, slot.Default)
        end

        local selected = CurrentAttachmentClass(weapon, i)
        ApplyAttachmentStats(sim, selected)
    end

    return base, sim
end

local function WeaponDamage(weapon)
    local primary = weapon.Primary or {}
    return Num(primary.Damage) * math.max(Num(primary.NumBullets, 1), 1)
end

local function WeaponRecoil(weapon)
    local recoil = weapon.Recoil or {}
    local visual = weapon.VisualRecoil or {}

    local fire = Avg({
        Avg(recoil.Vertical),
        Avg(recoil.Horizonal or recoil.Horizontal),
        Num(recoil.Shake) + Num(recoil.KickDown),
    }) * Avg({ Num(recoil.AdsMultiplier, 1), 1 })

    local view = Avg({
        Avg(visual.Vertical),
        Avg(visual.Horizonal or visual.Horizontal),
        Avg(visual.Backward),
        Avg({ -Num(visual.RecoverSpeed), -Num(visual.RecoverDelay) }),
    }) * Avg({ Num(visual.AdsMulitplier, 1), 1 })

    return math.Round(fire + view, 3)
end

local function BuildStats(weapon)
    local base, sim = BuildStatCopies(weapon)
    if not base or not sim then return {} end

    return {
        { Phrase("#TRMBase_Stat_Damage", "Damage"),       WeaponDamage(sim),                         WeaponDamage(base),                          true,  100 },
        { Phrase("#TRMBase_Stat_ClipSize", "Magazine"),   Num(sim.Primary and sim.Primary.ClipSize), Num(base.Primary and base.Primary.ClipSize), true,  150 },
        { Phrase("#TRMBase_Stat_RPM", "Fire rate"),       Num(sim.Primary and sim.Primary.RPM),      Num(base.Primary and base.Primary.RPM),      true,  1500 },
        { Phrase("#TRMBase_Stat_Spread", "Spread"),       Num(sim.Spread and sim.Spread.Base),       Num(base.Spread and base.Spread.Base),       false, 0.1 },
        { Phrase("#TRMBase_Stat_AimSpeed", "Ergonomics"), Num(sim.Aim and sim.Aim.Time),             Num(base.Aim and base.Aim.Time),             false, 1 },
        { Phrase("#TRMBase_Stat_Recoil", "Recoil"),       WeaponRecoil(sim),                         WeaponRecoil(base),                          false, 10 },
    }
end

local function SlotRole(slot)
    local name = string.lower(tostring(slot and slot.Name or ""))

    if string.find(name, "optic", 1, true) or string.find(name, "sight", 1, true) then
        return "optic"
    elseif string.find(name, "muzzle", 1, true) then
        return "muzzle"
    elseif string.find(name, "barrel", 1, true) then
        return "barrel"
    elseif string.find(name, "stock", 1, true) then
        return "stock"
    elseif string.find(name, "mag", 1, true) then
        return "mag"
    elseif string.find(name, "under", 1, true) or string.find(name, "fore", 1, true) then
        return "underbarrel"
    elseif string.find(name, "laser", 1, true) then
        return "laser"
    elseif string.find(name, "grip", 1, true) then
        return "grip"
    end

    return "misc"
end

local function SlotLayout(slot, index, count)
    local role = SlotRole(slot)
    local layouts = {
        stock = { tx = 0.24, ty = 0.50, side = "left", order = 3 },
        grip = { tx = 0.46, ty = 0.66, side = "left", order = 5 },
        mag = { tx = 0.53, ty = 0.67, side = "left", order = 6 },
        barrel = { tx = 0.68, ty = 0.48, side = "left", order = 2 },
        optic = { tx = 0.56, ty = 0.38, side = "right", order = 1 },
        muzzle = { tx = 0.78, ty = 0.48, side = "right", order = 3 },
        laser = { tx = 0.67, ty = 0.44, side = "right", order = 5 },
        underbarrel = { tx = 0.59, ty = 0.60, side = "right", order = 4 },
        misc = { tx = 0.48, ty = 0.52, side = (index % 2 == 0) and "right" or "left", order = 7 + index },
    }

    local layout = table.Copy(layouts[role] or layouts.misc)
    layout.role = role
    layout.index = index
    layout.count = count
    return layout
end

local function CopyVector(value)
    if isvector(value) then return Vector(value.x, value.y, value.z) end
    return Vector(0, 0, 0)
end

local function CopyAngle(value)
    if isangle(value) then return Angle(value.p, value.y, value.r) end
    return Angle(0, 0, 0)
end

local function ModelPath(value)
    if not value then return nil end
    local path = tostring(value)
    if path == "" or path == "[NULL Entity]" then return nil end
    return path
end

local PANEL = {}

function PANEL:Init()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)

    self.m_Slot = 1
    self.m_SlotCards = {}
    self.m_SlotScreen = {}
    self.m_PreviewModels = {}
    self.m_Anim = 0
    self.m_ModelYaw = 0
    self.m_ModelPitch = 0
    self.m_ModelZoom = 1.25
    self.m_ModelPanX = 0
    self.m_ModelPanZ = 0
    self.m_ModelCenter = Vector(0, 0, 0)
    self.m_ModelSize = 48
    self.m_SlotScroll = 0
    self.m_SlotMaxScroll = 0
    self.m_StatsScroll = 0
    self.m_StatsMaxScroll = 0

    self.m_ModelPanel = vgui.Create("DModelPanel", self)
    self.m_ModelPanel:SetFOV(28)
    self.m_ModelPanel:SetAmbientLight(Color(150, 165, 160))
    self.m_ModelPanel:SetDirectionalLight(BOX_TOP, Color(255, 255, 245))
    self.m_ModelPanel:SetDirectionalLight(BOX_FRONT, Color(225, 245, 238))
    self.m_ModelPanel:SetDirectionalLight(BOX_RIGHT, Color(120, 180, 175))
    self.m_ModelPanel.PaintOver = function(panel, w, h)
        surface.SetDrawColor(255, 255, 255, 9)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.SimpleText("DRAG TO PAN  /  SCROLL TO ZOOM", "TRM_Mod_Small", w / 2, h - 18, TEXT_DIM, TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER)
    end
    self.m_ModelPanel.LayoutEntity = function(_, ent)
        self:LayoutPreviewEntity(ent)
    end
    self.m_ModelPanel.PostDrawModel = function(_, ent)
        self:PostDrawPreview(ent)
    end
    self.m_ModelPanel.OnMousePressed = function(panel, code)
        if code ~= MOUSE_LEFT then return end
        self:BeginModelDrag()
    end
    self.m_ModelPanel.OnMouseReleased = function(panel, code)
        if code ~= MOUSE_LEFT then return end
        self:EndModelDrag()
    end
    self.m_ModelPanel.CursorMoved = function(panel, x, y)
        self:UpdateModelDrag()
    end
    self.m_ModelPanel.OnMouseWheeled = function(_, delta)
        self.m_ModelZoom = math.Clamp((self.m_ModelZoom or 1.25) - delta * 0.12, 0.05, 5.80)
        self:UpdatePreviewCamera()
        return true
    end

    self.m_StatsPanel = vgui.Create("DPanel", self)
    self.m_StatsPanel.Paint = function(_, w, h)
        self:PaintStats(w, h)
    end
    self.m_StatsPanel.OnMouseWheeled = function(_, delta)
        self.m_StatsScroll = math.Clamp((self.m_StatsScroll or 0) - delta * 36, 0, self.m_StatsMaxScroll or 0)
        return true
    end

    self.m_AttPanel = vgui.Create("DPanel", self)
    self.m_AttPanel.Paint = function(_, w, h)
        self:PaintAttachmentPanel(w, h)
    end

    self.m_AttScroll = vgui.Create("DScrollPanel", self.m_AttPanel)
    self.m_AttScroll:Dock(FILL)
    self.m_AttScroll:DockMargin(12, 78, 12, 46)

    self.m_AttList = vgui.Create("DPanel", self.m_AttScroll)
    self.m_AttList:Dock(TOP)
    self.m_AttList:SetTall(0)
    self.m_AttList.Paint = function() end

    self.m_SlotStrip = vgui.Create("DPanel", self)
    self.m_SlotStrip.Paint = function(_, w, h)
        surface.SetDrawColor(0, 0, 0, 72)
        surface.DrawRect(0, 0, w, h)
        if (self.m_SlotMaxScroll or 0) > 0 then
            draw.SimpleText("SCROLL SLOTS", "TRM_Mod_Tiny", w - 8, h - 10, TEXT_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    self.m_SlotStrip.OnMouseWheeled = function(_, delta)
        self.m_SlotScroll = math.Clamp((self.m_SlotScroll or 0) - delta * 92, 0, self.m_SlotMaxScroll or 0)
        self:LayoutSlotCards()
        return true
    end

    self.m_BackButton = vgui.Create("DButton", self)
    self.m_BackButton:SetText("")
    self.m_BackButton.DoClick = function()
        self:Close()
    end
    self.m_BackButton.Paint = function(button, w, h)
        local hovered = button:IsHovered()
        surface.SetDrawColor(hovered and ACCENT or PANEL_LINE)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("BACK", "TRM_Mod_Subtitle", w / 2, h / 2, hovered and ACCENT or TEXT_MAIN, TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER)
    end
end

function PANEL:PerformLayout(w, h)
    local statsW = math.min(330, math.floor(w * 0.20))
    local attW = math.min(370, math.floor(w * 0.28))
    local topY = math.floor(h * 0.18)
    local panelH = math.floor(h * 0.58)
    local attX = w - attW - 22
    local modelX = 22 + statsW + 38
    local modelY = math.floor(h * 0.13)
    local modelW = math.max(420, attX - modelX - 38)
    local modelH = math.floor(h * 0.66)

    self.m_StatsPanel:SetPos(22, topY)
    self.m_StatsPanel:SetSize(statsW, panelH)

    self.m_AttPanel:SetPos(attX, topY)
    self.m_AttPanel:SetSize(attW, math.floor(h * 0.62))

    self.m_ModelPanel:SetPos(modelX, modelY)
    self.m_ModelPanel:SetSize(modelW, modelH)

    self.m_SlotStrip:SetPos(modelX + 14, modelY + modelH - 104)
    self.m_SlotStrip:SetSize(math.max(modelW - 28, 1), 78)

    self.m_BackButton:SetSize(118, 34)
    self.m_BackButton:SetPos(w - 144, h - 58)

    self:RefreshSlotTargets()
    self:LayoutSlotCards()
    self:UpdatePreviewCamera()
end

function PANEL:LayoutPreviewEntity(ent)
    if not IsValid(ent) then return end

    ent:SetAngles(Angle(self.m_ModelPitch or 0, self.m_ModelYaw or 0, 0))
end

function PANEL:IsCursorInModelPanel()
    if not IsValid(self.m_ModelPanel) then return false end

    local x, y = self.m_ModelPanel:CursorPos()
    return x >= 0 and y >= 0 and x <= self.m_ModelPanel:GetWide() and y <= self.m_ModelPanel:GetTall()
end

function PANEL:BeginModelDrag()
    if not self:IsCursorInModelPanel() then return end

    self.m_DraggingModel = true
    self.m_LastDragX, self.m_LastDragY = input.GetCursorPos()
    self.m_ModelPanel:MouseCapture(true)
end

function PANEL:EndModelDrag()
    self.m_DraggingModel = false
    if IsValid(self.m_ModelPanel) then
        self.m_ModelPanel:MouseCapture(false)
    end
end

function PANEL:UpdateModelDrag()
    if not self.m_DraggingModel then return end

    if not input.IsMouseDown(MOUSE_LEFT) then
        self:EndModelDrag()
        return
    end

    local x, y = input.GetCursorPos()
    local lastX = self.m_LastDragX or x
    local lastY = self.m_LastDragY or y

    local dx = x - lastX
    local dy = y - lastY
    local size = math.max(self.m_ModelSize or 48, 1)
    local zoom = self.m_ModelZoom or 1.25
    local panelW = IsValid(self.m_ModelPanel) and math.max(self.m_ModelPanel:GetWide(), 1) or 1
    local panelH = IsValid(self.m_ModelPanel) and math.max(self.m_ModelPanel:GetTall(), 1) or 1
    local xScale = size * zoom / panelW
    local zScale = size * zoom / panelH

    self.m_ModelPanX = math.Clamp((self.m_ModelPanX or 0) - dx * xScale, -size, size)
    self.m_ModelPanZ = math.Clamp((self.m_ModelPanZ or 0) + dy * zScale, -size, size)
    self:UpdatePreviewCamera()

    self.m_LastDragX, self.m_LastDragY = x, y
end

function PANEL:OnMousePressed(code)
    if code == MOUSE_LEFT and self:IsCursorInModelPanel() then
        self:BeginModelDrag()
    end
end

function PANEL:OnMouseReleased(code)
    if code == MOUSE_LEFT then
        self:EndModelDrag()
    end
end

function PANEL:Think()
    self:UpdateModelDrag()
end

function PANEL:UpdatePreviewCamera()
    if not IsValid(self.m_ModelPanel) then return end

    local ent = self.m_ModelPanel:GetEntity()
    if not IsValid(ent) then return end

    local center = (self.m_ModelCenter or Vector(0, 0, 0)) + Vector(self.m_ModelPanX or 0, 0, self.m_ModelPanZ or 0)
    local size = math.max(self.m_ModelSize or 48, 1)
    local zoom = self.m_ModelZoom or 1.25
    local dist = math.Clamp(size * zoom, 42, 260)

    self.m_ModelPanel:SetLookAt(center)
    self.m_ModelPanel:SetCamPos(center + Vector(size * 0.02, -dist, size * 0.08))
end

function PANEL:SetupModel()
    if not IsValid(self.m_Weapon) then return end

    local model = self.m_Weapon.ViewModel
    if not model or model == "" then model = self.m_Weapon.WorldModel end
    if not model or model == "" then return end

    self.m_ModelPanel:SetModel(model)
    local ent = self.m_ModelPanel:GetEntity()
    if not IsValid(ent) then return end

    ent:InvalidateBoneCache()
    ent:SetupBones()

    -- 缓存预览用骨骼数据
    self.m_PreviewBones = {}
    for i = 0, ent:GetBoneCount() do
        local name = ent:GetBoneName(i)
        if name and name ~= "" then
            self.m_PreviewBones[name] = { Id = i, Parent = ent }
        end
    end

    local mins, maxs = ent:GetRenderBounds()
    local center = (mins + maxs) * 0.5
    local bounds = maxs - mins
    local size = math.max(bounds.x, bounds.y, bounds.z, 1)
    self.m_ModelCenter = center
    self.m_ModelSize = size
    self.m_ModelPanX = 0
    self.m_ModelPanZ = 0
    self:LayoutPreviewEntity(ent)
    self:UpdatePreviewCamera()

    self:RefreshPreview()
end

function PANEL:RemovePreviewModels()
    for _, model in ipairs(self.m_PreviewModels or {}) do
        if IsValid(model) then
            model:Remove()
        end
    end

    self.m_PreviewModels = {}
end

function PANEL:ApplyPreviewBodygroups(ent)
    if not IsValid(ent) or not IsValid(self.m_Weapon) then return end

    for i = 0, ent:GetNumBodyGroups() do
        ent:SetBodygroup(i, 0)
    end

    local bodygroups = {}
    for name, value in pairs(self.m_Weapon.BodyGroups or {}) do
        bodygroups[name] = value
    end

    for _, entry in pairs(self.m_Weapon.CurrentAttachments or {}) do
        local attData = entry and entry.Class and BASE_TRM_ATTS and BASE_TRM_ATTS[entry.Class]
        if attData and attData.BodyGroup then
            for name, value in pairs(attData.BodyGroup) do
                bodygroups[name] = value
            end
        end
    end

    -- 应用到预览实体
    for name, value in pairs(bodygroups) do
        local id = ent:FindBodygroupByName(name)
        if id and id > -1 then
            ent:SetBodygroup(id, value)
        end
    end

    -- 同时应用到配件预览模型
    for _, model in ipairs(self.m_PreviewModels or {}) do
        if not IsValid(model) then continue end
        -- 先清空再应用
        for i = 0, model:GetNumBodyGroups() do
            model:SetBodygroup(i, 0)
        end
        -- 武器默认 bodygroups
        for name, value in pairs(self.m_Weapon.BodyGroups or {}) do
            local id = model:FindBodygroupByName(name)
            if id and id > -1 then
                model:SetBodygroup(id, value)
            end
        end
        -- 配件自身 bodygroups
        local attData = model.Class and BASE_TRM_ATTS and BASE_TRM_ATTS[model.Class]
        if attData and attData.BodyGroup then
            for name, value in pairs(attData.BodyGroup) do
                local id = model:FindBodygroupByName(name)
                if id and id > -1 then
                    model:SetBodygroup(id, value)
                end
            end
        end
    end
end

function PANEL:SlotWorldPosition(ent, slot)
    if not IsValid(ent) or not slot then return nil end

    ent:InvalidateBoneCache()
    ent:SetupBones()

    if slot.Bone then
        local attId = ent:LookupAttachment(slot.Bone)
        if attId and attId > 0 then
            local attachment = ent:GetAttachment(attId)
            if attachment then
                local pos = attachment.Pos
                if slot.Pos then
                    pos = LocalToWorld(CopyVector(slot.Pos), ZERO_ANGLE, attachment.Pos, attachment.Ang)
                end
                return pos
            end
        end

        local boneId = ent:LookupBone(slot.Bone)
        if boneId then
            local matrix = ent:GetBoneMatrix(boneId)
            if matrix then
                local pos = matrix:GetTranslation()
                if slot.Pos then
                    pos = LocalToWorld(CopyVector(slot.Pos), ZERO_ANGLE, pos, matrix:GetAngles())
                end
                return pos
            end
        end
    end

    return self:SemanticSlotWorldPosition(ent, slot)
end

function PANEL:ProjectWorldToModelPanel(worldPos)
    if not IsValid(self.m_ModelPanel) or not worldPos then return nil end

    local panelX, panelY = self.m_ModelPanel:GetPos()
    local panelW, panelH = self.m_ModelPanel:GetSize()
    local camPos = self.m_ModelPanel.vCamPos
    local lookAt = self.m_ModelPanel.vLookatPos
    local fov = self.m_ModelPanel.fFOV or 33

    if not camPos or not lookAt then return nil end

    local ang = self.m_ModelPanel.aLookAngle or (lookAt - camPos):Angle()
    local delta = worldPos - camPos
    local depth = delta:Dot(ang:Forward())

    if depth <= 1 then return nil end

    local scale = (panelH * 0.5) / math.tan(math.rad(fov) * 0.5)
    local x = panelX + panelW * 0.5 - (delta:Dot(ang:Right()) * scale / depth)
    local y = panelY + panelH * 0.5 - (delta:Dot(ang:Up()) * scale / depth)

    if x < panelX or x > panelX + panelW or y < panelY or y > panelY + panelH then
        return nil
    end

    return x, y
end

function PANEL:SemanticSlotWorldPosition(ent, slot)
    local mins, maxs = ent:GetRenderBounds()
    local name = string.lower(tostring(slot and slot.Name or ""))
    local xSpan = maxs.x - mins.x
    local yMid = (mins.y + maxs.y) * 0.5
    local zSpan = maxs.z - mins.z

    local xFrac = 0.50
    local zFrac = 0.50

    if string.find(name, "optic", 1, true) or string.find(name, "sight", 1, true) then
        xFrac = 0.58
        zFrac = 0.86
    elseif string.find(name, "muzzle", 1, true) then
        xFrac = 0.96
        zFrac = 0.55
    elseif string.find(name, "barrel", 1, true) then
        xFrac = 0.78
        zFrac = 0.56
    elseif string.find(name, "stock", 1, true) then
        xFrac = 0.07
        zFrac = 0.54
    elseif string.find(name, "mag", 1, true) then
        xFrac = 0.48
        zFrac = 0.18
    elseif string.find(name, "under", 1, true) or string.find(name, "fore", 1, true) then
        xFrac = 0.61
        zFrac = 0.28
    elseif string.find(name, "laser", 1, true) or string.find(name, "tactical", 1, true) then
        xFrac = 0.71
        zFrac = 0.68
    elseif string.find(name, "grip", 1, true) then
        xFrac = 0.42
        zFrac = 0.25
    end

    return ent:LocalToWorld(Vector(mins.x + xSpan * xFrac, yMid, mins.z + zSpan * zFrac))
end

function PANEL:CreatePreviewModel(model, ent, slot, attData)
    if not IsValid(model) or not IsValid(ent) then return end
    model:SetNoDraw(true)
    model:SetNotSolid(true)
    model:SetMoveType(MOVETYPE_NONE)
    model:SetOwner(ent)

    if attData and attData.Scale then
        model:SetModelScale(attData.Scale)
    end

end

function PANEL:ApplyPreviewModel(ent)
    self:BuildModelBone(ent)
    local slot = self.m_Weapon.Attachments
    for slotKey, model in pairs(self.m_PreviewModels) do
        local attData = BASE_TRM_ATTS[model.Class]
        if attData.Bonemerge then
            model:AddEffects(EF_BONEMERGE)
            model:AddEffects(EF_BONEMERGE_FASTCULL)
            model:SetParent(ent)
            model:SetLocalPos(ZERO_VECTOR)
            model:SetLocalAngles(ZERO_ANGLE)

        else
            local slotEntry = slot[tonumber(model.Slot)]
            if not slotEntry then continue end
            local BoneData = self.m_PreviewBones[slotEntry.Bone]
            if not BoneData then continue end
            model:FollowBone(BoneData.Parent,BoneData.Id)
            model:SetLocalPos(ZERO_VECTOR)
            model:SetLocalAngles(ZERO_ANGLE)
            local LocalPos = CopyVector(ZERO_VECTOR)
            local LocalAngle = CopyAngle(ZERO_ANGLE)
            if slotEntry.Pos then LocalPos:Add(slotEntry.Pos) end
            if slotEntry.Ang then LocalAngle:Add(slotEntry.Ang) end
            if attData.Pos then LocalPos:Add(attData.Pos) end
            if attData.Angles then LocalAngle:Add(attData.Angles) end
            model:SetLocalPos(LocalPos)
            model:SetLocalAngles(LocalAngle)
        end
    end

    
end

function PANEL:BuildModelBone(ent)
    if not self.m_PreviewBones then
        self.m_PreviewBones = {}
        ent:InvalidateBoneCache()
        ent:SetupBones()
        for i = 0, ent:GetBoneCount() do
            local name = ent:GetBoneName(i)
            if name and name ~= "" then
                self.m_PreviewBones[name] = { Id = i, Parent = ent }
            end
        end
        -- 补充 Attachment 点（如 tag_flash_attachment）
        local attTable = ent:GetAttachments()
        if attTable and #attTable > 0 then
            for i = 1, #attTable do
                local att = attTable[i]
                if att and att.name and not self.m_PreviewBones[att.name] then
                    self.m_PreviewBones[att.name] = { Id = att.id, Parent = ent }
                end
            end
        end
    end

    -- 更新配件模型的骨骼
    for _, model in pairs(self.m_PreviewModels) do
        model:InvalidateBoneCache()
        model:SetupBones()
        local count = model:GetBoneCount()
        for index = 0, count do
            local name = model:GetBoneName(index)
            if name and name ~= "" then
                self.m_PreviewBones[name] = { Id = index, Parent = model }
            end
        end
    end
end

function PANEL:RefreshPreview()
    self:RemovePreviewModels()

    if not IsValid(self.m_ModelPanel) or not IsValid(self.m_Weapon) then return end

    local ent = self.m_ModelPanel:GetEntity()
    if not IsValid(ent) then return end


    for slotKey, entry in pairs(self.m_Weapon.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end

        local attData = BASE_TRM_ATTS and BASE_TRM_ATTS[entry.Class]
        local path = ModelPath(attData and attData.Model)
        if not path then continue end

        local slot = self.m_Weapon.Attachments and self.m_Weapon.Attachments[tonumber(slotKey)]
        if not attData.Bonemerge then continue end
        local model = ClientsideModel(path, RENDERGROUP_OPAQUE)
        if not IsValid(model) then continue end
        model.Class = entry.Class
        model.Slot = slotKey
        self:CreatePreviewModel(model, ent, slot, attData)
        self.m_PreviewModels[#self.m_PreviewModels + 1] = model
    end
    self:ApplyPreviewModel(ent)
    self:ApplyPreviewBodygroups(ent)
end

function PANEL:PostDrawPreview(ent)
    if not IsValid(ent) then return end

    self:ApplyPreviewBodygroups(ent)

    for _, model in ipairs(self.m_PreviewModels or {}) do
        if IsValid(model) then
            model:DrawModel()
        end
    end
end

function PANEL:RefreshSlotTargets()
    self.m_SlotScreen = {}
    if not IsValid(self.m_ModelPanel) then return end

    local panelX, panelY = self.m_ModelPanel:GetPos()
    local panelW, panelH = self.m_ModelPanel:GetSize()

    for i, slot in ipairs((IsValid(self.m_Weapon) and self.m_Weapon.Attachments) or {}) do
        self:SetFallbackSlotTarget(i, slot, panelX, panelY, panelW, panelH)
    end
end

function PANEL:SetFallbackSlotTarget(index, slot, panelX, panelY, panelW, panelH)
    if not panelX then
        if not IsValid(self.m_ModelPanel) then return end
        panelX, panelY = self.m_ModelPanel:GetPos()
        panelW, panelH = self.m_ModelPanel:GetSize()
    end

    local layout = SlotLayout(slot, index, #(self.m_Weapon and self.m_Weapon.Attachments or {}))
    local weaponLeft = panelX + panelW * 0.23
    local weaponRight = panelX + panelW * 0.78
    local weaponTop = panelY + panelH * 0.35
    local weaponBottom = panelY + panelH * 0.73

    self.m_SlotScreen[index] = {
        x = math.Clamp(panelX + panelW * layout.tx, weaponLeft, weaponRight),
        y = math.Clamp(panelY + panelH * layout.ty, weaponTop, weaponBottom),
        visible = true,
        fallback = true,
    }
end

function PANEL:RefreshSlotTargetsFromModel(ent)
    if not IsValid(ent) or not IsValid(self.m_Weapon) then return end

    self:RefreshSlotTargets()
    local panelX, panelY = self.m_ModelPanel:GetPos()
    local panelW, panelH = self.m_ModelPanel:GetSize()
    local weaponLeft = panelX + panelW * 0.17
    local weaponRight = panelX + panelW * 0.84
    local weaponTop = panelY + panelH * 0.26
    local weaponBottom = panelY + panelH * 0.78

    for i, slot in ipairs(self.m_Weapon.Attachments or {}) do
        local pos = self:SlotWorldPosition(ent, slot)
        local x, y = self:ProjectWorldToModelPanel(pos)

        if x and y and x >= weaponLeft and x <= weaponRight and y >= weaponTop and y <= weaponBottom then
            self.m_SlotScreen[i] = {
                x = x,
                y = y,
                visible = true,
                fallback = false,
            }
        else
            self:SetFallbackSlotTarget(i, slot, panelX, panelY, panelW, panelH)
        end
    end
end

function PANEL:RebuildSlotCards()
    for _, card in ipairs(self.m_SlotCards) do
        if IsValid(card) then card:Remove() end
    end

    self.m_SlotCards = {}
    if not IsValid(self.m_Weapon) then return end

    for i, slot in ipairs(self.m_Weapon.Attachments or {}) do
        local card = vgui.Create("DButton", IsValid(self.m_SlotStrip) and self.m_SlotStrip or self)
        card:SetText("")
        card.m_Index = i
        card.m_Slot = slot
        card.m_Layout = SlotLayout(slot, i, #(self.m_Weapon.Attachments or {}))
        card.DoClick = function()
            self.m_Slot = i
            self:RefreshAttList()
            self:EnsureSlotVisible(i)
            surface.PlaySound("buttons/lightswitch2.wav")
        end
        card.Paint = function(button, w, h)
            self:PaintSlotCard(button, w, h)
        end
        card.OnMouseWheeled = function(_, delta)
            self.m_SlotScroll = math.Clamp((self.m_SlotScroll or 0) - delta * 92, 0, self.m_SlotMaxScroll or 0)
            self:LayoutSlotCards()
            return true
        end

        self.m_SlotCards[#self.m_SlotCards + 1] = card
    end

    self:LayoutSlotCards()
end

function PANEL:LayoutSlotCards()
    if not self.m_SlotCards then return end

    if not IsValid(self.m_SlotStrip) then return end

    local count = math.max(#self.m_SlotCards, 1)
    local gap = 8
    local cardH = 66
    local stripW = math.max(self.m_SlotStrip:GetWide(), 1)
    local stripH = math.max(self.m_SlotStrip:GetTall(), cardH)
    local visibleCards = math.max(math.floor(stripW / 152), 1)
    local cardW = math.Clamp(math.floor((stripW - gap * math.min(count + 1, visibleCards + 1)) / math.min(count, visibleCards)), 128, 172)
    local totalW = count * cardW + (count - 1) * gap
    local startX = totalW < stripW and math.floor((stripW - totalW) * 0.5) or 0
    self.m_SlotMaxScroll = math.max(totalW - stripW, 0)
    self.m_SlotScroll = math.Clamp(self.m_SlotScroll or 0, 0, self.m_SlotMaxScroll)
    local y = math.floor((stripH - cardH) * 0.5)

    for slotIndex, card in ipairs(self.m_SlotCards) do
        if not IsValid(card) then continue end
        local x = startX + (slotIndex - 1) * (cardW + gap) - (self.m_SlotScroll or 0)

        card:SetSize(cardW, cardH)
        card:SetPos(x, y)
    end
end

function PANEL:EnsureSlotVisible(slotIndex)
    if not IsValid(self.m_SlotStrip) or not self.m_SlotCards then return end
    local card = self.m_SlotCards[slotIndex]
    if not IsValid(card) then return end

    local x, _ = card:GetPos()
    local w = card:GetWide()
    local stripW = self.m_SlotStrip:GetWide()

    if x < 0 then
        self.m_SlotScroll = math.Clamp((self.m_SlotScroll or 0) + x - 8, 0, self.m_SlotMaxScroll or 0)
    elseif x + w > stripW then
        self.m_SlotScroll = math.Clamp((self.m_SlotScroll or 0) + (x + w - stripW) + 8, 0, self.m_SlotMaxScroll or 0)
    end

    self:LayoutSlotCards()
end

function PANEL:SlotTarget(card)
    local target = self.m_SlotScreen and self.m_SlotScreen[card.m_Index]
    if target and target.visible then
        return target.x, target.y
    end

    local layout = card.m_Layout or { tx = 0.5, ty = 0.5 }
    return self:GetWide() * layout.tx, self:GetTall() * layout.ty
end

function PANEL:PaintSlotCard(card, w, h)
    local slot = card.m_Slot or {}
    local selected = card.m_Index == self.m_Slot
    local excluded = IsValid(self.m_Weapon) and not self.m_Weapon:CanAttach(card.m_Index)
    local attClass = IsValid(self.m_Weapon) and CurrentAttachmentClass(self.m_Weapon, card.m_Index) or nil
    local attName = AttachmentName(attClass or slot.Default)
    local slotName = language.GetPhrase(slot.Name)

    if excluded then
        surface.SetDrawColor(80, 19, 18, 165)
    elseif selected then
        surface.SetDrawColor(20, 78, 57, 220)
    elseif card:IsHovered() then
        surface.SetDrawColor(19, 31, 31, 195)
    else
        surface.SetDrawColor(9, 15, 15, 166)
    end
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(selected and ACCENT or PANEL_LINE)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    local plusColor = selected and ACCENT or Color(216, 238, 234, 235)
    local textX = 46
    surface.SetDrawColor(plusColor.r, plusColor.g, plusColor.b, selected and 72 or 38)
    surface.DrawRect(8, 12, 28, 28)
    surface.SetDrawColor(plusColor)
    surface.DrawOutlinedRect(8, 12, 28, 28, 1)
    draw.SimpleText("+", "TRM_Mod_Subtitle", 22, 25, plusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    draw.SimpleText(TrimText("TRM_Mod_Small", string.upper(slotName), w - textX - 8), "TRM_Mod_Small", textX, 19,
        selected and ACCENT or TEXT_MAIN, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(TrimText("TRM_Mod_Tiny", attName, w - textX - 8), "TRM_Mod_Tiny", textX, 43,
        excluded and WARNING or TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function PANEL:Paint(w, h)
    self.m_Anim = math.Approach(self.m_Anim or 0, 1, RealFrameTime() * 3)

    surface.SetDrawColor(MENU_BG)
    surface.DrawRect(0, 0, w, h)

    if IsValid(self.m_ModelPanel) then
        local mx, my = self.m_ModelPanel:GetPos()
        local mw, mh = self.m_ModelPanel:GetSize()
        surface.SetDrawColor(BENCH_BG)
        surface.DrawRect(mx, my, mw, mh)
        surface.SetDrawColor(21, 36, 35, 235)
        surface.DrawOutlinedRect(mx, my, mw, mh, 1)
        surface.SetDrawColor(151, 222, 213, 18)
        surface.DrawLine(mx + 18, my + mh * 0.5, mx + mw - 18, my + mh * 0.5)
        surface.SetDrawColor(0, 0, 0, 120)
        surface.DrawRect(mx, my, mw, 42)
        draw.SimpleText("WEAPON PREVIEW", "TRM_Mod_Small", mx + 14, my + 19, TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    surface.SetDrawColor(255, 255, 255, 2)
    for x = 0, w, 128 do
        surface.DrawLine(x, 0, x, h)
    end
    for y = 0, h, 128 do
        surface.DrawLine(0, y, w, y)
    end

    draw.SimpleText("WEAPON MODDING", "TRM_Mod_Title", 28, 28, TEXT_MAIN, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local weaponName = IsValid(self.m_Weapon) and self.m_Weapon:GetPrintName() or ""
    draw.SimpleText(string.upper(weaponName), "TRM_Mod_Subtitle", 31, 57, ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    surface.SetDrawColor(PANEL_LINE)
    surface.DrawLine(24, 78, w - 24, 78)
end

function PANEL:PaintOver(w, h)
    -- Attachment slots are selected from the bottom strip; no connector lines.
end

function PANEL:PaintStats(w, h)
    surface.SetDrawColor(PANEL_BG)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(PANEL_LINE)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    draw.SimpleText("STATISTICS", "TRM_Mod_Subtitle", 14, 18, TEXT_MAIN, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("CURRENT BUILD", "TRM_Mod_Small", 14, 39, TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if not IsValid(self.m_Weapon) then return end

    local ok, stats = pcall(BuildStats, self.m_Weapon)
    if not ok or not stats or #stats == 0 then
        draw.SimpleText("NO STAT DATA", "TRM_Mod_Subtitle", 14, 82, WARNING, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Weapon stat table unavailable", "TRM_Mod_Small", 14, 106, TEXT_DIM, TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER)
        return
    end

    local contentH = 75 + #stats * 55 + 16
    self.m_StatsMaxScroll = math.max(contentH - h, 0)
    self.m_StatsScroll = math.Clamp(self.m_StatsScroll or 0, 0, self.m_StatsMaxScroll)

    if (self.m_StatsMaxScroll or 0) > 0 then
        draw.SimpleText("SCROLL STATS", "TRM_Mod_Tiny", w - 14, 39, TEXT_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local sx, sy = self.m_StatsPanel:LocalToScreen(0, 58)
    render.SetScissorRect(sx, sy, sx + w, sy + h - 6, true)

    local y = 75 - (self.m_StatsScroll or 0)
    for _, stat in ipairs(stats) do
        local name = stat[1]
        local current = Num(stat[2])
        local base = Num(stat[3])
        local biggerIsBetter = stat[4]
        local maxValue = Num(stat[5], math.max(math.abs(base) * 2, 1))
        if maxValue <= 0 then maxValue = math.max(math.abs(base) * 2, 1) end

        local delta = current - base
        local good = biggerIsBetter and delta >= 0 or delta <= 0
        local deltaColor = delta == 0 and TEXT_DIM or (good and ACTIVE or WARNING)
        local ratio = math.Clamp(current / maxValue, 0, 1)
        local baseRatio = math.Clamp(base / maxValue, 0, 1)
        if not biggerIsBetter then
            ratio = 1 - ratio
            baseRatio = 1 - baseRatio
        end

        draw.SimpleText(string.upper(name), "TRM_Mod_Small", 14, y, TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%.3g", current), "TRM_Mod_Small", w - 14, y, TEXT_MAIN, TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER)

        surface.SetDrawColor(42, 55, 54, 230)
        surface.DrawRect(14, y + 13, w - 28, 8)
        surface.SetDrawColor(ACCENT)
        surface.DrawRect(14, y + 13, (w - 28) * ratio * self.m_Anim, 8)
        surface.SetDrawColor(deltaColor)
        surface.DrawRect(14 + (w - 28) * math.min(ratio, baseRatio) * self.m_Anim, y + 13,
            (w - 28) * math.abs(ratio - baseRatio) * self.m_Anim, 8)

        if delta ~= 0 then
            local deltaText = (delta > 0 and "+" or "") .. string.format("%.3g", delta)
            draw.SimpleText(deltaText, "TRM_Mod_Small", w - 14, y + 30, deltaColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        y = y + 55
    end

    render.SetScissorRect(0, 0, 0, 0, false)
end

function PANEL:PaintAttachmentPanel(w, h)
    surface.SetDrawColor(PANEL_BG)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(PANEL_LINE)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    local slot = IsValid(self.m_Weapon) and self.m_Weapon.Attachments and self.m_Weapon.Attachments[self.m_Slot]
    local slotName = language.GetPhrase(slot.Name)
    local attClass = IsValid(self.m_Weapon) and CurrentAttachmentClass(self.m_Weapon, self.m_Slot) or nil

    draw.SimpleText(string.upper(slotName), "TRM_Mod_Subtitle", 14, 18, TEXT_MAIN, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(TrimText("TRM_Mod_Small", AttachmentName(attClass or (slot and slot.Default)), w - 28),
        "TRM_Mod_Small", 14, 40, ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local boneText = slot and slot.Bone and ("BONE  " .. slot.Bone) or "NO BONE MAPPING"
    draw.SimpleText(TrimText("TRM_Mod_Small", boneText, w - 28), "TRM_Mod_Small", 14, 60, TEXT_DIM, TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER)

    draw.SimpleText(Phrase("#TRMBase_CloseHint", "Close with the customize key or Back"), "TRM_Mod_Small", w / 2, h - 24,
        TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:SetWeapon(weapon)
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end

    self.m_Weapon = weapon
    self.m_Slot = 1

    self:SetupModel()
    self:RebuildSlotCards()
    self:RefreshPreview()
    self:RefreshAttList()
end

function PANEL:RefreshAll()
    self:RebuildSlotCards()
    self:RefreshPreview()
    self:RefreshAttList()
end

function PANEL:RefreshAttList()
    if not IsValid(self.m_AttList) then return end
    self.m_AttList:Clear()

    if not IsValid(self.m_Weapon) then return end
    local slot = self.m_Weapon.Attachments and self.m_Weapon.Attachments[self.m_Slot]
    if not slot then return end

    local slotKey = tostring(self.m_Slot)
    local currentAtt = CurrentAttachmentClass(self.m_Weapon, self.m_Slot)
    local slotExcluded = not self.m_Weapon:CanAttach(self.m_Slot)


    local skipDefault = nil
    if slot.Default and BASE_TRM_ATTS and BASE_TRM_ATTS[slot.Default] then
        skipDefault = slot.Default
        self:AddAttButton(AttachmentName(slot.Default), slot.Default, currentAtt == slot.Default, slotKey, false, true)
    else
        self:AddAttButton(Phrase("#TRMBase_None", "None"), nil, currentAtt == nil or currentAtt == "None", slotKey, false,
            false)
    end

    for _, attClass in ipairs(GetAttachmentsForSlot(slot)) do
        if skipDefault and attClass == skipDefault then continue end
        self:AddAttButton(AttachmentName(attClass), attClass, currentAtt == attClass, slotKey, slotExcluded, false)
    end

    local totalH = 0
    for _, child in ipairs(self.m_AttList:GetChildren()) do
        totalH = totalH + child:GetTall() + 6
    end
    self.m_AttList:SetTall(math.max(totalH, 1))
    self.m_AttScroll:InvalidateLayout()
end

function PANEL:AddAttButton(name, attClass, isActive, slotKey, slotExcluded, isDefault)
    local btn = vgui.Create("DButton", self.m_AttList)
    btn:SetText("")
    btn:Dock(TOP)
    btn:SetTall(64)
    btn:DockMargin(0, 0, 0, 6)

    local weapon = self.m_Weapon

    btn.Paint = function(button, w, h)
        local blocked = slotExcluded and not isActive

        if isActive then
            surface.SetDrawColor(18, 55, 39, 238)
        elseif blocked then
            surface.SetDrawColor(58, 21, 21, 228)
        elseif button:IsHovered() then
            surface.SetDrawColor(23, 36, 36, 232)
        else
            surface.SetDrawColor(12, 20, 20, 220)
        end
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(isActive and ACTIVE or PANEL_LINE)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        local markerW = isActive and 0 or 28
        local textX = markerW > 0 and 44 or 12
        if not isActive then
            surface.SetDrawColor(blocked and Color(160, 70, 70, 54) or Color(151, 222, 213, 35))
            surface.DrawRect(12, 16, 24, 24)
            surface.SetDrawColor(blocked and WARNING or ACCENT)
            surface.DrawOutlinedRect(12, 16, 24, 24, 1)
            draw.SimpleText("+", "TRM_Mod_Subtitle", 24, 28, blocked and WARNING or ACCENT, TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER)
        end

        local statusReserve = (isActive or blocked) and 110 or 18
        local title = TrimText("TRM_Mod_Subtitle", name, w - textX - statusReserve)
        draw.SimpleText(title, "TRM_Mod_Subtitle", textX, 20, blocked and Color(190, 112, 112) or TEXT_MAIN,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local sub = attClass or "None"
        if isDefault then sub = sub .. " / default" end
        draw.SimpleText(TrimText("TRM_Mod_Small", sub, w - textX - statusReserve), "TRM_Mod_Small", textX, 45,
            blocked and WARNING or TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if isActive then
            draw.SimpleText(language.GetPhrase("TRMBase_Installed"), "TRM_Mod_Small", w - 12, 20, ACTIVE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        elseif blocked then
            draw.SimpleText(Phrase("#TRMBase_Excluded", "Excluded"), "TRM_Mod_Small", w - 12, 20, WARNING,
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    btn.DoClick = function()
        if slotExcluded and not isActive then
            surface.PlaySound("weapons/ar2/ar2_empty.wav")
            return
        end

        local id = attClass or "None"
        if not IsValid(weapon) then return end

        weapon.CurrentAttachments = weapon.CurrentAttachments or {}
        weapon.CurrentAttachments[slotKey] = (id ~= "None") and { Class = id } or nil
        weapon:SendAttachmentToServer(slotKey, id)

        surface.PlaySound("weapons/ar2/ar2_empty.wav")
        self:RefreshPreview()
        self:RefreshAll()
    end
end

function PANEL:Close()
    gui.EnableScreenClicker(false)
    TRM_AttachMenu_Instance = nil
    self:RemovePreviewModels()
    self:Remove()
end

vgui.Register("TRM_AttachMenu", PANEL, "DFrame")

concommand.Add("+trmbase_customize", function(ply)
    if not IsValid(TRM_AttachMenu_Instance) then
        local player = IsValid(ply) and ply or LocalPlayer()
        local weapon = IsValid(player) and player:GetActiveWeapon()
        if not IsValid(weapon) or not util.IsTRMBase(weapon) then
            print("[TRMBase] Current weapon is not a TRM Base weapon")
            return
        end

        gui.EnableScreenClicker(true)

        local frame = vgui.Create("TRM_AttachMenu")
        frame:SetWeapon(weapon)
        TRM_AttachMenu_Instance = frame
    else
        TRM_AttachMenu_Instance:Close()
    end
end)

net.Receive("TRMBase_SyncAttachment", function()
    local wep = net.ReadEntity()
    local slot = net.ReadString()
    local attClass = net.ReadString()

    if not IsValid(wep) then return end

    wep.CurrentAttachments = wep.CurrentAttachments or {}
    if attClass == "None" then
        wep.CurrentAttachments[slot] = nil
    else
        wep.CurrentAttachments[slot] = { Class = attClass }
    end

    if wep.BuildCustomizedGun then
        wep:BuildCustomizedGun()
    end
    wep.m_NeedsBuild = true

    if IsValid(TRM_AttachMenu_Instance) then
        TRM_AttachMenu_Instance:RefreshAll()
    end
end)

net.Receive("TRMBase_SyncAllAttachments", function()
    local wep = net.ReadEntity()
    if not IsValid(wep) then return end

    local count = net.ReadUInt(8)
    wep.CurrentAttachments = wep.CurrentAttachments or {}

    for i = 1, count do
        local slot = net.ReadString()
        local attClass = net.ReadString()
        wep.CurrentAttachments[slot] = { Class = attClass }
    end

    if wep.BuildCustomizedGun then
        wep:BuildCustomizedGun()
    end
    wep.m_NeedsBuild = true

    if IsValid(TRM_AttachMenu_Instance) then
        TRM_AttachMenu_Instance:RefreshAll()
    end
end)

concommand.Add("trmbase_test_attach", function(ply, cmd, args)
    local player = IsValid(ply) and ply or LocalPlayer()
    local weapon = IsValid(player) and player:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end

    local slotKey = args[1] or ""
    local attID = args[2] or ""
    weapon:SendAttachmentToServer(slotKey, attID)
end)

concommand.Add("trmbase_rebuild_attach", function(ply)
    local player = IsValid(ply) and ply or LocalPlayer()
    local weapon = IsValid(player) and player:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end

    if weapon.CurrentAttachments then
        for _, entry in pairs(weapon.CurrentAttachments) do
            if entry then
                weapon:RemoveAttachmentModel(entry)
            end
        end
    end

    print("[TRMBase] Attachment models rebuilt")
end)

concommand.Add("trmbase_show_attach", function(ply)
    local player = IsValid(ply) and ply or LocalPlayer()
    local weapon = IsValid(player) and player:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end

    print("-----------------------------------")
    print(weapon:GetPrintName())
    print("Can Attach")
    PrintTable(weapon.Attachments)
    print("Equipped:")
    PrintTable(weapon.CurrentAttachments)
end)

concommand.Add("trmbase_debug_slots", function(ply)
    local player = IsValid(ply) and ply or LocalPlayer()
    local weapon = IsValid(player) and player:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then
        print("[TRMBase] Current weapon is not TRM Base")
        return
    end

    print("========== TRMBase Slot Debug ==========")
    print("Total attachments in BASE_TRM_ATTS: " .. table.Count(BASE_TRM_ATTS or {}))

    print("--- All attachments with Category ---")
    for name, data in pairs(BASE_TRM_ATTS or {}) do
        if type(data) == "table" and data.Category then
            print("  " ..
            name .. " -> Category: " .. tostring(data.Category) .. ", Selectable: " .. tostring(data.Selectable))
        end
    end

    if not weapon.Attachments then
        print("Weapon has no Attachments table")
        return
    end

    print("--- Weapon Attachments (" .. #weapon.Attachments .. " slots) ---")
    for i, slot in ipairs(weapon.Attachments) do
        if istable(slot) then
            print("Slot " ..
            i ..
            ": Name=" ..
            tostring(slot.Name) ..
            ", Category={" .. table.concat(SlotCategories(slot), ", ") .. "}, Bone=" .. tostring(slot.Bone))

            local matches = GetAttachmentsForSlot(slot)
            if #matches > 0 then
                print("  -> Matches: " .. table.concat(matches, ", "))
            else
                print("  -> NO MATCHES!")
            end
        else
            print("Slot " .. i .. ": NOT A TABLE! type=" .. type(slot))
        end
    end
    print("========================================")
end)

local cvar_hide = CreateClientConVar("trmbase_hidehud_inspect", 1, FCVAR_ARCHIVE)
hook.Add("HUDShouldDraw", "HideWhileCustomizing", function()
    if IsValid(TRM_AttachMenu_Instance) then
        return false
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if util.IsTRMBase(wep) and IsValid(wep) then
        if wep:IsInspecting() and cvar_hide:GetBool() then
            return false
        end
    end
end)


