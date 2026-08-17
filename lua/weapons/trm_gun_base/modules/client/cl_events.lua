if not CLIENT then return end
require("trm_utils")
local tracerName = "Tracer"
local Tracerscale = 10000
local tracerStart
local utilf = util.Effect


net.Receive("TRMBase_TracerEffect", function(len)
    local weapon = net.ReadEntity()
    local startPos = net.ReadVector()
    local endPos = net.ReadVector()
    if IsValid(weapon) then
        weapon:DoTracer(startPos, endPos)
    end
end)


function SWEP:MuzzleEffects()
    local ent = self:IsFirstPerson() and self:GetViewModel() or self
    self:DoMuzzleFlash(ent)
end

function SWEP:DoShell()
    local stats = self.Effects.Shell
    local ent, Id = self:FindAttachment(self:IsFirstPerson() and self:GetViewModel() or self, stats.attachment)
    local attachment = self:GetAttachmentData(stats.attachment)
    if not attachment then return end
    local effect = EffectData()


    effect:SetEntity(ent)
    effect:SetOrigin(attachment.Pos)
    effect:SetAngles(attachment.Ang)
    effect:SetScale(stats.Scale or 1)
    local owner = self:GetOwner()

    while (IsValid(owner) && ! owner:IsPlayer()) do
        owner = owner:GetOwner()
    end

    if (IsValid(owner)) then
        effect:SetNormal(owner:GetVelocity():GetNormalized())
        effect:SetMagnitude(owner:GetVelocity():Length())
            
    end

    utilf(stats.effect, effect)
end

 
function SWEP:IsFirstPerson()
    local owner = self:GetOwner()
    local localPly = LocalPlayer()
    local last = (owner == localPly and not localPly:ShouldDrawLocalPlayer())


    return last
end

function SWEP:DoMuzzleFlash(ent)
    local _ent, attId = self:FindAttachment(ent, self.Effects.Muzzle.attachment)

    

    local pcf = CreateParticleSystem(_ent,
        self.Slienced and self.Effects.Muzzle.ParticleSuppressed or self.Effects.Muzzle.ParticleEffect,
        PATTACH_POINT_FOLLOW, attId)
    if IsValid(pcf) then
        pcf:StartEmission()
    end

end


function SWEP:DoTracer(startpos, endpos)
    if self:IsFirstPerson() then
        
        local att = self:GetAttachmentData(self.Effects.Muzzle.attachment)
        startpos = att and att.Pos or startpos 
    end
    
    local stats = self.Effects.Muzzle.Tracer
    
    util.ParticleTracerEx(  stats.Name or "trm_tracer", startpos, endpos, true ,self:EntIndex() , -1 )
end

local function findAttachmentInChildren(ent, attName, weapon)
    local attId = trm_utils.LookupAttachmentCached(ent, attName)

    for _, child in pairs(ent:GetChildren()) do
        if ! child:GetClass() == "class C_BaseFlex" then
            continue
        end

        if child:GetOwner() != weapon then
            continue
        end

        if weapon.m_TPIKModelCreated and table.HasValue(weapon.m_TPIKModelCreated, child) then
            continue
        end

        local child_ent, child_att = findAttachmentInChildren(child, attName)

        if (child_att != nil) then
            attId = child_att
            ent = child_ent
        end 
    end

    return ent, attId
end

function SWEP:FindAttachment(owner, attName)
    return findAttachmentInChildren(owner, attName, self)
end

