if SERVER then return end

TRM_ScopePiP = TRM_ScopePiP or {}

local P = TRM_ScopePiP

local function printMaterials(label, ent)
    print("[TRM ELCAN PiP] " .. label)

    if not IsValid(ent) then
        print("  invalid")
        return
    end

    print("  model: " .. tostring(ent:GetModel()))

    for index, matName in ipairs(ent:GetMaterials() or {}) do
        print("  [" .. tostring(index - 1) .. "] " .. tostring(matName))
    end
end

local function debugMaterials()
    local ply = LocalPlayer()
    local wep = IsValid(ply) and ply:GetActiveWeapon() or nil
    local vm = IsValid(ply) and ply:GetViewModel() or nil

    print("[TRM ELCAN PiP] ===== debug materials =====")
    print("[TRM ELCAN PiP] active weapon: " .. (IsValid(wep) and wep:GetClass() or "invalid"))
    print("[TRM ELCAN PiP] weapon model: " .. (IsValid(wep) and tostring(wep:GetModel()) or "invalid"))
    print("[TRM ELCAN PiP] aiming: " .. tostring(IsValid(wep) and wep.GetAimDelta and wep:GetAimDelta() or "unknown"))
    print("[TRM ELCAN PiP] elcan equipped: " .. tostring(P.HasScopeEquipped(wep)))
    print("[TRM ELCAN PiP] force test: " .. tostring(P.ForceTest == true))

    printMaterials("local viewmodel materials", vm)

    if IsValid(wep) then
        print("[TRM ELCAN PiP] current attachments:")
        for slot, entry in pairs(wep.CurrentAttachments or {}) do
            local att = entry and entry.Class and BASE_TRM_ATTS and BASE_TRM_ATTS[entry.Class]
            print("  slot " ..
                tostring(slot) .. ": " .. tostring(entry and entry.Class) .. " / " .. tostring(att and att.Name))
        end
    end

    local entry, att, slot = P.GetScopeAttachmentEntry(wep)
    print("[TRM ELCAN PiP] elcan slot: " .. tostring(slot))

    if entry and IsValid(entry.m_Model) then
        printMaterials("elcan accessory model materials", entry.m_Model)
        local lensIndex, lensMat = P.FindLensIndex(entry.m_Model, att)
        print("[TRM ELCAN PiP] detected lens index: " .. tostring(lensIndex))
        print("[TRM ELCAN PiP] detected lens material: " .. tostring(lensMat))
    else
        print("[TRM ELCAN PiP] no active elcan clientside model")
    end

    print("[TRM ELCAN PiP] ===== end debug =====")
end

local function forceTest(_, _, args)
    local enabled = tonumber(args and args[1] or "0") == 1
    P.ForceTest = enabled

    if not enabled and IsValid(P.ActiveModel) then
        P.ResetModel(P.ActiveModel)
    end

    print("[TRM ELCAN PiP] force test = " .. tostring(enabled))
end

concommand.Add("youraddon_pip_debug_materials", debugMaterials)
concommand.Add("trmbase_pip_debug_materials", debugMaterials)
concommand.Add("youraddon_pip_force_test", forceTest)
concommand.Add("trmbase_pip_force_test", forceTest)
