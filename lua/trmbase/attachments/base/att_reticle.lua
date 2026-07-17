-- att_sight.lua（瞄具配件通用基类）
ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_sight"
ATTACHMENT.Description = "The Base for Sight Attachments"


function ATTACHMENT:Render(weapon, model)
    -- 如果有分划板配置，渲染红点/分划板
    if self.Sight and self.Sight.Material then
        self:RenderReticle(weapon, model, self.Sight)
    end
end

require("trm_utils")
-- 渲染红点/分划板（使用 Stencil 遮罩）
function ATTACHMENT:RenderReticle(weapon, model, ret)
    if not ret or not ret.Material then return end

    -- 获取红点显示位置（附件点）
    self:ApplyReticleMaterial(weapon, model, ret)

    local att = trm_utils.GetFastAttachment(model, ret.Align)
    if not att then return end

    -- 开始 Stencil 遮罩
    render.ClearStencil()
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(0)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilEnable(true)
    render.SetStencilReferenceValue(TRM_BASE_REF + 1)

    -- 写入遮罩区域
    model:DrawModel()
    render.SetStencilCompareFunction(STENCIL_LESSEQUAL)

    -- 渲染红点
    local length = 1000
    local size = ret.Size or 5.12
    local color = ret.Color or Color(255, 0, 0, 255)
    render.SetMaterial(ret.Material)

    local offset = att.Ang:Forward() * 100
    if ret.Offset then
        offset = offset + att.Ang:Right() * ret.Offset.x
        offset = offset + att.Ang:Up() * ret.Offset.y
    end
    local roll = -att.Ang.r + 180
    if ret.Rotate then
        roll = roll + ret.Rotate
    end
    render.DrawQuadEasy(att.Pos + offset, att.Ang:Forward():GetNegated(), size, size, color, roll)
    render.ClearStencil()
    render.SetStencilEnable(false)
end

if CLIENT then
    local LenMaterial = CreateMaterial("trm_attachment_lens", "VertexLitGeneric", {
        ["$basetexture"] = "color/white",
        ["$model"] = "1",
        ["$selfillum"] = "1",
        ["$color2"] = "[0 0 0]",
        ["$nocull"] = "1",
        ["$nodecal"] = "1",
        ["$translucent"] = "1",
        ["$additive"] = "1"

    })
end


function ATTACHMENT:ApplyReticleMaterial(weapon, model, ret)
    if ! ret or ! ret.Hide or SERVER then return end

    local len = nil
    if weapon:GetAimDelta() > 0.5 then
        len = "!trm_attachment_lens"
    end

    model:SetSubMaterial(ret.Hide, len)
end
