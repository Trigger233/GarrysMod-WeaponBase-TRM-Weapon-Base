--Deal With MWB Mat

AddCSLuaFile()

if SERVER then return end

local lastPos = Vector()
local lastValue = 0
local lerp = Lerp
matproxy.Add({
    name = "MwEnvMapTint",

    init = function(self, mat, values)
        local color = { 1, 1, 1 }

        if (values.color != nil) then
            color = string.Explode(" ", string.Replace(string.Replace(values.color, "[", ""), "]", ""))
        end

        self.min = values.min || 0
        self.max = values.max || 1
        self.color = Vector(color[1], color[2], color[3])

        if (values.envmap != "env_cubemap") then
            mat:SetTexture("$envmap", values.envmap || "viper/shared/envmaps/specularity_50")
        else
            mat:SetString("$envmap", "env_cubemap")
        end
    end,

    bind = function(self, mat, ent)
        if (! IsValid(ent)) then return end

        if (! lastPos:IsEqualTol(ent:GetPos(), 1)) then
            local c = render.GetLightColor(ent:GetPos())
            lastValue = (c.x * 0.2126) + (c.y * 0.7152) + (c.z * 0.0722)
            lastValue = math.min(lastValue * 2, 1)
            lastPos = ent:GetPos()
        end

        ent.m_MwEnvMapTint = lerp(10 * RealFrameTime(), ent.m_MwEnvMapTint || 0, lastValue)
        mat:SetVector("$envmaptint", self.color * lerp(ent.m_MwEnvMapTint, self.min, self.max))
    end
})

matproxy.Add({
    name = "MwCamo",

    init = function(self, mat, values)
    end,

    bind = function(self, mat, ent)
        --[[if (!IsValid(ent)) then return end

		mat:SetInt("$detailblendmode", 0)
		mat:SetFloat("$detailblendfactor", 0)

		if (ent.mw_Camo == nil || ent.mw_Camo == "") then return end

		mat:SetInt("$detailblendmode", 4)
		mat:SetFloat("$detailblendfactor", 1)
		mat:SetTexture("$detail",  ent.mw_Camo)]]
    end
})

matproxy.Add({
    name = "MwSight",

    init = function(self, mat, values)
    end,

    bind = function(self, mat, ent)
        if (! IsValid(ent)) then return end

        if (ent.mw_Aim == nil) then
            mat:SetInt("$cloakpassenabled", 0)
            mat:SetFloat("$cloakfactor", 0)
        else
            mat:SetInt("$cloakpassenabled", 1)
            mat:SetFloat("$cloakfactor", math.Round(ent.mw_Aim))
        end
    end
})


 --arc9
local lastPos = Vector()
local lastValue = 0

-- hyperoptimization +1000 fps
local lerp = Lerp
local ENTITY = FindMetaTable("Entity")
local entityGetPos = ENTITY.GetPos
local renderGetLightColor = render.GetLightColor
local vectorIsEqualTol = FindMetaTable("Vector").IsEqualTol
local mathmin = math.min

matproxy.Add({
    name = "Arc9EnvMapTint",

    init = function(self, mat, values)
        local color = { 1, 1, 1 }

        if (values.color != nil) then
            color = string.Explode(" ", string.Replace(string.Replace(values.color, "[", ""), "]", ""))
        end

        self.min = values.min or 0
        self.max = values.max or 1
        self.color = Vector(color[1], color[2], color[3])

        --mat:SetTexture("$envmap", values.envmap or "arc9/shared/envmaps/specularity_50")
        if (values.envmap != "env_cubemap") then
            mat:SetTexture("$envmap", values.envmap or "arc9/shared/envmaps/specularity_50")
        else
            mat:SetString("$envmap", "env_cubemap")
        end
    end,

    bind = function(self, mat, ent)
        if ! IsValid(ent) then return end
        local getpos = entityGetPos(ent)
        if ! vectorIsEqualTol(lastPos, getpos, 1) then
            local c = renderGetLightColor(getpos)
            lastValue = (c.x * 0.2126) + (c.y * 0.7152) + (c.z * 0.0722)
            lastValue = mathmin(lastValue * 2, 1)
            lastPos = getpos
        end
        ent.m_Arc9EnvMapTint = lerp(10 * RealFrameTime(), ent.m_Arc9EnvMapTint || 0, lastValue)
        if ent.PhongMultSoLowerEnvmapPls then ent.m_Arc9EnvMapTint = ent.m_Arc9EnvMapTint * 0.3 end
        mat:SetVector("$envmaptint", self.color * lerp(ent.m_Arc9EnvMapTint, self.min, self.max))
    end
})
