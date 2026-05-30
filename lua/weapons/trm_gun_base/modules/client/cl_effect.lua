if not CLIENT then return end
local tracerName = "Tracer"
local Tracerscale = 10000
local tracerStart
function SWEP:DoTracer(startpos,endpos)
    if not CLIENT then return end
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
    local vm = self:GetViewModel()
    if not IsValid(vm) then return false end
    local muzzle = self:GetAttachmentData(self.Effects.Muzzle.attachment)



    return muzzle.Pos
end
