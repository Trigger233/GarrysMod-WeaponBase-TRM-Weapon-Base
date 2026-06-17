AddCSLuaFile()

local _path = "trmbase/assets"

local function LoadAssetFiles(path)
    local files, folders = file.Find(path .. "/*", "LUA")

    for _, file in ipairs(files) do
        local fullPath = path .. "/" .. file
        AddCSLuaFile(fullPath)
        include(fullPath)
        
    end

    for _, folder in ipairs(folders) do
        LoadAssetFiles(path .. "/" .. folder) -- 修复：加斜杠 + 用 folder
    end
end

LoadAssetFiles(_path)