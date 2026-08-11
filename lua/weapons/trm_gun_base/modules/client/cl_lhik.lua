if not CLIENT then
    return
end
local LHIKBones = {
    --"ValveBiped.Bip01_L_UpperArm",
    "ValveBiped.Bip01_L_Forearm",
    "ValveBiped.Bip01_L_Wrist",
    "ValveBiped.Bip01_L_Ulna",
    "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_L_Finger4",
    "ValveBiped.Bip01_L_Finger41",
    "ValveBiped.Bip01_L_Finger42",
    "ValveBiped.Bip01_L_Finger3",
    "ValveBiped.Bip01_L_Finger31",
    "ValveBiped.Bip01_L_Finger32",
    "ValveBiped.Bip01_L_Finger2",
    "ValveBiped.Bip01_L_Finger21",
    "ValveBiped.Bip01_L_Finger22",
    "ValveBiped.Bip01_L_Finger1",
    "ValveBiped.Bip01_L_Finger11",
    "ValveBiped.Bip01_L_Finger12",
    "ValveBiped.Bip01_L_Finger0",
    "ValveBiped.Bip01_L_Finger01",
    "ValveBiped.Bip01_L_Finger02"
}
--LHIK form Arccw

function SWEP:GetForegrip()
    return self.m_Foregrip or nil
end

local delta = 0
local VMMatrix = Matrix()
require("trm_utils")

function SWEP:DoLHIK()
    local vm = self:GetViewModel()
    if vm == nil then return end

    self:CycleLHIKAnimation()

    local lhik = self:GetForegrip()
    local lhik_model = lhik and lhik.Viewmodel or nil
    delta = math.Approach(delta, self:GetGrip1() and 1 or 0, RealFrameTime() * 10)



    if (lhik_model != nil and IsValid(lhik_model)) then
        vm:SetupBones()
        lhik_model:SetupBones()


        for _, bone in pairs(LHIKBones) do
            local vmbone = vm:LookupBone(bone)
            local lhikbone = lhik_model:LookupBone(bone)
            if ! vmbone then continue end
            if ! lhikbone then continue end

            local vmtransform = vm:GetBoneMatrix(vmbone)
            local lhiktransform = lhik_model:GetBoneMatrix(lhikbone)

            if ! vmtransform then continue end
            if ! lhiktransform then continue end

            local vm_pos = vmtransform:GetTranslation()
            local vm_ang = vmtransform:GetAngles()
            local lhik_pos = lhiktransform:GetTranslation()
            local lhik_ang = lhiktransform:GetAngles()


            VMMatrix:SetTranslation(LerpVector(delta, vm_pos, lhik_pos))
            VMMatrix:SetAngles(LerpAngle(delta, vm_ang, lhik_ang))
            -- debugoverlay.Axis(vm_pos, vm_ang, 1, 0.1, true)
            -- debugoverlay.Axis(lhik_pos, lhik_ang, 1, 0.1, true)

            vm:SetBoneMatrix(vmbone, VMMatrix)
        end
    end
end

local function GetAnimation(tab)
    local count = #tab
    local index = 1
    if count > 1 then
        index = math.Round(math.random(1, count), 0)
    end
    --print(tab[index])
    return tab[index]
end


function SWEP:PlayIKAnimation(seqClass, useInternal)
    if CurTime() < self:GetNextAnimationTime() then return end
    local ik = self:GetForegrip()
    if ik == nil then return end
    local model, attData = ik.Viewmodel, ik.Data
    if not IsValid(model) then return end
    local animation = model.Animations or nil
    if animation == nil then return end
    local animData = animation[seqClass]
    if (animData == nil) then
        return
    end
    local sequence = GetAnimation(animData.sequence)

    model:ResetSequence(sequence)
    model:SetCycle(0)
    model:SetPlaybackRate(animData.Speed or 1)
    local SequenceDuration = model:SequenceDuration(model:GetSequence())
    self.m_IKSeqClass = seqClass

    if model.Animations[seqClass].events then
        for _, event in ipairs(model.Animations[seqClass].events) do
            event.Triggered = false
        end
    end
    if useInternal then
        net.Start("TRMBase_LHIKAnimation")
        net.WriteEntity(self)
        net.WriteFloat(CurTime() + (SequenceDuration / (animData.Speed or 1)))
        net.SendToServer()
    end
end

function SWEP:CycleLHIKAnimation()
    local tbl = self:GetForegrip()
    if not tbl then return end
    local model, attData = tbl.Viewmodel, tbl.Data
    if not IsValid(model) then
        return
    end
    local cycle = model:GetCycle()
    local SequenceDuration = model:SequenceDuration(model:GetSequence())
    local Speed = model:GetPlaybackRate()
    local seqClass = self.m_IKSeqClass
    if model.Animations and model.Animations[seqClass] and model.Animations[seqClass].events then
        for Index, event in ipairs(model.Animations[seqClass].events) do
            if event.Triggered then
                continue
            end
            if cycle >= event.time and not event.Triggered and event.callback then
                net.Start("TRMBase_LHIKEvents")
                net.WriteEntity(self)
                net.WriteString(tbl.Data.ClassName)
                net.WriteString(seqClass)
                net.WriteInt(Index, 8)
                net.SendToServer()
                event.Triggered = true
            end
        end
    end


    model:SetCycle(cycle + FrameTime() / (SequenceDuration / Speed))
end

net.Receive("TRMBase_LHIKAnimation", function(len)
    local seqClass = net.ReadString()
    local useInternal = net.ReadBool()
    local ent = net.ReadEntity()
    timer.Simple(0.2, function()
        if IsValid(ent) then
            ent:PlayIKAnimation(seqClass, useInternal)
        end
    end)
end)


hook.Add("VManipPrePlayAnim", "TRM_VManipStopActions", function()
    local ply = LocalPlayer()
    local w = ply:GetActiveWeapon()

    if ! util.IsTRMBase(w) then return end

    local seqClass = w:GetPlayingSequence()
    if string.find(seqClass, "Reload") then
        return true
    end
end)

function SWEP:GetCameraControler()
    if !self:GetUnderbarrel() then return end
    local ik = self:GetForegrip()
    if !ik then return  end
    local anim_mdl , attData = ik.Viewmodel ,ik.Data
    if !IsValid(anim_mdl) then return end

    local attId = anim_mdl:LookupAttachment( "Camera")
    if attId == -1 or !attId then
        return
    end
    local ang = (anim_mdl:GetAttachment(attId)  or {}).Ang
    if !ang then return end
    ang.r = ang.r - 90

    return anim_mdl:WorldToLocalAngles(ang)
end

local BodyMatrix = Matrix()
