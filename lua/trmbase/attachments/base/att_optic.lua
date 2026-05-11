ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_reticle"
ATTACHMENT.Description = "The Base for Weapon"

function ATTACHMENT:Render(wep , model)
    BASE_TRM_ATTS[self.Base]:Render(wep ,model)
    
    self:RenderScope(wep , model )
end



function ATTACHMENT:RenderScope(wep, model)
    local _Hide = {2,3,5}
    local _Lense = {4}

    local function SetMat(_table , _Mat )
        if not _Mat then _Mat = "vgui/white" end
        for _ , Index in pairs(_table) do
            model:SetSubMaterial(Index - 1 , _Mat )
        end

    end
    
    SetMat(_Hide)

    if not self._RTTexture then
        self._RTTexture = GetRenderTarget("scope_rt",256,256)
    end

    render.PushRenderTarget(self._RTTexture)
    cam.Start2D()
        surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( 0, 0, 256, 256 )
    cam.End2D()
    render.RenderView({ drawviewmodel = false , fov = 40 })
    render.PopRenderTarget()

    local _RTMaterial = CreateMaterial( "example_rt_mat", "UnlitGeneric", {
	["$basetexture"] = self._RTTexture:GetName(), 
	--["$translucent"] = 1,
	["$vertexcolor"] = 1} )

    SetMat(_Lense , "!".."example_rt_mat" )


end