

if not CLIENT then return end 
CreateClientConVar("trmbase_cl_keybind_melee", "32", true, false, "Melee keybind")
CreateClientConVar("trmbase_cl_keybind_inspect", "19", true, false, "Inspect keybind")


local KeyVar = {
    Melee = GetConVar("trmbase_cl_keybind_melee"):GetInt() ,
    Inspect = GetConVar("trmbase_cl_keybind_inspect"):GetInt() ,
}

hook.Add("PlayerBindPress","TRMBASE_Weapon_Binds",function(ply,bind,pressed)
    local weapon = LocalPlayer():GetActiveWeapon()
    if not util.IsTRMBase(weapon) then return end
    
    if input.WasKeyPressed(KeyVar.Melee) then
        RunConsoleCommand("trmbase_melee")
    end

    if input.WasKeyPressed(KeyVar.Inspect) then
        RunConsoleCommand("trmbase_weaponinspect")
    end

    if bind == "+use" then

        if IsValid(TRM_AttachMenu_Instance) then
            TRM_AttachMenu_Instance:Close()
            return true
        end
    end

    if bind == "+menu_context"  and not ply:KeyDown(IN_USE) then
        weapon:SetCurrentTask("Customize")
        RunConsoleCommand("trmbase_customize")
        if IsValid(TRM_AttachMenu_Instance) then
            TRM_AttachMenu_Instance:Close()
        end
        return true
    end

    if bind == "+zoom" then
        return true
    end


end)  

