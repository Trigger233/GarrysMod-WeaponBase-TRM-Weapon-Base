if SERVER then return end
SWEP.vm_FastAttachment = {}
function SWEP:GetFastViewmodelAttachment(name)
    self.vm_FastAttachment = self.vm_FastAttachment or {}
    self.vm_FastAttachment[name] = self.vm_FastAttachment[name] or {}
    local Viewmodel = self:GetViewModel()
    if ! self.vm_FastAttachment[name].Matrix then
        local ent, attId = self:FindAttachment(Viewmodel, name)
        if ! IsValid(ent) or attId == -1 then return end
        local computeMatrix = Matrix()
        self.vm_FastAttachment[name].Entity = ent
        timer.Simple(0, function()
        --    ent:SetupBones()
            local attData = ent:GetAttachment(attId)
            if !attData then return end

            computeMatrix:SetTranslation(attData.Pos)
            computeMatrix:SetAngles(attData.Ang)
            self.vm_FastAttachment[name].Bone = attData.Bone
            local worldMatrix = ent:GetBoneMatrix(attData.Bone)
            computeMatrix = worldMatrix:GetInverse() * computeMatrix
            self.vm_FastAttachment[name].Matrix = computeMatrix
            PrintTable(self.vm_FastAttachment)
        end)
    end
    if ! IsValid(self.vm_FastAttachment[name].Entity) then
        self.vm_FastAttachment[name] = {}
        return
    end
    -- if ! self.vm_FastAttachment[name].Bone then
    --     self.vm_FastAttachment[name] = {}
    --     return
    -- end

    local CurrentWorldMatrix = self.vm_FastAttachment[name].Entity:GetBoneMatrix(self.vm_FastAttachment[name].Bone)
    if ! CurrentWorldMatrix then return end

    local newMatrix = CurrentWorldMatrix * self.vm_FastAttachment[name].Matrix
    local Pos = newMatrix:GetTranslation()
    local Ang = newMatrix:GetAngles()
    local newMatTable = { Pos = Pos, Ang = Ang }
    debugoverlay.Sphere(Pos, 5, 0.1, color_white, true)
    return newMatTable
end
