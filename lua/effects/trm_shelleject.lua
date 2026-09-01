function EFFECT:Init(data)
    self.m_NextKill = CurTime() + 1
    local wpn = data:GetEntity()
    self:SetOwner(wpn)
    self:SetModel(wpn.Effects.Shell.Model or Model("models/weapons/rifleshell.mdl"))
    self:SetAngles(data:GetAngles())
    self:SetModelScale(1)

    local pos = data:GetOrigin()

    self:SetPos(pos)
    -- debugoverlay.Sphere(pos, 5, 1, color_white, true)
    self.m_Velocity = self:GetAngles():Forward()
    self.m_Velocity:Mul(wpn.Effects.Shell.Magnitude * 10 * math.Rand(0.9, 1.3))
    self.m_Velocity:Add(data:GetNormal() * data:GetMagnitude())
    self.m_AngularVelocity = AngleRand()
    ---
    self.m_Sound = false
    self.m_LastPos = pos
    self.m_NextPos = pos
    --
    self.m_TimeStep = self:GetDeltaTime()
    --self:GetOwner().m_Shells[self] = true
end

function EFFECT:GetDeltaTime()
    return 0.1
end

function EFFECT:OnImpact(tr)
    self.m_Velocity:Add(tr.HitNormal * (self.m_Velocity:Length() * 1.15))
    self:DoImpactSound(tr)

    if (tr.MatType == "Water") then
        local data = EffectData()
        data:SetOrigin(self:GetPos())
        data:SetScale(1)
        util.Effect("waterripple", data)
    end
end

sound.Add({
    name = "TRMBase.Shell.Impact",
    sound = {
        "trmbase/shells/ShellBounce_L_Metal_Concrete_01.wav",
        "trmbase/shells/ShellBounce_L_Metal_Concrete_02.wav",
        "trmbase/shells/ShellBounce_L_Metal_Concrete_03.wav",
        "trmbase/shells/ShellBounce_L_Metal_Concrete_04.wav",
        "trmbase/shells/ShellBounce_L_Metal_Concrete_05.wav",
        "trmbase/shells/ShellBounce_L_Metal_Concrete_06.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 100,
})
sound.Add({
    name = "TRMBase.Shell.ImpactPoly",
    sound = {
        "trmbase/shells/ShellBounce_L_Poly_Concrete_01.wav",
        "trmbase/shells/ShellBounce_L_Poly_Concrete_02.wav",
        "trmbase/shells/ShellBounce_L_Poly_Concrete_03.wav",
        "trmbase/shells/ShellBounce_L_Poly_Concrete_04.wav",
        "trmbase/shells/ShellBounce_L_Poly_Concrete_05.wav",
        "trmbase/shells/ShellBounce_L_Poly_Concrete_06.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 100,
})
sound.Add({
    name = "TRMBase.Shell.ImpactWater",
    sound = { "trmbase/shells/ShellBounce_S_Water_01.wav",
        "trmbase/shells/ShellBounce_S_Water_02.wav",
        "trmbase/shells/ShellBounce_S_Water_03.wav",
        "trmbase/shells/ShellBounce_S_Water_04.wav",
        "trmbase/shells/ShellBounce_S_Water_05.wav",
        "trmbase/shells/ShellBounce_S_Water_06.wav",

        "trmbase/shells/ShellBounce_S_Water_07.wav",
        "trmbase/shells/ShellBounce_S_Water_08.wav",
        "trmbase/shells/ShellBounce_S_Water_09.wav",
        "trmbase/shells/ShellBounce_S_Water_10.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 100,
})
sound.Add({
    name = "TRMBase.Shell.Impact45ACP",
    sound = {
        "trmbase/shells/ShellBounce_S_45ACP_Concrete_01.wav",
        "trmbase/shells/ShellBounce_S_45ACP_Concrete_02.wav",
        "trmbase/shells/ShellBounce_S_45ACP_Concrete_03.wav",
        "trmbase/shells/ShellBounce_S_45ACP_Concrete_12.wav",
        "trmbase/shells/ShellBounce_Sl_45ACP_Concrete_04.wav",
        "trmbase/shells/ShellBounce_Sl_45ACP_Concrete_05.wav",
        "trmbase/shells/ShellBounce_Sl_45ACP_Concrete_06.wav",
        "trmbase/shells/ShellBounce_Sl_45ACP_Concrete_07.wav",
        "trmbase/shells/ShellBounce_Sl_45ACP_Concrete_08.wav",
        "trmbase/shells/ShellBounce_Sl_45ACP_Concrete_09.wav",
        "trmbase/shells/ShellBounce_Sl_45ACP_Concrete_10.wav",
        "trmbase/shells/ShellBounce_Sl_45ACP_Concrete_11.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 100,
})
-------------------------------
EFFECT.Sounds = {
    Default = "TRMBase.Shell.Impact",
    Water = "TRMBase.Shell.ImpactWater"
}
-----------------------------
function EFFECT:DoImpactSound(tr)
    if self.m_Sound then return end
    self.m_Sound = true
    self:EmitSound(self.Sounds[tr.MatType] || self.Sounds.Default)
end

function EFFECT:Think()
    --------
    while (self.m_TimeStep >= self:GetDeltaTime()) do
        self.m_Velocity:SetUnpacked(self.m_Velocity.x, self.m_Velocity.y,
            self.m_Velocity.z - (400 * self:GetDeltaTime()))
        --

        local tr = util.TraceLine({
            start = self.m_LastPos,
            endpos = self.m_NextPos + (self.m_Velocity * self:GetDeltaTime()),
            mask = MASK_BLOCKLOS,
            filter = self:GetOwner(),
        })


        if (bit.band(util.PointContents(tr.HitPos), CONTENTS_WATER) == CONTENTS_WATER) then
            tr.MatType = "Water"
            self:OnImpact(tr)
            return false
        end

        if (tr.Hit) then
            self:OnImpact(tr)
        end

        self.m_LastPos = self.m_NextPos
        self.m_NextPos = tr.HitPos
        --
        self.m_TimeStep = self.m_TimeStep - self:GetDeltaTime()
    end
    self.m_TimeStep = self.m_TimeStep + FrameTime()
    --------
    local delta = self.m_TimeStep / self:GetDeltaTime()

    self:SetPos(LerpVector(delta, self.m_LastPos, self.m_NextPos))
    local ang = self:GetAngles()
    self:SetAngles(LerpAngle(delta, ang, ang + self.m_AngularVelocity))
    return CurTime() < self.m_NextKill
end
