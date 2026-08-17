function SWEP:BipodLogic()
    if ! self.bipod then
        if self:HasFlag("BipodDeployed") then
            self:RemoveFlag("BipodDeployed")
        end
        return
    end


    local owner = self:GetOwner()
    local bDeployed = false
    if (! self:IsOwnerMoving() and owner:OnGround()) then
        local pos = self:GetOwner():EyePos() + Angle(0, self:GetOwner():EyeAngles().y, 0):Forward() * 16

        if (! self:GetOwner():Crouching()) then
            local tr = util.TraceHull({
                start = pos,
                endpos = pos - Vector(0, 0, 32),
                mins = Vector(-16, -16, 0),
                maxs = Vector(16, 16, 2),
                filter = player.GetAll(),
                mask = MASK_PLAYERSOLID
            })

            bDeployed = tr.Hit && ! tr.StartSolid
        else
            bDeployed = true
        end
    end






    if (bDeployed) then
        self:AddFlag("BipodDeployed")
    else
        self:RemoveFlag("BipodDeployed")
    end
end

function SWEP:IsOwnerMoving()
    return self:GetOwner():KeyDown(IN_FORWARD)
        || self:GetOwner():KeyDown(IN_BACK)
        || self:GetOwner():KeyDown(IN_MOVERIGHT)
        || self:GetOwner():KeyDown(IN_MOVELEFT)
end
