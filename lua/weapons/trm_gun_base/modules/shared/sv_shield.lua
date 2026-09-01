if CLIENT then return end

function SWEP:CreateShield()
    self:RemoveShield()
    print("TryCreateShield" , self )
    local model = self.Shield.Model

    if ! model then return end

    local shield = ents.Create("prop_physics")

    if ! IsValid(shield) then return end
    self:DeleteOnRemove(shield)
    self.ShieldProp = shield

    local bonename = self.Shield.Bone
    local boneindex = self:GetOwner():LookupBone(bonename)
    local bpos, bang = self:GetOwner():GetBonePosition(boneindex)
    local pos = self.Shield.Offset
    local ang = self.Shield.Ang
    local newpos = Vector(pos)

    newpos.y = -newpos.y

    local apos = LocalToWorld(newpos, ang, bpos, bang)

    shield:SetModel(model)
    shield:FollowBone(self:GetOwner(), boneindex)
    shield:SetPos(apos)
    shield:SetAngles(self:GetOwner():GetAngles() + ang)
    shield:SetOwner(self:GetOwner())

    shield:SetRenderMode(RENDERMODE_TRANSCOLOR)
    shield:SetMoveType(MOVETYPE_NOCLIP)
    shield:SetSolid(SOLID_NONE)
    shield:SetCollisionGroup(COLLISION_GROUP_WORLD)

    if self.Shield.NoDraw then
        shield:SetNoDraw(true)
    end

    shield.TRMIsShield = true
    shield.TRMWeapon = self

    shield:Spawn()
    shield:SetModelScale(self.Shield.Scale or 1, 0.1)
    shield:Activate()
    self:SetShieldEntity(shield)
    self:GetOwner().TRMShieidEntity = shield
end

function SWEP:RemoveShield()
    print("Remove Entity", self.ShieldProp)
    SafeRemoveEntity(self.ShieldProp)
    SafeRemoveEntity(self:GetOwner().TRMShieidEntity)
    SafeRemoveEntity(self:GetShieldEntity())
end
