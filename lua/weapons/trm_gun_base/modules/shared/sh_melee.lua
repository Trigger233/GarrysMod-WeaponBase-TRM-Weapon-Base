function SWEP:CanMelee()
    local seq = self:GetPlayingSequence()

    if  CurTime() > self:GetNextPrimaryFire() and self.Melee.Enabled then
        return true
    end


    if not  string.find(seq,"Melee") and self.Melee.Enabled  then
        return true
    end
    return false 
end



concommand.Add("trmbase_melee",function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base") then
        if wep:CanMelee() then
            wep:TrySetTask("Melee")
        end
    end
end)

function SWEP:DealMeleeDamage()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local startPos = owner:GetShootPos()
    local forward = owner:GetAimVector()
    local range = self.Melee.Range or 200
    local damage = self.Melee.Damage or 40
    local radius = self.Melee.Radius or 32  -- 增大判定半径
    
    local endPos = startPos + forward * range
    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        filter = owner,
        mins = Vector(-10, -5, -0),
        maxs = Vector(10, 5, 5),
       -- mask = MASK_SHOT_HULL,
    })
    
    
    local dmginfo = DamageInfo()
        dmginfo:SetDamage(damage)
        dmginfo:SetAttacker(owner)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamageForce(forward * (self.Melee.Force or 10))
        dmginfo:SetDamageType(DMG_CLUB)
    
    if not tr.Hit then return end
        self:MeleeImpactEffects(tr)
    self:MeleeDoor(tr)
    local ent = tr.Entity
    if not (game.SinglePlayer() and CLIENT ) then
        self:EmitSound(self.Melee.Sound)
    end
    if CLIENT then return end

    if IsValid(ent)  then
        if ent.TakeDamageInfo then
            ent:TakeDamageInfo(dmginfo)
        end
    end

    local phys

	if ent:IsRagdoll() then
		phys = ent:GetPhysicsObjectNum(tr.PhysicsBone or 0)
	else
		phys = ent:GetPhysicsObject()
	end

	if IsValid(phys) then
		if ent:IsPlayer() or ent:IsNPC() then
			ent:SetVelocity(owner:GetAimVector() * damage * 0.5)
			phys:SetVelocity(phys:GetVelocity() + forward * damage * 0.5)
		else
			phys:ApplyForceOffset(forward * damage * 0.5, tr.HitPos)
		end
	end
end
 
function SWEP:MeleeDoor(tr)
    if CLIENT or not IsValid(tr.Entity) then return end
    local ent =tr.Entity
    if not string.find(ent:GetClass() , "door") then return end
    ent:EmitSound("ambient/materials/door_hit1.wav", 100, math.random(80, 120))
    ent:SetKeyValue("Speed", "500")
    ent:SetKeyValue("Open Direction", "Both directions")
    ent:SetKeyValue("opendir", "0")
    ent:Fire("openawayfrom", self:GetOwner():EntIndex(), 0.1)
    ent:Fire("Open","",0.1)
    timer.Simple(0.3, function()
			if IsValid(ent) then
				ent:SetKeyValue("Speed", "100")
			end
	end)

end

function SWEP:MeleeImpactEffects(tr)

        if IsValid(tr.Entity) && tr.Entity.TakeDamageInfo then
            local bloodColor = tr.Entity:GetBloodColor()
            if bloodColor && bloodColor >= 0 then
                local blood = EffectData()
                blood:SetColor(bloodColor)
                blood:SetNormal(tr.Normal)
                blood:SetOrigin(tr.HitPos)
                blood:SetScale(1)
                util.Effect("BloodImpact", blood)
            end
        else
            local impact = EffectData()
            impact:SetOrigin(tr.HitPos)
            impact:SetStart(tr.StartPos)
            impact:SetSurfaceProp(tr.SurfaceProps)
            impact:SetEntity(tr.Entity)
            impact:SetHitBox(tr.HitBoxBone || 0)
            impact:SetDamageType(DMG_CLUB)
            util.Effect("Impact", impact)
        end

end
