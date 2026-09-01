sound.Add({
    name = "TRMBase.MagDrop.MetalL",
    sound = {
        "trmbase/magdrop/MagDrop_L_Metal_Concrete_01.wav",
        "trmbase/magdrop/MagDrop_L_Metal_Concrete_02.wav",
        "trmbase/magdrop/MagDrop_L_Metal_Concrete_03.wav",
        "trmbase/magdrop/MagDrop_L_Metal_Concrete_04.wav",
        "trmbase/magdrop/MagDrop_L_Metal_Concrete_05.wav",
        "trmbase/magdrop/MagDrop_L_Metal_Concrete_06.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 600,
})
sound.Add({
    name = "TRMBase.MagDrop.Drum",
    sound = {
        "trmbase/magdrop/MagDrop_Drum_Concrete_01.wav",
        "trmbase/magdrop/MagDrop_Drum_Concrete_02.wav",
        "trmbase/magdrop/MagDrop_Drum_Concrete_03.wav",
        "trmbase/magdrop/MagDrop_Drum_Concrete_04.wav",
        "trmbase/magdrop/MagDrop_Drum_Concrete_05.wav",
        "trmbase/magdrop/MagDrop_Drum_Concrete_06.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 600,
})
sound.Add({
    name = "TRMBase.MagDrop.PolyL",
    sound = {
        "trmbase/magdrop/MagDrop_L_Poly_Concrete_01.wav",
        "trmbase/magdrop/MagDrop_L_Poly_Concrete_02.wav",
        "trmbase/magdrop/MagDrop_L_Poly_Concrete_03.wav",
        "trmbase/magdrop/MagDrop_L_Poly_Concrete_04.wav",
        "trmbase/magdrop/MagDrop_L_Poly_Concrete_05.wav",
        "trmbase/magdrop/MagDrop_L_Poly_Concrete_06.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 600,
})
sound.Add({
    name = "TRMBase.MagDrop.Pipe",
    sound = {
        "trmbase/magdrop/MagDrop_Pipe_Concrete_01.wav",
        "trmbase/magdrop/MagDrop_Pipe_Concrete_02.wav",
        "trmbase/magdrop/MagDrop_Pipe_Concrete_03.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 600,
})

sound.Add({
    name = "TRMBase.MagDrop.MetalS",
    sound = {
        "trmbase/magdrop/MagDrop_S_Metal_Concrete_01.wav",
        "trmbase/magdrop/MagDrop_S_Metal_Concrete_02.wav",
        "trmbase/magdrop/MagDrop_S_Metal_Concrete_03.wav",
        "trmbase/magdrop/MagDrop_S_Metal_Concrete_04.wav",
        "trmbase/magdrop/MagDrop_S_Metal_Concrete_05.wav",
        "trmbase/magdrop/MagDrop_S_Metal_Concrete_06.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 600,
})

sound.Add({
    name = "TRMBase.MagDrop.PolyS",
    sound = {
        "trmbase/magdrop/MagDrop_S_Poly_Concrete_01.wav",
        "trmbase/magdrop/MagDrop_S_Poly_Concrete_02.wav",
        "trmbase/magdrop/MagDrop_S_Poly_Concrete_03.wav",
        "trmbase/magdrop/MagDrop_S_Poly_Concrete_04.wav",
        "trmbase/magdrop/MagDrop_S_Poly_Concrete_05.wav",
        "trmbase/magdrop/MagDrop_S_Poly_Concrete_06.wav",
    },
    channel = CHAN_MAGAZINEDROP,
    level = 600,
})


--AddSound
EFFECT.Sounds = {
    Default = Sound("TRMBase.MagDrop.MetalL"),
    Poly = Sound("TRMBase.MagDrop.Poly"),
    Drum = Sound("TRMBase.MagDrop.Drum"),
    MetalSmall = Sound("TRMBase.MagDrop.MetalS"),
    PolySmall = Sound("TRMBase.MagDrop.PolyS"),
}
function EFFECT:Init(data)
    self.m_NextKill = CurTime() + 10
    local wpn = data:GetEntity()
    self:SetOwner(wpn)
    self:SetModel(wpn.Effects.Mag and wpn.Effects.Mag.Model or Model("models/Items/combine_rifle_cartridge01.mdl"))
    self:SetAngles(data:GetAngles())
    self:SetModelScale(1)

    local pos = data:GetOrigin()


    self:SetPos(pos)
    -- debugoverlay.Sphere(pos, 5, 1, color_white, true)
    self.m_Velocity = self:GetAngles():Forward()
    self.m_Velocity:Mul(10 * math.Rand(0.9, 1.3))
    self.m_Velocity:Add(data:GetNormal() * data:GetMagnitude())

    ---
    self.m_Impacted = false
    self.m_Sound = false
    self.m_LastPos = pos
    self.m_NextPos = pos
    --
    self.m_TimeStep = self:GetDeltaTime()
    --
    local flag = data:GetFlags()

    if flag == 1 then
        self.Sounds.Default = self.Sounds.Drum
    elseif flag == 2 then
        self.Sounds.Default = self.Sounds.Poly
    elseif flag == 3 then
        self.Sounds.Default = self.Sounds.MetalSmall
    elseif flag == 4 then
        self.Sounds.Default = self.Sounds.PolySmall
    end
end

function EFFECT:GetDeltaTime()
    return 0.1
end

function EFFECT:OnImpact(tr)
    
    self.m_Velocity:Zero()
    self:DoImpactSound(tr)
    if ! self.m_Impacted then
        local ang = self:GetAngles()
        ang.r = 90
        self:SetAngles(ang)
        self.m_Impacted = true
    end
    if (tr.MatType == "Water") then
        local data = EffectData()
        data:SetOrigin(self:GetPos())
        data:SetScale(1)
        util.Effect("waterripple", data)
    end
end

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
            self.m_Velocity = self.m_Velocity * 0.2
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

    return CurTime() < self.m_NextKill
end
