-- =============================================
-- 世界模型渲染 — SetRenderOrigin/Angles 兼容模式
-- WorldModelOffsets 支持两种模式：
--   1. ManipulateBone（默认）：Bone + Pos + Angles
--   2. SetRenderOrigin（设置 UseRenderOrigin = true）：基于玩家右手骨骼 + SetRenderOrigin
-- =============================================

local function GetHandBonePosAng(ply)
    if not IsValid(ply) then return nil, nil end
    local bone = ply:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bone or bone <= 0 then
        bone = ply:LookupBone("R Hand")
    end
    if not bone or bone <= 0 then return nil, nil end
    return ply:GetBonePosition(bone)
end

-- =============================================
-- DrawWorldModel — 每帧由引擎调用
-- =============================================
local srf = surface
--
local colorTable = {
    common = Color(255, 255, 255, 255),
    shadow = Color(0, 0, 0, 150)
}
local function DrawText(text, x, y, color)
    srf.SetTextPos(x, y)
    srf.SetTextColor(color.r, color.g, color.b, color.a)
    srf.DrawText(text)
end


local function DrawFullText(text, x, y, color, center)
    if center == nil then
        center = true
    end
    local w = center and srf.GetTextSize(text) or 0
    DrawText(text, x - w / 2, y, color)
    DrawText(text, x - w / 2 + 2, y, colorTable.shadow)
end

local function GetPhrase(text)
    return language.GetPhrase(text)
end

local cvar_3d2d = CreateClientConVar("trmbase_cl_3d2d", 1, true, true, "helptext", 0, 1)
local cvar_3d2d_always = CreateClientConVar("trmbase_cl_3d2d_always", 0, true, true, "", 0, 1)
function SWEP:DrawWorldModelName()
    local viewer = LocalPlayer()
    local x, y = 0, 0
    cam.Start3D(EyePos(), EyeAngles(), nil, nil, nil, nil, nil, nil, nil)
    local ang = viewer:EyeAngles()

    ang:RotateAroundAxis(ang:Forward(), 180)
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), 90)

    cam.Start3D2D(self:WorldSpaceCenter() + Vector(0, 0, 16), ang, 0.1)
    srf.SetFont("TRM_Mod_Title")
    local text = self.PrintName or "Unknown"
    DrawFullText(text, x, y, colorTable.common)
    y = y + 10
    for slot, entry in pairs(self:GetAllAttachmentsInUse()) do
        local class = entry.Class
        if entry and class then
            local wepData = self.Attachments[tonumber(slot)]

            if wepData and wepData.Default and wepData.Default == class then
                continue
            end

            local Data = BASE_TRM_ATTS[class]
            if not Data then continue end
            text = Data.Name or ""
            y = y + 30
            DrawFullText(text, x - 100, y, colorTable.common, false)
        end
    end

    cam.End3D2D()
    cam.End3D()
end

function SWEP:RenderOverride(flags)
    local off = self.WorldModelOffsets
    local owner = self:GetOwner()
    if self:GetNoDraw() then
        self:RemoveAllAttachementModels()
        return
    end

    self:SetupBones()
    self:DrawModel(flags)
    if off and not off.Bone and IsValid(owner) then
        -- == SetRenderOrigin/SetRenderAngles 模式 ==
        local handPos, handAng = GetHandBonePosAng(owner)
        if handPos then
            local origin = Vector(handPos)
            local angles = handAng

            if off.Pos then
                origin:Add(angles:Right() * off.Pos.x)
                origin:Add(angles:Forward() * off.Pos.y)
                origin:Add(angles:Up() * off.Pos.z)
            end
            if off.Angles then
                angles:RotateAroundAxis(angles:Up(), off.Angles[1])
                angles:RotateAroundAxis(angles:Right(), off.Angles[2])
                angles:RotateAroundAxis(angles:Forward(), off.Angles[3])
            end
            self:SetRenderOrigin(origin)
            self:SetRenderAngles(angles)
            self.m_RenderOffset = true
        end
    elseif off and off.Bone then
        -- == ManipulateBone 模式 ==
        local bone = self:LookupBone(off.Bone)
        if bone and bone > 0 and IsValid(owner) then
            self:ManipulateBoneAngles(bone, off.Angles)
            self:ManipulateBonePosition(bone, off.Pos)
        end
    end

    if self.m_RenderOffset and not IsValid(owner) then
        self:SetRenderAngles(nil)
        self:SetRenderOrigin(nil)
        self.m_RenderOffset = false
    end

    if self.CurrentAttachments then
        for _, entry in pairs(self.CurrentAttachments) do
            local att = BASE_TRM_ATTS[entry.Class]
            if ! att then continue end
            if IsValid(entry.m_TpModel) and att.Render then
                entry.m_TpModel:SetupBones()
                att:Render(self, entry.m_TpModel)
            elseif att.Model then
                self:BuildCustomizedGun()
            end
        end
    end
end

local cvar_holster = GetConVar("trmbase_sv_holster_on_ladder")
function SWEP:DrawWorldModel(flags)
    local owner = self:GetOwner()
    if owner:IsPlayer() and owner:GetActiveWeapon() == self and owner:GetMoveType() == MOVETYPE_LADDER and cvar_holster:GetBool() then
        return
    end
    self:DrawModel(flags)
    if cvar_3d2d:GetBool() and (EyePos() - self:WorldSpaceCenter()):LengthSqr() <= 262144 and (cvar_3d2d_always:GetBool() or LocalPlayer():GetEyeTrace().Entity == self) then
        self:DrawWorldModelName()
    end
end

function SWEP:DrawWorldModelTranslucent(flags)
    self:DrawWorldModel(flags)
end

function SWEP:DrawHolsterModel(flag)
    self:SetRenderOrigin(self:GetShootPos())
    self:DrawWorldModel()
end

local function cheakModelIsVaildInWeapon(ent, wep)
    if not wep.GetAllAttachmentsInUse then return end
    for _, entry in pairs(wep:GetAllAttachmentsInUse()) do
        if (entry.m_Model and entry.m_Model == ent) or (entry.m_TpModel and entry.m_TpModel == ent) then
            return true
        end
    end
    return false
end

local LastRenderUpdate = 0

hook.Add("PreRender", "TRMBase_CleanupUnUsedAttModels", function()
    if SysTime() - LastRenderUpdate > 0 and not IsValid(TRM_AttachMenu_Instance) then
        local ply = LocalPlayer()
        local currentWeapon = ply:GetActiveWeapon()

        local distanceSqr = IsValid(currentWeapon)
            and currentWeapon:WorldSpaceCenter():DistToSqr(EyePos())
        for _, ent in ents.Iterator() do
            if ent:GetClass() == "class C_BaseFlex" and ent.TRMAttachmentModel then
                local owner = ent:GetOwner()
                if (not IsValid(owner) or not cheakModelIsVaildInWeapon(ent, owner)) or (EyePos() - owner:WorldSpaceCenter()):LengthSqr() > (distanceSqr or 1048576) then
                    --print(ent.TRMAttachmentModel)
                    -- print("Remove :", ent:GetModel())
                    ent:Remove()
                    continue
                end
            end
            if ent:GetNoDraw() and ent.RemoveAllAttachementModels then
                ent:RemoveAllAttachementModels()
            end
        end
        LastRenderUpdate = SysTime() + 5
    end
end)

hook.Add("HUDPaint", "debug", function()
    if ! GetConVar("developer"):GetBool() then return end
    local w, h = ScrW(), ScrH()
    local cBaseEntCount = 0
    local y = 0
    for _, ent in ents.Iterator() do
        if ent:GetClass() == "class C_BaseFlex" then
            cBaseEntCount = cBaseEntCount + 1
            --draw.SimpleText(ent:GetModel().." | "..tostring(ent:GetOwner()) , "Default", 0, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            y = y + 20
        end
    end
    draw.SimpleText(cBaseEntCount, "Default", 0, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)
