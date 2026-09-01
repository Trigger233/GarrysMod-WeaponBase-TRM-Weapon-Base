if ! CLIENT then
    return
end
local uf = util.Effect
function SWEP:DoDropMagzineEffect()
    local owner = self:GetOwner()
    if ! IsValid(owner) then return end
    if !self.Effects.Mag then return end
    local mag = EffectData()
    mag:SetEntity(self)
    mag:SetOrigin(self:GetPos())
    mag:SetAngles(self:GetAngles())
    mag:SetScale(1)

    mag:SetNormal(owner:GetVelocity():GetNormalized())
    mag:SetMagnitude(owner:GetVelocity():Length())

    mag:SetFlags(self.Effects.Mag.Flag or 0)

    uf("trm_magdrop_effect", mag)
end
