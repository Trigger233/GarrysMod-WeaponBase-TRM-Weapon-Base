if SERVER then return end
local flashlightMat = "effects/flashlight/hard"

SWEP.m_ProjectTexture = {} -- 存储投影纹理 { [attachmentName] = ProjectedTexture }

function SWEP:DrawCustomizionFlashLight(pos, ang, attachment)
    if not self.flashlight then return end

    if not self:HasFlag("FlashLightOn") then
        self:CleanupFlashLights()
        return
    end

    -- 创建或获取投影纹理
    if not IsValid(self.m_ProjectTexture[attachment]) then
        self.m_ProjectTexture[attachment] = ProjectedTexture()
        local proj = self.m_ProjectTexture[attachment]
        proj:SetFOV(50)
        proj:SetNearZ(8)
        proj:SetFarZ(1000)
        proj:SetBrightness(0.8)
        proj:SetColor(Color(255, 255, 200))
        proj:SetTexture(flashlightMat)
        
    end

    local proj = self.m_ProjectTexture[attachment]
    proj:SetPos(pos)
    proj:SetAngles(ang)
    proj:Update()
end

-- 关闭手电筒时禁用所有投影


-- 清理（换武器或卸下配件时）
function SWEP:CleanupFlashLights()
    if not self.m_ProjectTexture then return end
    for name, proj in pairs(self.m_ProjectTexture) do
        if IsValid(proj) then
            proj:Remove()
        end
    end
    self.m_ProjectTexture = {}
end
