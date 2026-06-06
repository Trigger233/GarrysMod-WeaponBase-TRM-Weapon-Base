
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
        bone = ply:LookupBone("RightHand")
    end
    if not bone or bone <= 0 then return nil, nil end
    return ply:GetBonePosition(bone)
end

-- =============================================
-- DrawWorldModel — 每帧由引擎调用
-- =============================================
function SWEP:RenderOverride(flags)
    
    if self.m_NeedsBuild and self.BuildCustomizedGun then
        self:BuildCustomizedGun()
        self.m_NeedsBuild = false
    end

    local off = self.WorldModelOffsets
    local owner = self:GetOwner()

    if off and not off.Bone and IsValid(owner) then
        -- == SetRenderOrigin/SetRenderAngles 模式 ==
        local handPos, handAng = GetHandBonePosAng(owner)
        if handPos then
            local origin = Vector(handPos)
            local angles = Angle(handAng)

            if off.Pos then
                origin:Add(angles:Right() * off.Pos.x)
                origin:Add(angles:Forward() * off.Pos.y)
                origin:Add(angles:Up() * off.Pos.z)
            end
            if off.Angles then
                angles:Add(off.Angles)
            end

            self:SetRenderOrigin(origin)
            self:SetRenderAngles(angles)
        end
    elseif off and off.Bone then
        -- == ManipulateBone 模式 ==
        local bone = self:LookupBone(off.Bone)
        if bone and bone > 0 and IsValid(owner) then
            self:ManipulateBoneAngles(bone, off.Angles)
            self:ManipulateBonePosition(bone, off.Pos)
        end
    end

    self:SetupBones()
    self:DrawModel(flags)

    if self.CurrentAttachments then
        for _, entry in pairs(self.CurrentAttachments) do
            local att = BASE_TRM_ATTS[entry.Class]
            if IsValid(entry.m_TpModel) and att.Render then
                entry.m_TpModel:InvalidateBoneCache()
                entry.m_TpModel:SetupBones()
                att:Render(self,entry.m_TpModel)
            end
        end
    end
end

function SWEP:DrawWorldModel(flags)
    self:DrawModel(flags)
end

function SWEP:DrawWorldModelTranslucent(flags)
    self:DrawWorldModel(flags)
end

-- =============================================
-- 清理 TP 配件模型（武器移除时子实体不会自动移除）
-- =============================================
function SWEP:OnRemove()
    if self.CurrentAttachments then
        for _, entry in pairs(self.CurrentAttachments) do
            if entry then
                self:RemoveAttachmentModel(entry, true)
            end
        end
    end
end
