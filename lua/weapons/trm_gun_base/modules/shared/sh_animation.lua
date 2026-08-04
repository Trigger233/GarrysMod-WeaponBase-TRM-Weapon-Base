local function resetEvents(wep, animation)
    local anim = wep.Animations[animation]
    if not anim then return end

    if anim.events then
        for _, event in pairs(anim.events) do
            event.Triggered = false
            --print(event.time)
        end
    end
end

local function applyEvents(weapon, animation, cycle)
    local anim = weapon.Animations[animation]
    if not anim then return end
    if anim.events then
        for _, event in pairs(anim.events) do
            if not event or event.Triggered then
                continue
            end

            if cycle >= event.time then
                if event.callback then
                    event.callback(weapon)
                end
                event.Triggered = true
            end
        end
    end
end

function SWEP:GetAnimation(Class)
    return self.Animations[Class] or false
end

function SWEP:PlayAnimation(sequenceClass, useInternalDuration, forceoverride)
    if not (IsFirstTimePredicted() and SERVER) then return end
    if self:GetNextAnimationTime() > CurTime() then return end
    local vm = self:GetViewModel()

    if not vm or not IsValid(vm) or not sequenceClass then
        return
    end


    local animData = self.Animations[sequenceClass] -- 修复1：用 [] 而不是 .
    if not animData then return end

    local seq = animData.sequence -- 获取动画序列名列表
    if not seq or #seq == 0 then return end

    local sequencePlay = seq[math.Round(math.Rand(1, #seq))] -- 修复2：直接用 #seq 获取长度

    self:SetPlayingSequence(sequenceClass)


    vm:SendViewModelMatchingSequence(vm:LookupSequence(sequencePlay))

    self:SetGrip1(true)
    self:SetGrip2(true)
    local duration = vm:SequenceDuration(vm:LookupSequence(sequencePlay))

    vm:SetCycle(0)

    resetEvents(self, sequenceClass)


    local speed = (animData.Speed or 1)
    vm:SetPlaybackRate(speed)

    self:ApplySpecialAnimationStat(vm, sequenceClass, duration, animData)

    if useInternalDuration and SERVER then
        local nexttime = (animData.RealLength or duration) * (animData.Length or 1) / speed
        self:SetNextAnimationTime(CurTime() + nexttime)
        self:SetNextFireTime(nexttime)
    end
end

function SWEP:DoAnimationEvents()
    local vm = self:GetViewModel()
    if not vm or not IsValid(vm) or not IsFirstTimePredicted() then
        return
    end

    local progress = vm:GetCycle()
    local sequenceClass = self:GetPlayingSequence()

    if not sequenceClass or not self.Animations or not self.Animations[sequenceClass] or not self.Animations[sequenceClass].events then
        return
    end




    applyEvents(self, sequenceClass, progress)
end

function SWEP:ApplySpecialAnimationStat(vm, sequenceClass, duration, animData)
    if string.find(sequenceClass, "Ads") then
        local AdsSpeed = (animData.RealLength or duration) / self:GetAimTime()
        vm:SetPlaybackRate(AdsSpeed)
    end
end

function SWEP:ChooseAnim(animationClass)
    if not SERVER then return end

    local empty = self:IsEmpty()
    local aim = self:HasFlag("Aiming")
    local function hasAnim(Class)
        local anim = self.Animations
        return anim and anim[Class] and true or false
    end
    local AnimName = animationClass

    if not hasAnim(AnimName) then
        AnimName = "Idle"
    end
    if empty and hasAnim(AnimName .. "_Empty") then
        AnimName = AnimName .. "_Empty"
    end
    if aim and hasAnim("Iron_" .. AnimName) then
        AnimName = "Iron_" .. AnimName
    end

    return AnimName
end

function SWEP:IsAnimFinished()
    return self:GetNextAnimationTime() < CurTime()
end

if SERVER then
    util.AddNetworkString("trmbase_tpanim")
    util.AddNetworkString("TRMBase_LHIKAnimation")
    util.AddNetworkString("TRMBase_LHIKEvents")
    function SWEP:PlayIKAnimation(seqClass, useInternal)
        net.Start("TRMBase_LHIKAnimation")
        net.WriteString(seqClass)
        net.WriteBool(useInternal)
        net.WriteEntity(self)
        net.Broadcast()
    end

    net.Receive("TRMBase_LHIKAnimation", function(len, ply)
        local ent = net.ReadEntity()
        local time = net.ReadFloat()
        ent:SetNextAnimationTime(time)
        ent:SetNextPrimaryFire(time)
    end)

    net.Receive("TRMBase_LHIKEvents", function(len, ply)
        local weapon = net.ReadEntity()
        local attClass = net.ReadString()
        local seqClass = net.ReadString()
        local index = net.ReadInt(8)
        local AttData = BASE_TRM_ATTS[attClass]
        if AttData.Animations and AttData.Animations[seqClass] then
            local tbl = AttData.Animations[seqClass].events
            if (tbl != nil and tbl[index] != nil) then
                tbl[index].callback(weapon)
            end
        end
    end)
end

function SWEP:PlayerGesture(slot, anim)
    if (CLIENT && IsFirstTimePredicted()) then
        self:GetOwner():AnimRestartGesture(slot, anim, true)
    end

    if SERVER then
        net.Start("trmbase_tpanim", true)
        net.WriteUInt(slot, 2)
        net.WriteInt(anim, 12)
        net.WriteEntity(self:GetOwner())
        if (game.SinglePlayer()) then
            net.Send(self:GetOwner())
        else
            net.SendOmit(self:GetOwner())
        end
    end
end

if CLIENT then
    net.Receive("trmbase_tpanim", function()
        local slot = net.ReadUInt(2)
        local anim = net.ReadInt(12)
        local ply = net.ReadEntity()

        if (ply == NULL) then
            return
        end

        ply:AnimRestartGesture(slot, anim, true)
    end)
end

function SWEP:FireAnimationEvent(pos, ang, event, option, source)
    if event == 9001 or event == 6001 then
        return true
    end

    if event == 9031 then
        if option == "ResetBullets" then
            self._MagazineRequestedReset = true
        end
    end


    return false
end
