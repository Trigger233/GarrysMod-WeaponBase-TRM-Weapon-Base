local tracerName = "Tracer"
local Tracerscale = 5000
local tracerStart
function SWEP:DoTracer(startpos,endpos)
    if not CLIENT then return end
    if self.Slienced or not self.Effects.Muzzle.Tracer then return end
    tracerStart = self:GetMuzzlePos() or startpos
    tracerName = self.Effects.Muzzle.Tracer.Name or tracerName
    local owner = self:GetOwner()
    local effect = EffectData()

    effect:SetStart(tracerStart) 
    effect:SetOrigin(endpos)
    effect:SetScale(Tracerscale)
    util.Effect(tracerName, effect )
end

net.Receive("TRMBase_TracerEffect", function(len)
    local weapon = net.ReadEntity()
    local startPos = net.ReadVector()
    local endPos = net.ReadVector()
    if IsValid(weapon ) then
        weapon:DoTracer(startPos,endPos)
    end
end)



function SWEP:GetMuzzlePos() 
    local muzzle = self:GetAttachmentData(self.Effects.Muzzle.attachment)
    if not muzzle then
        muzzle = self:GetWorldAttachmentData()
    end
    -- if not muzzle then
    --     return false
    -- end
    return muzzle.Pos or false
end
