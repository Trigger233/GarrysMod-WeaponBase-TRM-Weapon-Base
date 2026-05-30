if not CLIENT then return end

-- =============================================
-- 世界模型渲染 — SetRenderOrigin/Angles 方式
-- Offset = { Pos = Vector, Ang = Angle }
--   基于玩家右手骨骼 + SetRenderOrigin
-- =============================================




-- =============================================
-- DrawWorldModel — 每帧由引擎调用
-- =============================================
function SWEP:DrawWorldModel(flags)
    if self.m_NeedsBuild and self.BuildCustomizedGun then
        -- print(CurTime())
        self:BuildCustomizedGun()
        self.m_NeedsBuild = false
    end

    -- 先计算骨骼变换，再画模型
    if self.WorldModelOffsets.Bone then
        local bone = self:LookupBone(self.WorldModelOffsets.Bone)
        if bone and bone > 0 and IsValid(self:GetOwner()) then
            self:ManipulateBoneAngles(bone, self.WorldModelOffsets.Angles)
            self:ManipulateBonePosition(bone, self.WorldModelOffsets.Pos)
        end
    else
        self:SetRenderOrigin(self.WorldModelOffsets.Pos)
        self:SetRenderAngles(self.WorldModelOffsets.Angles)
    end
    self:DrawModel(flags)
    if self.CurrentAttachments then
        for _, entry in pairs(self.CurrentAttachments) do
            if IsValid(entry.m_TpModel) then
                entry.m_TpModel:DrawModel()
            end
        end
    end
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
