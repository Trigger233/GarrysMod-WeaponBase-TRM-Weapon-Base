ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_reticle"
ATTACHMENT.Description = "The Base for Weapon"
ATTACHMENT.Selectable = false

function ATTACHMENT:Render(wep, model)
    if wep:IsCarriedByLocalPlayer() then
        self:RenderScope(wep, model)
    else
        model:DrawModel()
    end
end

function ATTACHMENT:RenderScope(wep, model)
    if not IsValid(model) then return end

    -- 获取瞄准点位置
    local scopeAlign = self.Sight and self.Sight.Align
    if not scopeAlign then
        model:DrawModel()
        return
    end

    local scopeAtt = model:GetAttachment(model:LookupAttachment(scopeAlign))
    if not scopeAtt then
        model:DrawModel()
        return
    end

    -- 获取屏幕上的瞄准位置
    local scopePos = scopeAtt.Pos
    local scopeAng = scopeAtt.Ang
    local screen = scopePos:ToScreen()
    if not screen or not screen.visible then
        model:DrawModel()
        return
    end

    -- 渲染瞄准镜本体模型
    model:DrawModel()

    -- ========== 绘制准星分划 ==========
    if self.Sight.Material then
        local mat = self.Sight.Material
        local size = self.Sight.Size or 256
        local color = self.Sight.Color or Color(255, 0, 0)
        local aimDelta = wep.GetAimDelta and wep:GetAimDelta() or 1

        if aimDelta > 0.5 then
            local alpha = (aimDelta - 0.5) * 2
            local c = Color(color.r, color.g, color.b, alpha * 255)
            render.SetScissorRect(0, 0, ScrW(), ScrH(), true)
            surface.SetMaterial(mat)
            surface.SetDrawColor(c)
            surface.DrawTexturedRect(
                screen.x - size * 0.5,
                screen.y - size * 0.5,
                size,
                size
            )
            render.SetScissorRect(0, 0, 0, 0, false)
        end
    end

    -- ========== 镜框遮罩（可选） ==========
    if self.Scope and self.Scope.Align then
        local scopeData = model:GetAttachment(model:LookupAttachment(self.Scope.Align))
        if scopeData then
            local pos = scopeData.Pos + scopeData.Ang:Forward() * -2
            local forward = scopeData.Ang:Forward()
            local scopeSize = self.Scope.Size or 2

            render.SetStencilEnable(true)
            render.ClearStencil(0)
            render.SetStencilWriteMask(1)
            render.SetStencilTestMask(1)
            render.SetStencilReferenceValue(1)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
            render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
            render.SetStencilFailOperation(STENCILOPERATION_KEEP)
            render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

            render.SetMaterial(Material("vgui/white"))
            render.DrawQuadEasy(pos, forward:GetNegated(), scopeSize, scopeSize, Color(255, 255, 255, 255), -scopeData.Ang.r)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_LESSEQUAL)
            render.SetStencilPassOperation(STENCILOPERATION_KEEP)

            render.SetStencilEnable(false)
        end
    end
end
