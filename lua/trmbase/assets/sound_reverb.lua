TRMBASE = TRMBASE or {}
include("include/trmbase_sound.lua")

local allowExt = {
    "mp3", "wav", "ogg"
}

local Sounds = {
    {
        Name = "AR.Atmo",
        Pref = "weap_ar_fire_plr_atmo_ext1",
        Path = "sound/trmbase/reverberation/atmo/ar", -- 加上 sound/
        Channel = CHAN_ATMO,
    }
}

function TRMBASE.AddWeaponSound(name, pref, path, chan)
    local files, _ = file.Find(path .. "/*.*", "GAME") -- 搜索 garrysmod/ 目录

    for _, fileName in ipairs(files) do
        -- 检查扩展名
        local ext = string.GetExtensionFromFilename(fileName)
        if not table.HasValue(allowExt, string.lower(ext)) then
            continue
        end

        -- 去掉扩展名
        local baseName = string.StripExtension(fileName)

        -- 注册音效
        sound.Add({
            name = name,
            channel = chan or CHAN_AUTO,
            volume = 1.0,
            sound = path .. "/" .. baseName
        })

        print("[TRMBASE] Registered sound:", name)
    end
end

for _, c in pairs(Sounds) do
    TRMBASE.AddWeaponSound(c.Name, c.Pref, c.Path, c.Channel)
end
