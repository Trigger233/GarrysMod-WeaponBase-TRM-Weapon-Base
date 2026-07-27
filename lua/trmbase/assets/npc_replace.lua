-- =============================================
-- TRMBase 武器/弹药替换系统
-- 只替换地图生成的 HL2/HL1 武器 + 弹药箱
-- =============================================

CreateConVar("trmbase_replace_weapon", 1, FCVAR_ARCHIVE)

local refresh = 0.5

if CLIENT and not SERVER then return end

-- ========== 需要替换的武器列表 ==========
local ReplaceableWeapons = {
    -- HL2
    "weapon_ar2", "weapon_pistol", "weapon_smg1", "weapon_shotgun",
    "weapon_357", "weapon_crossbow",
    -- HL1
    "weapon_357_hl1", "weapon_glock_hl1", "weapon_mp5_hl1",
    "weapon_shotgun_hl1", "weapon_crossbow_hl1"
}
local ReplaceableWeaponsMelee = {
    "weapon_crowbar", "weapon_stunstick"
}

local BlackList = {
    "trm_gun_base", "trm_melee_base", "trm_nade_base"
}

-- 弹药映射
local WeaponMap = {
    ["weapon_mp5_hl1"] = { "smg1", "ar2" },
    ["weapon_glock_hl1"] = "pistol",
    ["weapon_shotgun_hl1"] = "buckshot",
}

local SpecialAmmoMap = {
    ["XBowBolt"] = "SniperPenetratedRound",
    ["XBowBoltHL1"] = "SniperPenetratedRound",
    ['357Round'] = '357',
}

-- ========== 弹药箱映射 ==========
local AmmoBoxMap = {
    ['ammo_357'] = "item_ammo_357",
    ['ammo_9mmbox'] = { "item_ammo_smg1_large", "item_ammo_ar2_large" },
    ['ammo_pistol'] = "item_ammo_pistol",
    ['ammo_buckshot'] = "item_box_buckshot",
    ['ammo_glockclip'] = "item_ammo_pistol",
    ['ammo_mp5clip'] = { "item_ammo_smg1", "item_ammo_ar2" },
    ['ammo_mp5grenades'] = "item_ammo_smg1_grenade",
    ['ammo_rpgclip'] = "item_rpg_round",
    ['item_ammo_crossbow'] = "ent_trm_sniper_ammo",
}

-- ========== 判断是否需要替换武器 ==========
local function ShouldReplaceWeapon(ent)
    if not IsValid(ent) or not ent:IsWeapon() then return false end
    if weapons.IsBasedOn(ent:GetClass(), "trm_gun_base") then return false end
    --if IsValid(ent:GetOwner()) then return false end -- 有主人的不替换

    local class = ent:GetClass()
    for _, name in ipairs(ReplaceableWeapons) do
        if class == name then return true end
    end

    if table.HasValue(ReplaceableWeaponsMelee, class) then
        return true
    end

    return false
end

local function ShouldReplaceAmmoBox(ent)
    if not IsValid(ent) then return false end
    return AmmoBoxMap[ent:GetClass()] ~= nil
end

-- ========== 查找 TRM 替换武器 ==========-

--PrintTable(weapons.Get("trm_base_melee_crowbar"))
local function FindTRMReplacement(weapon)
    local class = weapon:GetClass()
    local ammoType = game.GetAmmoName(weapon:GetPrimaryAmmoType())
    local AllWeapons = weapons.GetList()
    local results = {}

    if table.HasValue(ReplaceableWeaponsMelee, class) then
        for _, wep in ipairs(AllWeapons) do
            if type(wep) ~= "table" then continue end

            local className = wep.ClassName



            if table.HasValue(BlackList, className) then
                continue
            end

            if weapons.IsBasedOn(className, "trm_melee_base") and ! weapons.IsBasedOn(className, "trm_nade_base") then
                table.insert(results, className)
            end
        end
        return #results > 0 and results[math.random(#results)] or nil
    end


    if WeaponMap[class] then
        if istable(WeaponMap[class]) then
            ammoType = WeaponMap[class][math.random(#WeaponMap[class])]
        else
            ammoType = WeaponMap[class] or ammoType
        end
    end

    if not ammoType then return nil end
    ammoType = SpecialAmmoMap[ammoType] or ammoType

    local lower = string.lower(ammoType)

    for _, wep in pairs(AllWeapons) do
        if type(wep) ~= "table" then continue end
        if wep.Base ~= "trm_gun_base" then continue end
        if wep.Primary and string.lower(wep.Primary.Ammo or "") == lower then
            table.insert(results, wep.ClassName)
        end
    end

    return #results > 0 and results[math.random(#results)] or nil
end

local function IsMelee(ClassName)
    return weapons.IsBasedOn(ClassName, "trm_melee_base") and not weapons.IsBasedOn(ClassName, "trm_nade_base")
end

local function HasMelee(ply)
    for _, weapon in ipairs(ply:GetWeapons()) do
        if IsMelee(weapon:GetClass()) then
            return true
        end
    end

    return false
end

-- ========== 替换武器 ==========
local function ReplaceWeapon(ent)
    if not ShouldReplaceWeapon(ent) then return end
    if not GetConVar("trmbase_replace_weapon"):GetBool() then return end

    local newClass = FindTRMReplacement(ent)
    if not newClass then return end

    local pos, ang, vel = ent:GetPos(), ent:GetAngles(), ent:GetVelocity()

    --print("[TRMBase] Replace weapon:", ent:GetClass(), "→", newClass)

    ent:Remove()

    local newEnt = ents.Create(newClass)
    if IsValid(newEnt) then
        newEnt:SetPos(pos)
        newEnt:SetAngles(ang)
        newEnt:Spawn()
        newEnt:SetVelocity(vel)
    end
end

-- ========== 替换弹药箱 ==========
local function ReplaceAmmoBox(ent)
    if not ShouldReplaceAmmoBox(ent) then return end

    local class = ent:GetClass()
    local target = AmmoBoxMap[class]
    if istable(target) then
        target = target[math.random(#target)]
    end

    local pos, ang, model, skin = ent:GetPos(), ent:GetAngles(), ent:GetModel(), ent:GetSkin()

    print("[TRMBase] Replace ammo:", class, "→", target)

    ent:Remove()

    local newEnt = ents.Create(target)
    if IsValid(newEnt) then
        newEnt:SetPos(pos)
        newEnt:SetAngles(ang)
        newEnt:Spawn()
        if model and model ~= "" and newEnt.SetModel then
            newEnt:SetModel(model)
        end
        if skin and newEnt.SetSkin then
            newEnt:SetSkin(skin)
        end
    end
end

-- ========== 主函数 ==========
local function TryReplace(ent)
    if not IsValid(ent) then return end
    if ShouldReplaceAmmoBox(ent) then
        ReplaceAmmoBox(ent)
    elseif ShouldReplaceWeapon(ent) then
        ReplaceWeapon(ent)
    end
end

local function ReplaceWeaponOnPickup(ply, ent)
    if ! IsFirstTimePredicted() then return end
    if not IsValid(ent) or not ShouldReplaceWeapon(ent) then return end
    if not GetConVar("trmbase_replace_weapon"):GetBool() then return end

    local newClass = FindTRMReplacement(ent)
    if not newClass then return end

    local pos = ent:GetPos()
    local ang = ent:GetAngles()


    ent:Remove()

    local newEnt = ents.Create(newClass)
    if IsValid(newEnt) then
        newEnt:SetPos(pos)
        newEnt:SetAngles(ang)
        newEnt:Spawn()
    end
    return true
end

hook.Add("PlayerCanPickupWeapon", "TRMBase_ReplaceWeapon", function(ply, ent)
     if ReplaceWeaponOnPickup(ply, ent) then
        return false
     end

    if HasMelee(ply) and IsMelee(ent:GetClass()) then
        return false
    end
end)
-- ========== 钩子：只替换弹药箱 ==========
hook.Add("OnEntityCreated", "TRMBase_ReplaceAmmo", function(entity)
    if not IsValid(entity) then return end
    if not AmmoBoxMap[entity:GetClass()] then return end

    timer.Simple(refresh, function()
        if IsValid(entity) then
            ReplaceAmmoBox(entity)
        end
    end)
end)

-- ========== 钩子：替换武器（玩家丢出时） ==========
hook.Add("PlayerDroppedWeapon", "TRMBASE_ReplaceWeapon", function(owner, ent)
    timer.Simple(refresh, function()
        if IsValid(ent) then
            ReplaceWeapon(ent)
        end
    end)
end)

-- ========== 钩子：读档后扫描 ==========
hook.Add("Restored", "TRMBASE_ReplaceRestored", function()
    timer.Simple(refresh, function()
        for _, ent in ents.Iterator() do
            if IsValid(ent) then
                TryReplace(ent)
            end
        end
    end)
end)
