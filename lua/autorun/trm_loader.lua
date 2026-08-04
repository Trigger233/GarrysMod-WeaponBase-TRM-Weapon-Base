if SERVER then
    AddCSLuaFile()
end

TRMWeaponBase = TRMWeaponBase or {}   

BASE_TRM_ATTS = BASE_TRM_ATTS or {}
TRM_BASE_REF = 69

local function LoadAttachmentStats(path, fileName)
    local name = string.Replace(fileName, ".lua", "")
    local fullPath = path .. "/" .. fileName

    if SERVER then
        AddCSLuaFile(fullPath)  
    end

    local func = CompileFile(fullPath)
    if not func then
        print("[TRMAtt] Failed to load:", fullPath)
        return
    end

    ATTACHMENT = {}
    ATTACHMENT.ClassName = name
    ATTACHMENT.Folder = path
    ATTACHMENT.Path = fullPath

    func()

    BASE_TRM_ATTS[name] = BASE_TRM_ATTS[name] or {}
    table.Merge(BASE_TRM_ATTS[name], table.Copy(ATTACHMENT))
end



local function LoadAttachments(path)
    local files, folders = file.Find(path .. "/*", "LUA")
    for _, fileName in ipairs(files) do
        if string.EndsWith(fileName, ".lua") then
            LoadAttachmentStats(path, fileName)
        end
    end

    for _, folderName in ipairs(folders) do
        LoadAttachments(path .. "/" .. folderName)
    end
end



local function inherit(current, base)
    for k, v in pairs(base) do
        if not istable(v) then
            if current[k] == nil then
                current[k] = v
            end
        else
            if current[k] == nil then
                current[k] = {}
            end
            inherit(current[k], v)
        end
    end
end

function TRMWeaponBase.Inherit(att)
    local baseClass = BASE_TRM_ATTS[att.Base]
    while baseClass do
        if baseClass == att.ClassName then
            break
        end

        inherit(att, baseClass)
        baseClass = BASE_TRM_ATTS[baseClass.Base]
    end
end

local function finishAttachments()
    for name, att in pairs(BASE_TRM_ATTS) do
        if type(att) ~= "table" then
            print("[TRMAtt] Skipping non-table:", name, type(att))
            continue
        end
        if att.Base then
            TRMWeaponBase.Inherit(att)
        end
    end 
end
local function Load()
    LoadAttachments("trmbase/attachments")
    LoadAttachments("trmbase/att")
    finishAttachments()
    
    for _ , ent in ents.Iterator() do
        if ent:IsWeapon() and ent.BuildCustomizedGun then
            ent:BuildCustomizedGun()
        end
    end
end

Load() 
 
AddCSLuaFile("includes/modules/trm_input.lua")

CHAN_ATMO = 137
CHAN_REFLECTION = 138
CHAN_CASINGS = 139
CHAN_TRIGGER = 140
CHAN_MINIGUNFIRE = 141
CHAN_MAGAZINEDROP = 142
CHAN_WPNFOLEY = 143

AddCSLuaFile("include/rndx.lua")
function TRMWeaponBase.GetRNDX()
    return include("include/rndx.lua")
end
