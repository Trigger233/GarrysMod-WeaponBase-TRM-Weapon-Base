-- lua/trmbase/modules/trm_input.lua
local TRM_Input = {}

TRM_Input.Binds = {}
TRM_Input.BindStates = {}
TRM_Input.DoubleTapPending = {}
TRM_Input._comboTriggered = {}

-- ========== 核心功能 ==========

-- 注册绑定
function TRM_Input.RegisterBind(bindName, bindCmd, mode, callback)
    TRM_Input.Binds[bindName] = {
        cmd = bindCmd,
        mode = mode,
        callback = callback
    }
end

-- 更新 bind 命令的状态
function TRM_Input.UpdateBind(bindCmd, isDown)
    local state = TRM_Input.BindStates[bindCmd]
    if not state then
        state = {
            LastPress = 0,
            LastRelease = 0,
            PressCount = 0,
            IsDown = false
        }
        TRM_Input.BindStates[bindCmd] = state
    end

    local now = CurTime()

    if isDown and not state.IsDown then
        state.LastPress = now
        state.PressCount = state.PressCount + 1
    elseif not isDown and state.IsDown then
        state.LastRelease = now
    end

    state.IsDown = isDown
end

-- 处理单击/双击/组合的触发
function TRM_Input.HandleBind(bindName, bind, isDown)
    local mode = bind.mode
    local cmd = bind.cmd

    if mode == "single" and not isDown then
        local state = TRM_Input.BindStates[cmd]
        if state and state.PressCount == 1 then
            local pressDuration = state.LastRelease - state.LastPress
            if pressDuration < 0.25 and pressDuration > 0 then
                bind.callback()
                state.PressCount = 0
            end
        end
    elseif mode == "double" and isDown then
        local state = TRM_Input.BindStates[cmd]
        if state then
            local now = CurTime()
            if state.PressCount == 2 and now - state.LastPress <= 0.3 then
                bind.callback()
                state.PressCount = 0
            end
        end
    elseif mode == "combo" and isDown then
        if type(cmd) == "table" and #cmd == 2 then
            local state1 = TRM_Input.BindStates[cmd[1]]
            local state2 = TRM_Input.BindStates[cmd[2]]
            if state1 and state2 and state1.IsDown and state2.IsDown then
                local comboKey = cmd[1] .. "_" .. cmd[2]
                if not TRM_Input._comboTriggered[comboKey] then
                    TRM_Input._comboTriggered[comboKey] = true
                    bind.callback()
                end
            else
                local comboKey = cmd[1] .. "_" .. cmd[2]
                TRM_Input._comboTriggered[comboKey] = false
            end
        end
    end
end

-- ========== Spawnmenu 绑定器 ==========

-- 添加单键绑定（占一整行）
-- lua/trmbase/modules/trm_input.lua

-- 辅助函数：命令名转键码
function TRM_Input.CommandToKeyCode(cmd)
    if not cmd or cmd == "" then return 0 end
    -- 直接返回 input.GetKeyCode，如果是 "+xxx" 格式需要特殊处理
    if string.sub(cmd, 1, 1) == "+" then
        -- "+reload" 这种命令，需要查绑定
        local key = input.LookupBinding(cmd)
        if key then
            return input.GetKeyCode(key)
        end
        return 0
    else
        -- "v" 这种直接转换
        return input.GetKeyCode(cmd) or 0
    end
end

-- 辅助函数：键码转命令名
function TRM_Input.KeyCodeToCommand(keyCode)
    if keyCode <= 0 then return "" end
    local keyName = input.GetKeyName(keyCode)
    if not keyName then return "" end
    -- 尝试查找绑定命令
    local bind = input.LookupBinding(keyName)
    if bind then return bind end
    -- 如果没有绑定，返回键名本身
    return keyName
end

-- 添加单键绑定（转换默认命令名为键码）
function TRM_Input.AddKeyBinder(panel, label, convar, defaultCmd)
    if not panel.KeyBinder then return end
    local defaultKeyCode = TRM_Input.CommandToKeyCode(defaultCmd)
    CreateClientConVar(convar, tostring(defaultKeyCode), true, false)
    panel:KeyBinder(label, convar)
end

-- 添加双键绑定
function TRM_Input.AddDoubleKeyBinder(panel, label1, convar1, default1, label2, convar2, default2)
    if not panel.KeyBinder then return end

    local defaultKeyCode1 = TRM_Input.CommandToKeyCode(default1)
    local defaultKeyCode2 = TRM_Input.CommandToKeyCode(default2)

    CreateClientConVar(convar1, tostring(defaultKeyCode1), true, false)
    CreateClientConVar(convar2, tostring(defaultKeyCode2), true, false)

    local row = panel:CreatePanel("Panel")
    row:SetSize(panel:GetWide(), 30)
    row:SetPaintBackground(false)

    local left = row:CreatePanel("Panel")
    left:SetSize(panel:GetWide() / 2 - 5, 30)
    left:SetPaintBackground(false)
    left:KeyBinder(label1, convar1)

    local right = row:CreatePanel("Panel")
    right:SetSize(panel:GetWide() / 2 - 5, 30)
    right:SetPos(panel:GetWide() / 2 + 5, 0)
    right:SetPaintBackground(false)
    right:KeyBinder(label2, convar2)
end

-- 添加所有绑定
function TRM_Input.AddAllBinder(panel)
    if not panel.KeyBinder then return end

    TRM_Input.AddKeyBinder(panel, "TRMBase_MeleeKey", "trmbase_cl_keybind_melee", "v")
    TRM_Input.AddKeyBinder(panel, "TRMBase_InspectKey", "trmbase_cl_keybind_inspect", "r")
    TRM_Input.AddKeyBinder(panel, "TRMBase_CustomizeKey", "trmbase_cl_keybind_customize", "c")

    TRM_Input.AddDoubleKeyBinder(panel,
        "TRMBase_UnderBarrelKey", "trmbase_cl_keybind_ub", "+reload",
        "TRMBase_FiremodeKey", "trmbase_cl_keybind_firemode", "v"
    )
end

return TRM_Input
 