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
local VMMatrix =    Matrix()
function SWEP:DoLHIK()
    local vm = self:GetViewModel()
    if vm == nil then return end
    


    local lhik = self:GetForegrip()
    local lhik_model = lhik and lhik.Viewmodel or nil 
    delta = math.Approach(delta, self:GetGrip1()  and 1 or 0, engine.TickInterval() )

 

    if (lhik_model != nil) then
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
            debugoverlay.Axis(vm_pos, vm_ang, 1, 0.1, true)
            debugoverlay.Axis(lhik_pos, lhik_ang, 1, 0.1, true)
            
            vm:SetBoneMatrix(vmbone, VMMatrix)
        end
    end
end

local function GetAnimation(tab)
    local  count = #tab
    local index = 1 
    if count > 1 then
        index = math.Round(math.random(1, count),0)
    end
    --print(tab[index])
    return tab[index]
end

function SWEP:PlayIKAnimation(seqClass,useInternal)
    local ik  = self:GetForegrip()
    if ik == nil then return end
    local model , attData = ik[1] , ik[2]
    if not IsValid(model) then return end
    local animation = attData.Animations or nil
    if animation == nil then return end
    local animData = animation[seqClass]
    if (animData == nil ) then
        return
    end

    model:SetCycle(0)
    model:SetPlaybackRate(animData.Speed or 1)

    model:ResetSequence("reload")
    --print("1")
end

net.Receive("TRMBase_LHIKAnimation", function(len)
    local seqClass = net.ReadString()
    local useInternal = net.ReadBool()
    local ent = net.ReadEntity()
    ent:PlayIKAnimation(seqClass,useInternal)
end)