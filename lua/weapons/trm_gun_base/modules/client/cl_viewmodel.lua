if SERVER then return end

function SWEP:ShouldDrawViewModel()
    local owner = self:GetOwner()
    if owner:InVehicle() or owner:ShouldDrawLocalPlayer() then return false end
    return true
end

require("trm_utils")
function SWEP:ViewModelDrawn(vm, flag)
    if not IsValid(vm) then return end
    vm:SetupBones()
    self:BuildViewmodelAttachmentsData(vm)

    for _, att in pairs(self:GetAllAttachmentsInUse()) do
        local attData = BASE_TRM_ATTS[att.Class]

        if att.m_Model then
            if attData.Render then
                attData:Render(self, att.m_Model)
            end
        elseif not att.m_Model and attData.Model then
            self:BuildCustomizedGun()
        end
    end
end

function SWEP:BuildViewmodelAttachmentsData(vm)
    if not IsValid(vm) then return end

    self.m_Attachment = self.m_Attachment or {}
    local stats = self.Effects
    if not stats then return end

    for _, element in pairs(stats) do
        if not element or not element.attachment then
            continue
        end

        local ent, attId = self:FindAttachment(vm, element.attachment)
        if not IsValid(ent) or not attId or attId == -1 then
            -- 可选：用默认值或跳过
            self.m_Attachment[element.attachment] = false
            continue
        end

        local att = ent:GetAttachment(attId)
        if not att then
            self.m_Attachment[element.attachment] = false
            continue
        end

        self.m_Attachment[element.attachment] = att
    end
end

function SWEP:GetAttachmentData(name)
    return self.m_Attachment[name] or false
end

function SWEP:PostDrawViewModel(vm, weappon, ply, flag)
end

function SWEP:PreDrawViewModel(vm)
end

local cvar_mdv = CreateClientConVar("trmbase_sight_mdv", 1.33, true, false, "None Description", 0, 3)
local function MDVSensitivity(curFOV, defFOV, mdv)
    -- 限制 mdv 最小值，避免 tan 爆炸
    mdv = math.max(mdv or 1.33, 0.5) -- 最小 0.5

    if mdv == 0 then
        return curFOV / defFOV
    end

    -- 保护：避免角度接近 90°
    local angleA = math.rad(defFOV / 2) / mdv
    local angleB = math.rad(curFOV / 2) / mdv

    -- 角度超过 85° 时钳制，避免 tan 爆炸
    local maxAngle = math.rad(85)
    if angleA > maxAngle then angleA = maxAngle end
    if angleB > maxAngle then angleB = maxAngle end

    local a = math.tan(angleA)
    local b = math.tan(angleB)

    return math.Clamp(b / a, 0.01, 1)
end
local function HasScope(wep)
    for _, entry in pairs(wep.CurrentAttachments or {}) do
        local att = BASE_TRM_ATTS[entry.Class]
        if att and att.Scope and att.Scope.Zoom then
            return (BASE_TRM_ATTS[entry.Class].Scope.Zoom or 1)
        end
    end
    return false
end

function SWEP:AdjustMouseSensitivity(defaultSensitivity, localFOV, _)
    local defaultFOV = GetConVar("fov_desired"):GetInt()
    local currentFOV = localFOV
    local scope = HasScope(self)
    local aim = self:GetAimDelta()
    if scope then
        currentFOV = Lerp(aim, defaultFOV, defaultFOV / (scope or 1))
    else
        currentFOV = Lerp(aim, defaultFOV, localFOV / self.Aim.Scale)
    end
    --chat.AddText(scope)
    return MDVSensitivity(currentFOV, defaultFOV, cvar_mdv:GetFloat())
end

concommand.Add("trm_clear_test_model", function(ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    if wep.test and IsValid(wep.test.m_model) then
        wep.test.m_model:Remove()
        wep.test.m_model = nil
        print("测试模型已清除")
    else
        print("没有找到测试模型")
    end
end)

-- 调试 ConVar
CreateClientConVar("trmbase_freeze_vm", 0)

-- =============================================
-- 调试：冻结 viewmodel 位置/角度
-- =============================================

concommand.Add("trmbase_freeze_vm", function(ply, cmd, args)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not util.IsTRMBase(wep) then
        print("[TRMBase] 当前武器不是 TRM Base 武器")
        return
    end

    local cv = GetConVar("trmbase_freeze_vm")
    local newVal = cv:GetInt() == 0 and 1 or 0
    cv:SetInt(newVal)

    if newVal == 1 then
        local vm = wep:GetViewModel(0)
        if IsValid(vm) then
            wep.m_VMFreezePos = vm:GetPos()
            wep.m_VMFreezeAng = vm:GetAngles()
        end
        print("[TRMBase] Viewmodel 已冻结")
        print("  位置:", tostring(wep.m_VMFreezePos))
        print("  角度:", tostring(wep.m_VMFreezeAng))
        print("  再次执行 trmbase_freeze_vm 解冻")
    else
        wep.m_VMFreezePos = nil
        wep.m_VMFreezeAng = nil
        print("[TRMBase] Viewmodel 已解冻")
    end
end)
