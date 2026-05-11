if not CLIENT then return end

hook.Add("PopulateToolMenu","TRM_weapon_base_q_menu",function()
    spawnmenu.AddToolMenuOption("TriggerMiku_Work","WeaponBase","trmbase_admin","Admin","","",function(panel)
        panel:ClearControls()
        panel:CheckBox("Infinite reserve Ammo","trmbase_infinite_ammo")
        panel:CheckBox("Auto Reload","trmbase_autoreload")

        
    end)
    spawnmenu.AddToolMenuOption("TriggerMiku_Work","WeaponBase","trmbase_client","Client","","",function(panel)
        panel:ClearControls()
        panel:KeyBinder("Melee","trmbase_cl_keybind_melee")
        panel:KeyBinder("Inspect","trmbase_cl_keybind_inspect")
        panel:CheckBox("Crosshair","trmbase_crosshair_enable")
        panel:ColorPicker("Crosshair color","trmbase_crosshair_color_r","trmbase_crosshair_color_g","trmbase_crosshair_color_b","trmbase_crosshair_color_a")
        panel:NumSlider("CrossHair Style","trmbase_crosshair_style",1,3,0)
        panel:CheckBox("CrossHair Dot","trmbase_crosshair_dot")
        panel:CheckBox("Hide HUD When Inspect","trmbase_hidehud_inspect")
    end)

    
end)