-- =============================================
-- TRMBase NPC/武器替换系统
-- 仅在玩家拾取前替换 HL2/HL1 Source 武器
-- =============================================

CreateConVar("trmbase_replace_npc", "0", FCVAR_ARCHIVE)
CreateConVar("trmbase_replace_weapon", "0", FCVAR_ARCHIVE)
CreateConVar("trmbase_replace_chance", "100", FCVAR_ARCHIVE)
CreateConVar("trmbase_random_attachments", "0", FCVAR_ARCHIVE)

local refresh = 0.5

if CLIENT and not SERVER then return end

-- ========== 需要替换的武器列表（仅 HL2 + HL1 Source） ==========
local ReplaceableWeapons = {
    -- HL2 武器
    "weapon_ar2",
    "weapon_ar2_altfire",
    "weapon_pistol",
    "weapon_smg1",
    "weapon_shotgun",
    "weapon_357",
    "weapon_rpg",
    "weapon_crossbow",
    "weapon_frag",
    "weapon_stunstick",
    "weapon_bugbait",
    "weapon_physcannon",
    "weapon_crowbar",

    -- HL1 Source 武器
    "weapon_mp5_hl1",
    "weapon_glock_hl1",
    "weapon_shotgun_hl1",
    "weapon_357_hl1",
    "weapon_crossbow_hl1",
    "weapon_rpg_hl1",
    "weapon_uzi_hl1",
    "weapon_9mmAR_hl1",
    "weapon_egon_hl1",
    "weapon_handgrenade_hl1",
    "weapon_satchel_hl1",
    "weapon_tripmine_hl1",
    "weapon_snark_hl1",
    "weapon_dualpistol_hl1",
    "weapon_charger_hl1",
    "weapon_m203_hl1",
    "weapon_grapple_hl1",
    "weapon_mp5_hl1_sd",
    "weapon_ak47_hl1",
}

-- 弹药映射（HL2 → TRM）
local SpecialAmmoMap = {
    ["XBowBolt"] = "SniperPenetratedRound",
    ['357Round'] = '357',
}

local WeaponMap = {
    ["weapon_mp5_hl1"] = { "smg1", "ar2" },
    ["weapon_glock_hl1"] = "pistol",
    ["weapon_shotgun_hl1"] = "buckshot",
}

local AmmoBoxMap = {
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

-- ========== 判断是否应该替换 ==========
local function ShouldReplaceWeapon(ent)
    if not IsValid(ent) then return false end
    if not ent:IsWeapon() then return false end
    if ent.Base == "trm_gun_base" then return false end
  --  if IsValid(ent:GetOwner()) then return false end -- 已有主人

    local class = ent:GetClass()
    for _, replaceClass in ipairs(ReplaceableWeapons) do
        if class == replaceClass then
            return true
        end
    end
    return false
end

-- ========== 查找 TRM 替换武器 ==========
local function FindTRMReplacement(weapon)
    local class = weapon:GetClass()
    local ammoType = game.GetAmmoName(weapon:GetPrimaryAmmoType())

    if weapon and WeaponMap[class] then
        if istable(WeaponMap[class]) then
            ammoType = WeaponMap[class][math.random(#WeaponMap[class])]
        else
            ammoType = WeaponMap[class] or ammoType
        end
    end

    if not ammoType then return nil end

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

    return #results > 0 and results[math.random(#results)] or nil
end

-- ========== 随机配件 ==========
local function RandomizeAttachments(ent)
    if not IsValid(ent) then return end
    if not ent.Attachments or #ent.Attachments == 0 then return end
    if not ent.EquipAttachment then return end

    local owner = ent:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then return end

    local cv = GetConVar("trmbase_random_attachments")
    if not cv or not cv:GetBool() then return end

    for i, slot in ipairs(ent.Attachments) do
        if not slot.Category then continue end

        local available = {}
        for attClass, attData in pairs(BASE_TRM_ATTS) do
            if type(attData) ~= "table" then continue end
            if not attData.Category then continue end
            if attData.Selectable == false then continue end

            local categories = istable(slot.Category) and slot.Category or { slot.Category }
            for _, cat in ipairs(categories) do
                if attData.Category == cat then
                    table.insert(available, attClass)
                    break
                end
            end
        end

        if #available == 0 then continue end

        if math.random() < 0.5 then
            local chosen = available[math.random(#available)]
            if chosen ~= slot.Default then
                ent:EquipAttachment(tostring(i), chosen)
            end
        end
    end
    ent:ChangeWeaponStats()
end

-- ========== 替换逻辑 ==========
local cv_replace = GetConVar("trmbase_replace_weapon")

local function ReplaceWeaponIfNeeded(ent)
    if not ShouldReplaceWeapon(ent) then return end

    local cv = GetConVar("trmbase_replace_weapon")
    if not cv or not cv:GetBool() then return end

    local chance = GetConVar("trmbase_replace_chance"):GetInt() or 100
    if math.random(0, 99) >= chance then return end

    local newClass = FindTRMReplacement(ent)
    if not newClass then return end

    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local velocity = ent:GetVelocity()

    print("[TRMBase] Replacing:", ent:GetClass(), "→", newClass)

    ent:Remove()

    local newEnt = ents.Create(newClass)
    if IsValid(newEnt) then
        newEnt:SetPos(pos)
        newEnt:SetAngles(ang)
        newEnt:Spawn()
        newEnt:SetVelocity(velocity)

        timer.Simple(refresh, function()
            if IsValid(newEnt) then
                RandomizeAttachments(newEnt)
            end
        end)
    end
end

-- ========== 钩子 ==========
hook.Add("PlayerCanPickupWeapon", "TRMBase_Replace", function(ply,ent)
    if not IsValid(ent) then return end
    timer.Simple(refresh, function()
        if IsValid(ent) then
            ReplaceWeaponIfNeeded(ent)
        end
    end)
end)

-- 2. 玩家丢武器时检测
hook.Add("PlayerDroppedWeapon", "TRMBASE_ReplaceDrop", function(owner, ent)
    timer.Simple(refresh, function()
        if IsValid(ent) then
            ReplaceWeaponIfNeeded(ent)
        end
    end)
end)

-- 3. 读档后扫描
hook.Add("Restored", "TRMBASE_ReplaceRestored", function()
    timer.Simple(refresh, function()
        for _, ent in ents.Iterator() do
            if IsValid(ent) and ShouldReplaceWeapon(ent) then
                ReplaceWeaponIfNeeded(ent)
            end
        end
    end)
end)

print("[TRMBase] Weapon replacement system loaded (HL2/HL1 only)")
