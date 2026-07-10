ATTACHMENT.Base = "att_scope"
ATTACHMENT.Name = "att_hybrid"
ATTACHMENT.Description = "The Base for Hybrid Optics"
ATTACHMENT.Selectable = false

local bodygroup_cache = {}

local function ApplyBodyGroup(model, name, value)
    if not IsValid(model) then return end

    bodygroup_cache[model] = bodygroup_cache[model] or {}

    if bodygroup_cache[model][name] == nil then
        bodygroup_cache[model][name] = model:FindBodygroupByName(name)
    end

    local id = bodygroup_cache[model][name]
    if id and id >= 0 then
        model:SetBodygroup(id, value)
    end
end

local pose = 0
function ATTACHMENT:Render(wep, model)
    if not IsValid(model) then return end

    local hybridOn = wep:HasFlag("HybridOn") or false
    local hybridData = self.HybridSight

    -- 1. 切换身体组（切换镜体）
    if hybridData and hybridData.Bodygroup then
        ApplyBodyGroup(model, hybridData.Bodygroup, hybridOn and 1 or 0)
    end

    if hybridData and hybridData.PoseParameter then
        self:SetHybridPoseParam(wep, model)
    end
    


    if wep:IsCarriedByLocalPlayer() then
        wep:RenderScopeSight(model, self)
    end

    -- 2. 渲染瞄准镜
    -- 红点模式：渲染红点准星
    self:RenderReticle(wep, model, self.Sight)

    -- 3. 绘制模型
end

function ATTACHMENT:Remove(weapon, model)
    -- 清理缓存
    if IsValid(model) then
        bodygroup_cache[model] = nil
    end
end

function ATTACHMENT:RTCode(weapon, size)
    -- 倍镜的 PiP 渲染代码（由 att_scope 处理）
end

function ATTACHMENT:SetHybridPoseParam(weapon,model)
    if !self.HybridSight.PoseParameter then
        return 
    end

    local target =  weapon:HasFlag("HybridOn") and 1 or 0
    pose = math.Approach(pose, target, RealFrameTime() * (self.HybridSight.SmoothPose or 2) )
    local ppid = model:LookupPoseParameter(self.HybridSight.PoseParameter)
    local min , max = model:GetPoseParameterRange(ppid)
    model:SetPoseParameter(ppid,pose)
end
