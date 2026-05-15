ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_reticle"
ATTACHMENT.Description = "The Base for Weapon"

function ATTACHMENT:Render(wep , model)
    BASE_TRM_ATTS[self.Base]:Render(wep,model)
    if wep:IsCarriedByLocalPlayer() then 
        self:RenderScope(wep , model )
  
    end
        

end


--ATTACHMENT._RTTexture = GetRenderTarget("scope_rt", 512, 512)

function ATTACHMENT:RenderScope(wep, model)
    local _Hide = {2,3,5}
    local _Lense = {4}

    local function SetMat(_table, _Mat)
        if not _Mat then _Mat = "vgui/white" end
        for _, Index in pairs(_table) do
            model:SetSubMaterial(Index - 1, _Mat)
        end
    end
    
    SetMat(_Hide, "vgui/white")  -- 隐藏其他材质

    if not self._RTTexture then
        self._RTTexture = GetRenderTarget("scope_rt_" .. wep:EntIndex(), 512, 512)
    end

  

    render.PushRenderTarget(self._RTTexture)
        
        render.Clear(0, 0, 0, 255)  -- 黑色背景，不透明
        render.SetAmbientLight(1, 1, 1)  -- 提高亮度
        if wep:GetAimDelta() > 0.1 then
            render.RenderView({
                origin = wep:GetOwner():GetShootPos(),
                angles = wep:GetOwner():EyeAngles() + wep:GetVisualRecoil() ,
                fov = 10,  -- 4.5 倍放大
                drawviewmodel = false,
                drawhud = false,
            })
        end
        
        -- 可选：叠加红点
        cam.Start2D()
            surface.SetDrawColor(255, 0, 0, 100)
            surface.DrawRect(256 - 4, 256 - 4, 8, 8)
        cam.End2D()
    render.PopRenderTarget()


    -- 使用无光照材质
    local rtMat = CreateMaterial("scope_rt_mat_" .. wep:EntIndex(), "UnlitGeneric", {
        ["$basetexture"] = self._RTTexture:GetName(),
        ["$translucent"] = 0,
        ["$vertexalpha"] = 0,
    })

    SetMat(_Lense, "!" .. rtMat:GetName())

end