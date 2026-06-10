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
    --self:MagazineBoneInit(weapon, model)
end

function ATTACHMENT:SetMagFollowerPoseParam(weapon, model, val)
    local ppid = model:LookupPoseParameter(self.BulletPoseParameter)
    if not ppid or ppid <= 0 then return end

    local min, max = model:GetPoseParameterRange(ppid)
    min = min or 0
    max = max or 1
    model:SetPoseParameter(ppid, math.Clamp(val, min, max))
end

local function cacheBones(model, bones)
    for _, name in pairs(bones) do
        model.cachedBones[name] = { id = model:LookupBone(name), remove = false }
    end
end

function ATTACHMENT:MagazineBoneInit(weapon, model)
    if model._mag_inited then return end
    model._mag_inited = true

    model._requestedReset = false
    model._clip = -1
    model._lastClip = -1
    model._ammo = -1
    model._lastAmmo = -1
    model.BulletList = table.Copy(self.BulletList)
    model.ReserveBulletList = table.Copy(self.ReserveBulletList)
    model:SetupBones()
    model.cachedBones = {}

    for _, bones in pairs(model.BulletList) do
        cacheBones(model, bones)
    end

    for _, bones in pairs(model.ReserveBulletList) do
        cacheBones(model, bones)
    end

    model.magzineCallback = model:AddCallback("BuildBonePositions", function(ent, numbones)

    end)
end
