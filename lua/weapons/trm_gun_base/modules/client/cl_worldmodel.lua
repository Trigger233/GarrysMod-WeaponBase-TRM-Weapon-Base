if not CLIENT then return end

-- =============================================
-- 世界模型渲染 — SetRenderOrigin/Angles 方式
-- Offset = { Pos = Vector, Ang = Angle }
--   基于玩家右手骨骼 + SetRenderOrigin
-- =============================================

--- 应用世界模型变换
function SWEP:WorldModelOffsetUpdate(ply)
    if not IsValid(ply) then
        self:SetRenderOrigin(nil)
        self:SetRenderAngles(nil)
        return
    end

    local offset = self.Offset
    if not offset then return end

    local handBone = ply:LookupBone("ValveBiped.Bip01_R_Hand")
    if not handBone then return end

    local mat = ply:GetBoneMatrix(handBone)
    if not mat then return end

    local pos, ang = mat:GetTranslation(), mat:GetAngles()

    if offset.Pos then
        pos = pos + ang:Right() * offset.Pos.x
        pos = pos + ang:Forward() * offset.Pos.y
        pos = pos + ang:Up() * offset.Pos.z
    end

    if offset.Ang then
        ang:RotateAroundAxis(ang:Up(), offset.Ang.yaw or offset.Ang.y or 0)
        ang:RotateAroundAxis(ang:Right(), offset.Ang.pitch or offset.Ang.p or 0)
        ang:RotateAroundAxis(ang:Forward(), offset.Ang.roll or offset.Ang.r or 0)
    end

    self:SetRenderOrigin(pos)
    self:SetRenderAngles(ang)
end

-- =============================================
-- DrawWorldModel — 每帧由引擎调用
-- =============================================
function SWEP:DrawWorldModel(flags)
    local ply = self:GetOwner()
    local validowner = IsValid(ply)

    if validowner then
        self:WorldModelOffsetUpdate(ply)
    else
        self:SetRenderOrigin(nil)
        self:SetRenderAngles(nil)
    end

    local showWorldModel = (self.ShowWorldModel == nil or self.ShowWorldModel or not validowner)
    if showWorldModel then
        self:DrawModel()
    end
end

function SWEP:DrawWorldModelTranslucent(flags)
    self:DrawWorldModel(flags)
end

-- =============================================
-- 清理 TP 配件模型（武器移除时子实体不会自动移除）
-- =============================================
function SWEP:OnRemove()
    if self.TpAttachmentModels then
        for _, model in pairs(self.TpAttachmentModels) do
            if IsValid(model) then
                model:Remove()
            end
        end
        self.TpAttachmentModels = nil
    end
end
