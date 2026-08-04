ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_magazine"
ATTACHMENT.BulletList = {}        -- 一维数组：{"bullet_01", "bullet_02", "bullet_03"}
ATTACHMENT.ReserveBulletList = {} -- 同样一维数组
ATTACHMENT.BulletPoseParameter = "bullets_offset"

local small = Vector(0, 0, 0)
local normal = Vector(1, 1, 1)

function ATTACHMENT:Render(weapon, model)
    BASE_TRM_ATTS[self.Base]:Render(weapon, model)

    if not weapon:IsCarriedByLocalPlayer() then return end


    if not weapon:IsReloading() then
        model._clip = weapon:Clip1()
        model._ammo = weapon:Ammo1()
        self:SetMagFollowerPoseParam(weapon, model, weapon:GetMaxClip1() - weapon:Clip1())
    end
end

function ATTACHMENT:SetMagFollowerPoseParam(weapon, model, val)
    local ppid = model:LookupPoseParameter(self.BulletPoseParameter)
    if not ppid or ppid <= 0 then return end

    local min, max = model:GetPoseParameterRange(ppid)
    min = min or 0
    max = max or 1
    model:SetPoseParameter(ppid, math.Clamp(val, min, max))
end

function ATTACHMENT:ResetBullets(weapon, model)
    model._MagazineRequestedReset = true
    self:SetMagFollowerPoseParam(weapon, model, weapon:GetMaxClip1() - (weapon:Clip1() + weapon:Ammo1()))
end

local small = Vector()
local normal = Vector(1, 1, 1)

local function cacheBones(model, bones)
    for _, name in pairs(bones) do
        model.cachedBones[name] = { id = model:LookupBone(name), remove = false }
    end
end

local function scaleBones(ent, bones, bRemove)
    for i, bone in pairs(bones) do
        ent.cachedBones[bone].remove = bRemove
    end
end

function ATTACHMENT:Init(weapon, model)
    if (table.IsEmpty(self.BulletList) && table.IsEmpty(self.ReserveBulletList)) then
        return
    end

    model._clip = -1
    model._lastclip = -1
    model.BulletList = table.Copy(self.BulletList)

    model:SetupBones()
    model.cachedBones = {}

    for _, bones in pairs(model.BulletList) do
        cacheBones(model, bones)
    end

    model:AddCallback("BuildBonePositions", function(ent, numbones)
        if (ent._lastClip != ent._clip) then
            for i, bones in pairs(ent.BulletList) do
                scaleBones(ent, bones, ent._clip <= i)
            end

            ent._lastClip = ent._clip
        end



        if (weapon._MagazineRequestedReset) then
            for i, bones in pairs(ent.BulletList) do
                scaleBones(ent, bones, weapon:Clip1() + weapon:Ammo1() < i)
            end

            weapon._MagazineRequestedReset = false
        end

        for name, boneStuff in pairs(ent.cachedBones) do
            if (! boneStuff.remove or !boneStuff.id) then
                continue
            end

            local mat = ent:GetBoneMatrix(boneStuff.id)

            if !mat then
                continue
            end

            mat:SetScale(small)
            ent:SetBoneMatrix(boneStuff.id, mat)
        end
    end)
end
