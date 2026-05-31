if SERVER then
    AddCSLuaFile()
end

BASE_TRM_INJECTOR = BASE_TRM_INJECTOR or {}



local function LoadInjectorStat(path, fileName)
    local name = string.Replace(fileName, ".lua", "")
    local fullPath = path .. "/" .. fileName

    if SERVER then
        AddCSLuaFile(fullPath)
    end

    local c = CompileFile(fullPath)
    if not c then
        print("[TRMAtt] Failed to load:", fullPath)
        return
    end

    INJECTOR = {}
    INJECTOR.ClassName = name
    INJECTOR.Folder = path

    c()

    BASE_TRM_INJECTOR[name] = BASE_TRM_INJECTOR[name] or {}

    table.Merge(BASE_TRM_INJECTOR[name], table.Copy(INJECTOR))
end
local function LoadInjector(path)
    local files, folders = file.Find(path .. "/*", "LUA")
    print("Loading Injector ")
    for _, fileName in ipairs(files) do
        if string.EndsWith(fileName, ".lua") then
            LoadInjectorStat(path, fileName)
        end
    end

    for _, folderName in ipairs(folders) do
        LoadInjector(path .. "/" .. folderName)
    end
end
local injectorPath = "trmbase/injectors"
LoadInjector(injectorPath)

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

function BASE_TRM_INJECTOR.Inherit(injector)
    local baseclass = BASE_TRM_INJECTOR[injector.Base]
    while baseclass do
        inherit(injector, baseclass)
        baseclass = BASE_TRM_INJECTOR[baseclass.Base]
    end
end

local function finishInjectors()
    for name, injector in pairs(BASE_TRM_INJECTOR) do
        if type(injector) == "table" and injector.Base then
            BASE_TRM_INJECTOR.Inherit(injector)
        end
    end
end
finishInjectors()

hook.Add("OnReloaded", "TRMBASE_INJECTOR_RELOAD", function()
    LoadInjector(injectorPath)
    finishInjectors()
    PrintTable(BASE_TRM_INJECTOR)
end)

concommand.Add("print_trm_injector", function()
    PrintTable(BASE_TRM_INJECTOR)
end)


hook.Add("PreRegisterSWEP", "TRMBASE_INJECTOR_SWEP", function(weapon, class)
    if not util.IsTRMBase(weapon) then return end
    for _, injector in pairs(BASE_TRM_INJECTOR) do
        if injector.DoInjector then
            injector:DoInjector(weapon, class)
        end
    end
end)
