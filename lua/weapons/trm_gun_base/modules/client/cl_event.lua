if not CLIENT then return end

function SWEP:ShootEffects()
	if SERVER then return end
	local ejectDelay = self.m_EjectDelay or 0

	local vm = self:GetOwner():ShouldDrawLocalPlayer()
    if not vm then 
        
 	    self:DoMuzzleEffect()           
        
        if self.Effects.Shell.Primary then
            self:DoShell() 
        end
    end 


end

function SWEP:DoMuzzleEffect()

    if SERVER or self.m_Slienced then return end
   
    local effect = EffectData()
    local att = self:GetAttachmentData(self.Effects.Muzzle.attachment)
    local vm = self:GetViewModel()

    effect:SetColor(255,255,255,255)
    effect:SetAttachment(   att.id  )
    effect:SetOrigin(   att.Pos )
    effect:SetAngles(   att.Ang )
    effect:SetEntity(   att.Ent ) 
    effect:SetScale(1)
    effect:SetFlags(2)

    --print(att.id)

    util.Effect(self.Effects.Muzzle.effect,effect)
end

function SWEP:DoShell()
    if SERVER then return end
    local effect = EffectData()
    local att_shell = self:GetAttachmentData(self.Effects.Shell.attachment)

    --effect:SetAttachment(att.id)
    effect:SetOrigin(att_shell.Pos + self.Effects.Shell.Pos)
    -- print(att_shell.Pos)
    -- debugoverlay.Sphere(att_shell.Pos,10,3,Color(255,255,255),true)
    effect:SetAngles(att_shell.Ang + self.Effects.Shell.Ang)
    effect:SetScale(1)
    effect:SetEntity(self)
    effect:SetFlags(0)
    effect:SetMagnitude(1)
    util.Effect(self.Effects.Shell.effect,effect)
end



