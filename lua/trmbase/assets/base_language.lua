-- trmbase_language_util.lua
if SERVER then
    AddCSLuaFile()
end
if not CLIENT then return end

TRMBase = TRMBase or {}
TRMBase.Language = TRMBase.Language or {}

-- 中文
TRMBase.Language.cn = {
    ["SniperPenetratedRound_ammo"] = "狙击弹药",
    ["SniperRound_ammo"]           = "狙击弹药ALT",

    ["Optic"]                      = "瞄具",
    ["Muzzle"]                     = "枪口",
    ["Laser"]                      = "战术配件",
    ["Mag"]                        = "弹匣",
    ["Barrel"]                     = "枪管",
    ["Stock"]                      = "枪托",
    ["Grip"]                       = "后握把",
    ["UnderBarrel"]                = "下挂",
    ["Misc"]                       = "杂项",
    ["Pump"]                       = "泵把",
    ["Sight"]                      = "瞄具",
    ["Tactical"]                   = "战术配件",
    ["Ammo"]                       = "弹药",
    ["Perk"]                       = "特长",

    -- VGUI
    ["TRMBase_Installed"]          = "已安装",
    ["TRMBase_Default"]            = "默认配件",
    ["TRMBase_None"]               = "无",
    ["TRMBase_Customize"]          = " - 自定义",
    ["TRMBase_NoSlots"]            = "此武器没有配件槽位",
    ["TRMBase_CloseHint"]          = "按 Menu_Context 关闭",
    ["TRMBase_SlotExcluded"]       = "此槽位被已装备的配件排除",
    ["TRMBase_Excluded"]           = "已排除",

    ["TRMBase_VGUI_Customize"]     = "武器改装",
    ["TRMBase_VGUI_DragHint"]      = "左键拖动，滚轮缩放",

    -- 属性面板
    ["TRMBase_Stat_Damage"]        = "伤害",
    ["TRMBase_Stat_ClipSize"]      = "弹匣容量",
    ["TRMBase_Stat_RPM"]           = "射速",
    ["TRMBase_Stat_Spread"]        = "散布",
    ["TRMBase_Stat_AimSpeed"]      = "开镜时间",
    ["TRMBase_Stat_Recoil"]        = "后坐力",

    -- 菜单选项
    --3D2D
    ["TRMBase_3D2D"]               = "显示3D2D",
    ["TRMBase_3D2D_Always"]        = "总是显示3D2D",

    --Admin
    ["TRMBase_InfiniteAmmo"]       = "无限备弹",
    ["TRMBase_AutoReload"]         = "自动换弹",
    ["TRMBase_FireInteruptReload"] = "开火打断换弹",
    ["TRMBase_SprintReload"]       = "冲刺换弹",
    ["TRMBase_LoadAttOnPickup"]    = "拾取时加载配件（还没做好",
    ["TRMBase_Holster"]            = "在游泳/梯子收起武器",
    --bullet
    ["TRMBase_Physical_Bullet"]    = "物理子弹",
    --NPC
    ["TRMBase_ReplaceNPC"]         = "替换 NPC 武器",
    ["TRMBase_ReplaceWeapon"]      = "替换生成武器",
    ["TRMBase_ReplaceChance"]      = "替换概率",
    ["TRMBase_RandomAttach"]       = "随机配件",
    --Client
    ["TRMBase_HUD"]                = "启用HUD",
    ["TRMBase_HideHUD"]            = "隐藏默认HL2HUD",
    ["TRMBase_HUD_Scale"]          = "HUD的缩放",
    ["TRMBase_MeleeKey"]           = "近战",
    ["TRMBase_InspectKey"]         = "检视",
    ["TRMBase_CustomizeKey"]       = "自定义",
    ["TRMBase_UnderBarrelKey"]     = "切换下挂武器",
    ["TRMBase_Crosshair"]          = "准星",
    ["TRMBase_CrosshairColor"]     = "准星颜色",
    ["TRMBase_CrosshairStyle"]     = "准星样式",
    ["TRMBase_CrosshairDot"]       = "准星中心点",
    ["TRMBase_HideHUDInspect"]     = "检视时隐藏 HUD",
    ["TRMBase_ToggleAim"]          = "切换式瞄准",
    ["TRMBase_MDV"]                = "灵敏度缩放系数",
    --Mod
    ["TRMBase_CheapScope"]         = "高性能准镜",
    ["TRMBase_Zeroing"]            = "弹道归零",
    ["TRMBase_ScopeZoom"]          = "变焦",
    ["TRMBase_HybridToggle"]       = "切换混合瞄具",
    ["TRMBase_TacSightToggle"]     = "切换战术姿态",
    --
    ["TRMBase_Mod_Shake"]          = "后坐力晃动",
    ["TRMBase_Mod_Recoil"]         = "后坐力",
    ["TRMBase_Mod_VisualRecoil"]   = "视觉后坐力",
    ["TRMBase_Mod_AimSpeed"]       = "开镜速度",
    ["TRMBase_Mod_Damage"]         = "伤害",
    --Viewmodel
    ["TRMBase_OffsetX"]            = "X轴偏移",
    ["TRMBase_OffsetY"]            = "Y轴偏移",
    ["TRMBase_OffsetZ"]            = "Z轴偏移",
    ["TRMBase_ViewmodelFOVAim"]    = "开镜时的VMFOV",
    ["TRMBase_FreezeVM"]           = "冻结VM（调试用）",
    ["TRMBase_FreezeVM_Desc"]      = "冻结ViewModel动画，方便调试配件位置",
    ["TRMBase_DebugHUD"]           = "调试HUD",
    ["TRMBase_DebugReload"]        = "调试换弹",

    -- Firemode
    ["TRMBase_Firemode"]           = "开火模式",
}

-- 英文
TRMBase.Language.en = {
    ["SniperPenetratedRound_ammo"] = "Sniper Ammo",
    ["SniperRound_ammo"]           = "Sniper Ammo ALT",

    ["Optic"]                      = "Optic",
    ["Muzzle"]                     = "Muzzle",
    ["Laser"]                      = "Tactical",
    ["Mag"]                        = "Magazine",
    ["Barrel"]                     = "Barrel",
    ["Stock"]                      = "Stock",
    ["Grip"]                       = "Grip",
    ["UnderBarrel"]                = "Underbarrel",
    ["Misc"]                       = "Misc",
    ["Pump"]                       = "Pump",
    ["Sight"]                      = "Sight",
    ["Tactical"]                   = "Tactical",
    ["Ammo"]                       = "Ammo",
    ["Perk"]                       = "Perk",

    -- VGUI
    ["TRMBase_Installed"]          = "Installed",
    ["TRMBase_Default"]            = "Default",
    ["TRMBase_None"]               = "None",
    ["TRMBase_Customize"]          = " - Customize",
    ["TRMBase_NoSlots"]            = "This weapon has no attachment slots",
    ["TRMBase_CloseHint"]          = "Press Menu_Context to close",
    ["TRMBase_SlotExcluded"]       = "This slot is excluded by equipped attachments",
    ["TRMBase_Excluded"]           = "Excluded",

    ["TRMBase_VGUI_Customize"]     = "Weapon Customize",
    ["TRMBase_VGUI_DragHint"]      = "Left drag to rotate | Scroll to zoom",

    -- Stats
    ["TRMBase_Stat_Damage"]        = "Damage",
    ["TRMBase_Stat_ClipSize"]      = "Magazine Size",
    ["TRMBase_Stat_RPM"]           = "RPM",
    ["TRMBase_Stat_Spread"]        = "Spread",
    ["TRMBase_Stat_AimSpeed"]      = "Aim Time",
    ["TRMBase_Stat_Recoil"]        = "Recoil",

    -- Menu
    ["TRMBase_3D2D"]               = "Show 3D2D",
    ["TRMBase_3D2D_Always"]        = "Always show 3D2D",

    -- Admin
    ["TRMBase_InfiniteAmmo"]       = "Infinite Reserve Ammo",
    ["TRMBase_AutoReload"]         = "Auto Reload",
    ["TRMBase_FireInteruptReload"] = "Fire Interrupts Reload",
    ["TRMBase_SprintReload"]       = "Sprint Reload",
    ["TRMBase_LoadAttOnPickup"]    = "Load Attachments on Pickup (WIP)",
    ["TRMBase_Holster"]            = "Holster when swimming/on ladder",

    -- Bullet
    ["TRMBase_Physical_Bullet"]    = "Physical Bullet",

    -- NPC
    ["TRMBase_ReplaceNPC"]         = "Replace NPC Weapon",
    ["TRMBase_ReplaceWeapon"]      = "Replace Spawned Weapon",
    ["TRMBase_ReplaceChance"]      = "Replace Chance",
    ["TRMBase_RandomAttach"]       = "Random Attachments",

    -- Client
    ["TRMBase_HUD"]                = "Enable HUD",
    ["TRMBase_HideHUD"]            = "Hide Default HL2 HUD",
    ["TRMBase_HUD_Scale"]          = "HUD Scale",
    ["TRMBase_MeleeKey"]           = "Melee",
    ["TRMBase_InspectKey"]         = "Inspect",
    ["TRMBase_CustomizeKey"]       = "Customize",
    ["TRMBase_UnderBarrelKey"]     = "Toggle Underbarrel",
    ["TRMBase_Crosshair"]          = "Crosshair",
    ["TRMBase_CrosshairColor"]     = "Crosshair Color",
    ["TRMBase_CrosshairStyle"]     = "Crosshair Style",
    ["TRMBase_CrosshairDot"]       = "Crosshair Dot",
    ["TRMBase_HideHUDInspect"]     = "Hide HUD When Inspecting",
    ["TRMBase_ToggleAim"]          = "Toggle Aim",
    ["TRMBase_MDV"]                = "MDV Sensitivity",

    -- Mod
    ["TRMBase_CheapScope"]         = "Cheap Scope (Performance)",
    ["TRMBase_Zeroing"]            = "Zeroing",
    ["TRMBase_ScopeZoom"]          = "Scope Zoom",
    ["TRMBase_HybridToggle"]       = "Toggle Hybrid Sight",
    ["TRMBase_TacSightToggle"]     = "Toggle Tactical Stance",

    -- Weapon Modifiers
    ["TRMBase_Mod_Shake"]          = "Recoil Shake",
    ["TRMBase_Mod_Recoil"]         = "Recoil",
    ["TRMBase_Mod_VisualRecoil"]   = "Visual Recoil",
    ["TRMBase_Mod_AimSpeed"]       = "Aim Speed",
    ["TRMBase_Mod_Damage"]         = "Damage",

    -- Viewmodel
    ["TRMBase_OffsetX"]            = "Offset X",
    ["TRMBase_OffsetY"]            = "Offset Y",
    ["TRMBase_OffsetZ"]            = "Offset Z",
    ["TRMBase_ViewmodelFOVAim"]    = "Viewmodel FOV (Aiming)",
    ["TRMBase_FreezeVM"]           = "Freeze VM (Debug)",
    ["TRMBase_FreezeVM_Desc"]      = "Freeze ViewModel animation for attachment debugging",
    ["TRMBase_DebugHUD"]           = "Debug HUD",
    ["TRMBase_DebugReload"]        = "Debug Reload",

    -- Firemode
    ["TRMBase_Firemode"]           = "Firemode",
}

-- 获取当前语言
function TRMBase.GetLanguage()
    local lang = GetConVar("gmod_language"):GetString()
    lang = string.lower(lang)
    if lang == "zh-cn" or lang == "zh-tw" then
        return TRMBase.Language.cn
    end
    return TRMBase.Language.en
end

local function refreshLang()
    for k, v in pairs(TRMBase.GetLanguage()) do
        language.Add(k, v)
    end
end
refreshLang()

function LanguageChanged(lang)
end

hook.Add("LanguageChanged", "TRMBASE_ImmediatelyUpdateLang", function()
    refreshLang()
end)


 