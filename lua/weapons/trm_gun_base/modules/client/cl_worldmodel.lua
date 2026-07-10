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
    if  center == nil then
        center = true
    end
    local w = center and srf.GetTextSize(text) or 0
    DrawText(text, x - w / 2, y, color)
    DrawText(text, x - w / 2 + 2, y, colorTable.shadow)
end

local function GetPhrase(text)
    return language.GetPhrase(text)
end

local cvar_3d2d = CreateClientConVar("trmbase_cl_3d2d", 1,true, true, "helptext", 0, 1)
local cvar_3d2d_always = CreateClientConVar("trmbase_cl_3d2d_always", 0, true, true, "",0, 1)
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
    y = y + 20
    text = GetPhrase(game.GetAmmoName(self:GetPrimaryAmmoType()) .. "_ammo") or ""
    DrawFullText(text, x, y, colorTable.common)
    y= y + 10
    for slot, entry in pairs(self:GetAllAttachmentsInUse()) do
        local class = entry.Class
        if entry and class then

            local wepData = self.Attachments[tonumber(slot)]

            if wepData and wepData.Default and wepData.Default == class then
                continue
            end

            local Data = BASE_TRM_ATTS[class]

            text = Data.Name or ""
            y = y + 30
            DrawFullText(text, x - 100, y, colorTable.common,false)
        end
    end

    cam.End3D2D()
    cam.End3D()
end

function SWEP:RenderOverride(flags)
    local off = self.WorldModelOffsets
    local owner = self:GetOwner()
    if self:GetNoDraw() then return end

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
            if IsValid(entry.m_TpModel) and att.Render then
                entry.m_TpModel:SetupBones()
                att:Render(self, entry.m_TpModel)
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
    if cvar_3d2d:GetBool() and (EyePos() - self:WorldSpaceCenter()):LengthSqr() <= 262144 and (cvar_3d2d_always:GetBool()  or LocalPlayer():GetEyeTrace().Entity == self) then
        self:DrawWorldModelName()
    end
end

function SWEP:DrawWorldModelTranslucent(flags)
    self:DrawWorldModel(flags)
end

local LHIK = {
    "ValveBiped.Bip01_L_Wrist",
    "ValveBiped.Bip01_L_Ulna",
    "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_L_Finger4",
    "ValveBiped.Bip01_L_Finger41",
    "ValveBiped.Bip01_L_Finger42",
    "ValveBiped.Bip01_L_Finger3",
    "ValveBiped.Bip01_L_Finger31",
    "ValveBiped.Bip01_L_Finger32",
    "ValveBiped.Bip01_L_Finger2",
    "ValveBiped.Bip01_L_Finger21",
    "ValveBiped.Bip01_L_Finger22",
    "ValveBiped.Bip01_L_Finger1",
    "ValveBiped.Bip01_L_Finger11",
    "ValveBiped.Bip01_L_Finger12",
    "ValveBiped.Bip01_L_Finger0",
    "ValveBiped.Bip01_L_Finger01",
    "ValveBiped.Bip01_L_Finger02"

}

local newMatrix = Matrix()
local delta = 0
function SWEP:DoTPIK()
    local ik = self:GetForegrip()
    if ik == nil then return end

    local owner = self:GetOwner()
    if not owner or not owner:IsPlayer() then return end
    local ikmodel = ik.Worldmodel

    if ikmodel != nil then
        delta = math.Approach(delta, self:GetGrip1() and 1 or 0, engine.TickInterval())
        owner:SetupBones()
        ikmodel:SetupBones()
        for _, boneName in pairs(LHIK) do
            local wmBone = owner:LookupBone(boneName)
            local ikBone = ikmodel:LookupBone(boneName)
            if not wmBone or not ikBone then continue end

            local wmMatrix = owner:GetBoneMatrix(wmBone)
            local ikMatrix = ikmodel:GetBoneMatrix(ikBone)
            if not wmMatrix or not ikMatrix then continue end


            --debugoverlay.Axis(ikMatrix:GetTranslation(), ikMatrix:GetAngles(), 5, 0.2, true)
            newMatrix:SetTranslation(LerpVector(delta, wmMatrix:GetTranslation(), ikMatrix:GetTranslation()))
            newMatrix:SetAngles(LerpAngle(delta, wmMatrix:GetAngles(), ikMatrix:GetAngles()))

            owner:SetBoneMatrix(wmBone, newMatrix)
            --owner:SetBonePosition(wmBone, newMatrix:GetTranslation(), newMatrix:GetAngles())
        end
    end
end

-- hook.Add("PrePlayerDraw", "TRMBase_Tpik", function(player, flags)
--     local weapon = player:GetActiveWeapon()
--     if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end

--     -- if weapon.DoTPIK then
--     --     weapon:DoTPIK()
--     -- end

-- end)
