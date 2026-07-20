local function isReloadSeq(seq)
    return seq and (string.find(seq, "Reload") or string.find(seq, "reload"))
end
local cvar_firebreakreload = CreateConVar("trmbase_fire_interupt_reload", 0, FCVAR_ARCHIVE)

local task_reload = {}
task_reload.Name = "Reload"
task_reload.Priority = 200

function task_reload:CanBeSet(weapon)
    return weapon:CanReload()
end

function task_reload:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    local seq = weapon:GetPlayingSequence()
    if not isReloadSeq(seq) then
        if weapon.ReloadType == "Single" then
            if weapon:Clip1() == 0 and weapon.Animations.Reload_Empty then
                weapon:PlayAnimation(weapon:ChooseAnim( "Reload_Empty"), true)
            elseif weapon.Animations.Reload_Start then
                weapon:PlayAnimation(weapon:ChooseAnim( "Reload_Start"), true)
            end

            weapon:PlayerGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, weapon.HoldTypes["BoltAction"].Reload)
        else
            weapon:PlayerGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, weapon.HoldTypes[weapon:GetCurrentHoldType()].Reload)

            weapon:PlayAnimation(weapon:ChooseAnim("Reload"), true)
            if cvar_firebreakreload:GetBool( ) then
                weapon:SetNextPrimaryFire( 60 / weapon.Primary.RPM )
            end            
        end
    end
end

function task_reload:Think(cycle, weapon)
    if weapon.ReloadType == "Single" then
            weapon:TrySetTask("ReloadLoop")
    elseif weapon:GetNextAnimationTime() > CurTime() then
            weapon:TrySetTask("Idle")
            
    end
end

SWEP:RegisterTask(task_reload)

local task_loop = {}
task_loop.Name = "ReloadLoop"
task_loop.Priority = 200

function task_loop:CanBeSet(weapon)
    return true
end

function task_loop:OnSet(weapon)

end

function task_loop:Think(cycle, weapon)
    local max = weapon:GetMaxClip1() + weapon:GetChamberAmmo()
    local reserve = weapon:GetOwner():GetAmmoCount(weapon:GetPrimaryAmmoType())
    if weapon:GetNextPrimaryFire() < UnPredictedCurTime() then
        weapon:PlayerGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, weapon.HoldTypes["BoltAction"].Reload)
    end

    if weapon:Clip1() < max and reserve > 0 then
        weapon:PlayAnimation("Reload", true)
        if cvar_firebreakreload:GetBool() then
            weapon:SetNextPrimaryFire(60 / weapon.Primary.RPM)
        end
    else
        weapon:TrySetTask("ReloadEnd")
    end
end

SWEP:RegisterTask(task_loop)

local task_end = {}
task_end.Name = "ReloadEnd"
task_end.Priority = 200

function task_end:CanBeSet(weapon)
    return true
end

function task_end:OnSet(weapon)

end

function task_end:Think(cycle, weapon)
    if weapon:GetNextPrimaryFire() <= CurTime() then
        if not string.find(weapon:GetPlayingSequence(), "Reload_End") then
            weapon:SetNextAnimationTime(0) -- Make sure
            weapon:PlayAnimation(weapon:ChooseAnim("Reload_End"), true)
        end
        weapon:TrySetTask("Idle")
    end
end

SWEP:RegisterTask(task_end)
