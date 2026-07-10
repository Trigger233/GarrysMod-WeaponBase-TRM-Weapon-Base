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

function SWEP:PlayAnimation(sequenceClass, useInternalDuration,forceoverride)
    if not (IsFirstTimePredicted() and SERVER) then return end
    if self:GetNextAnimationTime() > CurTime()  then return end
    local vm = self:GetViewModel()

    self:PlayWorldAnimation(sequenceClass)
    --print("Playing animation: Customize")
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

function SWEP:PlayWorldAnimation(sequenceClass)
    if not SERVER then return end -- 只在服务端执行，让所有玩家看到
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- 映射表：第一人称动画 → 第三人称动画（ACT）
    local animationTable = {
        -- 攻击类
        ["Fire"] = PLAYER_ATTACK1,
        ["Fire_Last"] = PLAYER_ATTACK1,
        ["Iron_Fire"] = PLAYER_ATTACK1,
        ["Iron_Fire_Last"] = PLAYER_ATTACK1,

        ["Rechamber"] = PLAYER_ATTACK1,
        ["Iron_Rechamber"] = PLAYER_ATTACK1,
        -- 换弹类
        ["Reload"] = PLAYER_RELOAD,
        ["Reload_Empty"] = PLAYER_RELOAD,
        ["Reload_Start"] = PLAYER_RELOAD,
        ["Reload_End"] = PLAYER_ATTACK1,

        -- 武器操作
        ["Draw"] = PLAYER_DEPLOY,
        ["Holster"] = PLAYER_HOLSTER,

        -- 待机
        ["Idle"] = PLAYER_IDLE,
        ["Idle_Empty"] = PLAYER_IDLE,
        ["Iron_Idle"] = PLAYER_IDLE,
        ["Iron_Idle_Empty"] = PLAYER_IDLE,

        -- 冲刺
        ["Sprint"] = PLAYER_RUN,
        ["Sprint_Empty"] = PLAYER_RUN,
        ["Sprint_In"] = PLAYER_RUN,
        ["Sprint_Out"] = PLAYER_RUN,

        -- 检视
        ["Inspect"] = PLAYER_IDLE,
        ["Inspect_Empty"] = PLAYER_IDLE,
        ["Melee"] = PLAYER_ATTACK1,
        ["Melee_Empty"] = PLAYER_ATTACK1,

    }


    local act = animationTable[sequenceClass]
    if act then
        owner:SetAnimation(act)
    end
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
    local aim = self:GetAimDelta() > 0.5 and true or false
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

if (SERVER) then
    util.AddNetworkString("TRMBase_LHIKAnimation")

    function SWEP:PlayIKAnimation(seq, duration)
        net.Start("TRMBase_LHIKAnimation")
        net.WriteString(seq)
        net.WriteBool(duration or false)
        net.WriteEntity(self)
        net.Broadcast()
    end
end
