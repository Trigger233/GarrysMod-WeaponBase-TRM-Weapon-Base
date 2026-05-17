-- =============================================
-- TRMBase NPC 武器替换系统
-- 自动根据 NPC 当前武器的弹药类型匹配合适的 TRM 武器
-- 开关: trmbase_replace_npc (0/1)
-- =============================================

CreateConVar("trmbase_replace_npc", "0", FCVAR_ARCHIVE)
if CLIENT and not SERVER then return end

-- 查找使用指定弹药类型的 TRM 武器
-- weapons.GetList() 返回的是定义表（不是实体），用 Base 字段判断
local function FindTRMByAmmo(ammoType)
    if not ammoType then return nil end
    local lower = string.lower(ammoType)
    for _, wep in pairs(weapons.GetList()) do
        if type(wep) ~= "table" then continue end
        if wep.Base ~= "trm_gun_base" then continue end
        local wa = wep.Primary and wep.Primary.Ammo
        if wa and string.lower(wa) == lower then
            return wep.ClassName
        end
    end
    return nil
end

local function DoNPCReplace(npc)
    if not IsValid(npc) or not npc:IsNPC() then return end
    local cv = GetConVar("trmbase_replace_npc")
    if not cv or not cv:GetBool() then return end

    local wep = npc:GetActiveWeapon()
    if not IsValid(wep) then return end

    -- 读武器弹药类型，没有就按 NPC 类型推断
    local ammoType =game.GetAmmoName( wep:GetPrimaryAmmoType())
    if not ammoType or ammoType == "" then
        local ammoMap = {
            npc_combine_s = "ar2",
            npc_combine = "ar2",
            npc_metropolice = "pistol",
            npc_rebel = "pistol",
            npc_citizen = "pistol",
        }
        ammoType = ammoMap[npc:GetClass()]
        if not ammoType then return end
    end

    local newClass = FindTRMByAmmo(ammoType)
    if not newClass then return end

    print("[TRMBase] Replacing " .. npc:GetClass() .. "'s weapon → " .. newClass)
    if IsValid(wep) then wep:Remove() end
    npc:Give(newClass)
    local nw = npc:GetWeapon(newClass)
    --print(nw)
    --if IsValid(nw) then npc:SetActiveWeapon(nw) end
end

-- 玩家从菜单生成 NPC
-- hook.Add("PlayerSpawnedNPC", "TRMBase_NPCReplace", function(ply, npc)
--     if not IsValid(npc) then return end
--     print("[TRMBase] PlayerSpawnedNPC: " .. npc:GetClass())
--     timer.Simple(0.3, function() DoReplace(npc) end)
-- end)

hook.Add("OnEntityCreated","TRMBase_Replace",function(ent )
    if ent:IsNPC() then
        timer.Simple(FrameTime()*3,function()
            DoNPCReplace(ent)
        end)
    end
    
end)