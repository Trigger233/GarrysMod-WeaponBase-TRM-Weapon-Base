if SERVER then return end

function SWEP:ShouldDrawViewModel()
    local owner = self:GetOwner()
    if owner:InVehicle() then return false end
    return true
end

require("trm_utils")
function SWEP:ViewModelDrawn(vm, flag)
    if not IsValid(vm) or self.TRMViewModelOverDraw then return end
    self:BuildViewmodelAttachmentsData(vm)

    self.m_StoredAngle      = self:GetCameraControler()
    self.m_CameraAttachment = self:GetCameraAttachmentAngle(vm)
end

function SWEP:GetAttachmentData(name)
    return self.m_Attachment[name] or false
end

function SWEP:PostDrawViewModel(vm, weappon, ply, flag)
    if self.TRMViewModelOverDraw then return end


    cam.End3D()
end

local cvar_blur = CreateClientConVar("trmbase_cl_blur", 1, true, true, "helptext", 0, 1)
local BlurMul = 0
local CycleLerp = 0
function SWEP:PreDrawViewModel(vm)
    if self.TRMViewModelOverDraw then return end

    -- self:DoLHIK()


    BlurMul = Lerp(RealFrameTime() * 10, BlurMul,
        (self:IsReloading() and self:GetAimDelta() < 0.2 or self:IsCustomizing() or self:IsInspecting()) and 1 or 0)
    if BlurMul > 0.1 and cvar_blur:GetBool() then
        DrawBokehDOF(BlurMul * 5, 1, 1)
    end
    cam.Start3D(EyePos(), EyeAngles(), self:GetViewmodelFov(), 0, 0, ScrW(), ScrH(), 1, 1024)

    if GetConVar("trmbase_cl_cheapscope"):GetBool() then
        self:RenderScopeView()
    end
    render.DepthRange(0.0, 0)
end

-- 调试 ConVar
CreateClientConVar("trmbase_freeze_vm", 0)


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


local NextUpdate = 0
local UpdateTime = 1 / 120
local stack = {}
SWEP.m_Attachment = {}



local function IsEmpty(_table) return #_table > 0 end

function SWEP:BuildViewmodelAttachmentsData(vm)
    if not IsValid(vm) then return end
    local stats = self.Effects
    if not stats then return end

    if #stack < 1 then
        for _, element in pairs(stats) do
            if element.attachment then
                stack[#stack + 1] = element.attachment
            end
        end
    end

    local handle = 1
    --PrintTable(stack)

    while (#stack > 0) do
        if handle > 1 then break end
        if SysTime() < NextUpdate then break end

        local attName = table.remove(stack, 1)

        if ! attName then
            continue
        end
        local ent, attId = self:FindAttachment(vm, attName)
        if ! IsValid(ent) or ! attId or attId == -1 then
            continue
        end

        self.m_Attachment[attName] = ent:GetAttachment(attId)
        --PrintTable(self.m_Attachment)
        handle = handle + 1

        NextUpdate = SysTime() + UpdateTime
    end
end
