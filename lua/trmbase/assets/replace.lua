-- =============================================
-- TRMBase NPC/武器替换系统
-- 仅在玩家拾取前替换 HL2/HL1 Source 武器 + 弹药盒
-- =============================================

CreateConVar("trmbase_replace_weapon", 0, FCVAR_ARCHIVE)

local refresh = 0.5

if CLIENT and not SERVER then return end

-- ========== 需要替换的武器列表（仅 HL2 + HL1 Source） ==========
local ReplaceableWeapons = {
    -- HL2 武器
    "weapon_ar2",
    "weapon_pistol",
    "weapon_smg1",
    "weapon_shotgun",
    "weapon_357",
    "weapon_crossbow",
    -- HL1 Source 武器
    "weapon_357_hl1",
    "weapon_glock_hl1",
    "weapon_mp5_hl1",
    "weapon_shotgun_hl1", "weapon_crossbow_hl1"
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

-- ========== 弹药箱映射表 ==========
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

-- ========== 钩子 ==========
hook.Add("PlayerCanPickupWeapon", "TRMBase_Replace", function(ply, ent)
end)

hook.Add("PlayerCanPickupItem", "TRMBase_Replace", function(ply, item)
end)

hook.Add("PlayerDroppedWeapon", "TRMBASE_ReplaceDrop", function(owner, ent)
end)

hook.Add("OnEntityCreated", "TRMBase_Replace", function(entity)
    --只替换弹药箱子
end)

-- 4. 读档后扫描
hook.Add("Restored", "TRMBASE_ReplaceRestored", function()
    -- timer.Simple(refresh, function()
    --     for _, ent in ents.Iterator() do
    --         if IsValid(ent) then
    --             TryReplace(ent)
    --         end
    --     end
    -- end)
end)
