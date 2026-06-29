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
function SWEP:RenderOverride(flags)
    local off = self.WorldModelOffsets
    local owner = self:GetOwner()
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
end

function SWEP:DrawWorldModelTranslucent(flags)
    self:DrawWorldModel(flags)
end

-- =============================================
-- 清理 TP 配件模型（武器移除时子实体不会自动移除）
-- =============================================
