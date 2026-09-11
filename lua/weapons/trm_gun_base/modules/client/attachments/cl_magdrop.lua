if ! CLIENT then
    return
end
local uf = util.Effect
local Origin = Vector()
function SWEP:DoDropMagzineEffect()
    local owner = self:GetOwner()
    if ! IsValid(owner) then return end
    if ! self.Effects.Mag then return end
    Origin = self:GetPos()
    if self.Effects.Mag.attachment then
        Origin = self:GetAttachmentData(self.Effects.Mag.attachment).Pos or Origin
    end

    local mag = EffectData()
    mag:SetEntity(self)
    mag:SetOrigin(Origin)
    mag:SetAngles(self:GetAngles())
    mag:SetScale(1)

    mag:SetNormal(owner:GetVelocity():GetNormalized())
    mag:SetMagnitude(owner:GetVelocity():Length())

    mag:SetFlags(self.Effects.Mag.Flag or 0)

    uf("trm_magdrop_effect", mag)
end
