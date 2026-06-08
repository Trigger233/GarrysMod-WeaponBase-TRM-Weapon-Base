if not CLIENT then return end

CreateClientConVar("trmbase_cl_keybind_melee", 0, true, false, "Melee keybind")
CreateClientConVar("trmbase_cl_keybind_inspect", 0, true, false, "Inspect keybind")
CreateClientConVar("trmbase_cl_keybind_customize", 0, true, false, "Customize keybind")
CreateClientConVar("trmbase_cl_keybind_firemode", 0, true, false, "Firemode keybind")

-- 使用 ConVar 引用而非一次性读出，确保实时生效
local cv_melee = GetConVar("trmbase_cl_keybind_melee")
local cv_inspect = GetConVar("trmbase_cl_keybind_inspect")
local cv_customize = GetConVar("trmbase_cl_keybind_customize")
local cv_firemode = GetConVar("trmbase_cl_keybind_firemode")
local cv_underbarrel = CreateClientConVar("trmbase_cl_keybind_ub", 0, true, false, "Underbarrel keybind")

hook.Add("PlayerBindPress", "TRMBASE_Weapon_Binds", function(ply, bind, pressed)
    local weapon = LocalPlayer():GetActiveWeapon()
    if not util.IsTRMBase(weapon) then return end

    -- Melee
    if input.WasKeyPressed(cv_melee:GetInt()) and cv_melee:GetInt() > 0 then
        RunConsoleCommand("trmbase_melee")
    end

    if input.WasKeyPressed(cv_melee:GetInt()) and cv_melee:GetInt() > 0 then
        RunConsoleCommand("trmbase_melee")
    end
    -- Inspect
    if input.WasKeyPressed(cv_inspect:GetInt()) and cv_inspect:GetInt() > 0 then
        RunConsoleCommand("trmbase_weaponinspect")
    end

    if input.WasKeyPressed(cv_underbarrel:GetInt()) and cv_underbarrel:GetInt() > 0 then
        RunConsoleCommand("+trmbase_switch_underbarrel")
    end
    -- Customize：独立按键 vs 菜单回退，两条路泾渭分明
    local custKey = cv_customize:GetInt()

    -- 路径 A：有独立按键 → 只认该按键
    if custKey > 0 then
        if input.WasKeyPressed(custKey) then
            RunConsoleCommand("+trmbase_customize")
            return true
        end
    -- 路径 B：无独立按键 → 回退到 +menu_context（右键菜单）
    else
        if bind == "+menu_context" and pressed and not ply:KeyDown(IN_USE) then
            RunConsoleCommand("+trmbase_customize")
            return true
        end
    end



    -- 阻止普通缩放行为（由武器管理系统接管）
    if bind == "+zoom" and pressed then
        RunConsoleCommand("+trmbase_cycle_firemode")
        return true
    end



    
end)


