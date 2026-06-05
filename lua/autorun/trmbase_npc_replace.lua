-- =============================================
-- TRMBase NPC/武器替换系统
-- 自动匹配弹药类型，支持随机选择
-- 开关:
--   trmbase_replace_npc (0/1)
--   trmbase_replace_weapon (0/1) - 替换生成的世界武器
-- =============================================

CreateConVar("trmbase_replace_npc", "0", FCVAR_ARCHIVE)
CreateConVar("trmbase_replace_weapon", "0", FCVAR_ARCHIVE)
CreateConVar("trmbase_replace_chance", "100", FCVAR_ARCHIVE)
CreateConVar("trmbase_random_attachments", "0", FCVAR_ARCHIVE)

local refresh = 1 -- 固定延迟，确保实体完全初始化

if CLIENT and not SERVER then return end

local SpecialAmmoMap = {
    ["XBowBolt"] = "SniperPenetratedRound",
    ['357Round'] = '357' ,
}

local WeaponMap = {
    ["weapon_mp5_hl1"] = { "smg1", "ar2" },
    ["weapon_glock_hl1"] = "pistol",
    ["weapon_shotgun_hl1"] = "buckshot",
}

-- 弹药箱映射表（扩展版）
local AmmoBoxMap = {
    -- 原版点实体
    ['ammo_357'] = "item_ammo_357",
    ['ammo_9mmbox'] = { "item_ammo_smg1_large", "item_ammo_ar2_large" },
    ['ammo_pistol'] = "item_ammo_pistol",
    ['ammo_buckshot'] = "item_box_buckshot",
    ['ammo_glockclip'] = "item_ammo_pistol",
    ['ammo_mp5clip'] = { "item_ammo_smg1", "item_ammo_ar2" },
    ['ammo_mp5grenades'] = "item_ammo_smg1_grenade",
    ['ammo_rpgclip'] = "item_rpg_round",
    ['ammo_crossbow'] = "ent_trm_sniper_ammo",
}

-- 查找所有使用指定弹药类型的 TRM 武器（返回列表，支持随机）
local function FindAllTRMByAmmo(weapon)
    local ClassName = weapon:GetClass()
    local ammoType = game.GetAmmoName((weapon:GetPrimaryAmmoType()))

    if weapon and WeaponMap[ClassName] then
        if istable(WeaponMap[ClassName]) then
            ammoType = WeaponMap[ClassName][math.random(#WeaponMap[ClassName])]
        else
            ammoType = WeaponMap[ClassName] or ammoType
        end
    end

    if not ammoType then return end

    if SpecialAmmoMap[ammoType] then
        ammoType = SpecialAmmoMap[ammoType]
    end

    local lower = string.lower(ammoType)
    local results = {}

    for _, wep in pairs(weapons.GetList()) do
        if type(wep) ~= "table" then continue end
        if wep.Base ~= "trm_gun_base" then continue end

        local wa = wep.Primary and wep.Primary.Ammo
        if wa and string.lower(wa) == lower then
            table.insert(results, wep.ClassName)
        end
    end

    return results
end

local function PickRandom(list)
    if #list == 0 then return nil end
    return list[math.random(#list)]
end

-- 检查替换概率（0-100）
local function RollChance()
    local cv = GetConVar("trmbase_replace_chance")
    local chance = cv and cv:GetInt() or 100
    return math.random(0, 99) < chance
end

-- 随机装备配件（跳过玩家武器）
local function RandomizeAttachments(ent)
    if not IsValid(ent) then return end
    if not ent.Attachments or #ent.Attachments == 0 then return end
    if not ent.EquipAttachment then return end

    -- 跳过玩家正在使用的武器（避免干扰玩家当前配件状态）
    local owner = ent:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then return end

    local cv = GetConVar("trmbase_random_attachments")
    if not cv or not cv:GetBool() then return end

    for i, slot in ipairs(ent.Attachments) do
        if not slot.Category then continue end

        -- 找到该槽位可用的配件
        local available = {}
        for attClass, attData in pairs(BASE_TRM_ATTS) do
            if type(attData) ~= "table" then continue end
            if not attData.Category then continue end

            for _, cat in ipairs(istable(slot.Category) and slot.Category or { slot.Category }) do
                if attData.Selectable == false then continue end
                if attData.Category == cat  then
                    table.insert(available, attClass)
                    break
                end
            end
        end

        if #available == 0 then continue end

        -- 每个槽 50% 概率装一个随机配件
        if  RollChance() then
            local chosen = available[math.random(#available)]
            if chosen ~= slot.Default then
                ent:EquipAttachment(tostring(i), chosen)
            end
        end
        ent:ChangeWeaponStats()
    end
end

-- ===== NPC 武器替换 =====
local function DoNPCReplace(npc)
    if not IsValid(npc) or not npc:IsNPC() then return end

    local cv = GetConVar("trmbase_replace_npc")
    if not cv or not cv:GetBool() then return end

    local wep = npc:GetActiveWeapon()
    if not IsValid(wep) or wep.Base == "trm_gun_base" then return end

    local candidates = FindAllTRMByAmmo(wep)
    if not candidates or  #candidates == 0 then return end

    local newClass = PickRandom(candidates)

    print("[TRMBase] NPC " ..
        npc:GetClass() .. ": " .. wep:GetClass() .. " → " .. newClass .. " (random from " .. #candidates .. ")")

    if IsValid(wep) then wep:Remove() end
    npc:Give(newClass)

    timer.Simple(refresh, function()
        local newWep = npc:GetActiveWeapon()
        if IsValid(newWep) then
            RandomizeAttachments(newWep)
        end
    end)
end

-- 是否由玩家生成的实体？
local function IsPlayerSpawned(ent)
    local owner = ent:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then return true end
    if ent.PlayerDropped then return true end
    return false
end

-- ===== 世界武器替换 =====
local function DoWeaponReplace(ent)
    if not IsValid(ent) then return end
    if not ent:IsWeapon() then return end
    if ent.Base == "trm_gun_base" then return end
    if IsValid(ent:GetOwner()) then return end

    local candidates = FindAllTRMByAmmo(ent)
    if not candidates or #candidates == 0 then return end

    local newClass = PickRandom(candidates)

    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local velocity = ent:GetVelocity()
    local isPlayerGen = IsPlayerSpawned(ent)

    print("[TRMBase] World weapon: " ..
        ent:GetClass() .. " → " .. newClass .. (isPlayerGen and " (player)" or " (world)"))

    ent:Remove()

    local newEnt = ents.Create(newClass)
    if IsValid(newEnt) then
        newEnt:SetPos(pos)
        newEnt:SetAngles(ang)
        newEnt:Spawn()
        newEnt:SetVelocity(velocity)

        -- 不是玩家生成的武器 → 随机装点配件
        if not isPlayerGen then
            timer.Simple(refresh, function()
                if IsValid(newEnt) then
                    RandomizeAttachments(newEnt)
                end
            end)
        end
    end
end

-- ===== 弹药箱替换（修复版） =====
-- ===== 弹药箱替换（保留原模型版） =====
local function ReplaceAmmoBox(ent)
    local class = ent:GetClass()
    if not AmmoBoxMap[class] then return false end

    -- 随机选择目标弹药箱类型
    local targetClass
    if istable(AmmoBoxMap[class]) then
        targetClass = AmmoBoxMap[class][math.random(#AmmoBoxMap[class])]
    else
        targetClass = AmmoBoxMap[class]
    end

    -- 保存原实体信息
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local model = tostring(ent:GetModel()) -- 原模型路径
    local skin = ent:GetSkin()   -- 原皮肤

    print("[TRMBase] Replacing ammo box: " .. class .. " → " .. targetClass)
    print("[TRMBase] Preserving model: " .. (model or "none"))

    -- 创建新弹药箱
    local newEnt = ents.Create(targetClass)
    if IsValid(newEnt) then
        newEnt:SetPos(pos)
        newEnt:SetAngles(ang)



        newEnt:Spawn()

        -- 可选：保留原弹药箱的弹药数量
        if ent.GetAmmoCount and newEnt.SetAmmoCount then
            newEnt:SetAmmoCount(ent:GetAmmoCount())
        end
        newEnt:SetModel(model)

        ent:Remove()
        print("[TRMBase] Successfully created: " .. targetClass .. " with original model")
        return true
    end

    print("[TRMBase] Failed to create: " .. targetClass)
    return false
end
-- ===== 主替换函数 =====
local cv = GetConVar("trmbase_replace_weapon")

local function replace(ent)
    if not IsValid(ent) or util.IsTRMBase(ent) then return end

    -- 优先处理弹药箱（弹药箱不是NPC也不是武器，需要单独处理）
    if AmmoBoxMap[ent:GetClass()] then
        ReplaceAmmoBox(ent)
        return -- 重要：处理完弹药箱就返回，避免继续执行下面的逻辑
    end

    if ent:IsNPC() then
        DoNPCReplace(ent)
    elseif ent:IsWeapon()  then
        if cv and cv:GetBool() then
            DoWeaponReplace(ent)
        end
    end
end

-- ===== 钩子 =====
hook.Add("OnEntityCreated", "TRMBase_Replace", function(ent)
    if not IsValid(ent) then return end

    -- 延迟执行，确保实体完全初始化
    timer.Simple(refresh, function()
        if IsValid(ent) then
            replace(ent)
        end
    end)
end)

hook.Add("PlayerDroppedWeapon", "TRMBASE_ReplaceDrop", function(owner, ent)
    timer.Simple(refresh, function()
        if IsValid(ent) then
            local cv = GetConVar("trmbase_replace_weapon")
            if cv and cv:GetBool() then
                DoWeaponReplace(ent)
            end
        end
    end)
end)

-- 定期扫描（处理地图预放置的实体）
local LastThink = 0
hook.Add("Think", "TRMBASE_ReplacerThink", function()
    if CurTime() - LastThink < refresh  then return end
    LastThink = CurTime()

    for _, ent in ents.Iterator() do
        if not IsValid(ent) then continue end

        -- 检查是否需要处理
        if ent:IsNPC() or
            (ent:IsWeapon() and ent:GetOwner() == NULL) or
            AmmoBoxMap[ent:GetClass()] then
            replace(ent)
        end
    end
end)

-- 读档后重新扫描
hook.Add("Restored", "TRMBASE_ReplaceRestored", function()
    timer.Simple(refresh, function()
        for _, ent in ents.Iterator() do
            if not IsValid(ent) then continue end
            if ent:IsNPC() or
                (ent:IsWeapon() and ent:GetOwner() == NULL) or
                AmmoBoxMap[ent:GetClass()] then
                replace(ent)
            end
        end
    end)
end)

print("[TRMBase] NPC/Weapon/Ammo replacement system loaded")
