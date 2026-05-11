-- Create render target
if SERVER or true then return end
local exampleRT = GetRenderTarget( "example_rt", 256, 256 )

-- Draw to the render target
local function update()
 
    render.PushRenderTarget( exampleRT )
	cam.Start2D()
		-- Draw background
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawRect( 0, 0, 1024, 1024 )

		-- Draw some foreground stuff
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( 0, 0, 256, 256 )
	cam.End2D()

    render.RenderView({
    })
    render.PopRenderTarget()

    
end
update()

local customMaterial = CreateMaterial( "example_rt_mat", "UnlitGeneric", {
	["$basetexture"] = exampleRT:GetName(), -- You can use "example_rt" as well
	--["$translucent"] = 1,
	["$vertexcolor"] = 1
} )

hook.Add( "HUDPaint", "ExampleDraw", function()
    update()
    draw.DrawText("Test View","Default",0,0,Color(255,255,255),TEXT_ALIGN_LEFT )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( customMaterial )
	surface.DrawTexturedRect( 0, 0, customMaterial:GetTexture( "$basetexture" ):Width(), customMaterial:GetTexture( "$basetexture" ):Height() )
end )