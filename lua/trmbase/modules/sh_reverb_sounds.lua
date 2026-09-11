local function AddSound(name, path, channel)
    sound.Add({
        name = name,
        sound = path,
        channel = channel,
        level = 6000,
    })
end

AddSound("TRM.Reflection.AR.InDoor", { "trmbase/reverb/reflection/ar/AR_Refl_Indoor_Close_3P.wav" }, CHAN_REFLECTION)

AddSound("TRM.Reflection.AR.OutDoor",
    { "trmbase/reverb/reflection/ar/Wpn_AR_Refl_Cls_01.wav",
        "trmbase/reverb/reflection/ar/Wpn_AR_Refl_Cls_02.wav",
        "trmbase/reverb/reflection/ar/Wpn_AR_Refl_Cls_03.wav",
        "trmbase/reverb/reflection/ar/Wpn_AR_Refl_Cls_04.wav",
        "trmbase/reverb/reflection/ar/Wpn_AR_Refl_Cls_05.wav",
        "trmbase/reverb/reflection/ar/Wpn_AR_Refl_Cls_06.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.BR.InDoor",
    { "trmbase/reverb/reflection/br/BR_Refl_InDoor_Cls.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.BR.OutDoor",
    { 
        "trmbase/reverb/reflection/br/Wpn_BR_Refl_Cls_01.wav",
        "trmbase/reverb/reflection/br/Wpn_BR_Refl_Cls_02.wav",
        "trmbase/reverb/reflection/br/Wpn_BR_Refl_Cls_03.wav",
        "trmbase/reverb/reflection/br/Wpn_BR_Refl_Cls_04.wav",
        "trmbase/reverb/reflection/br/Wpn_BR_Refl_Cls_05.wav",
        "trmbase/reverb/reflection/br/Wpn_BR_Refl_Cls_06.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.DMR.OutDoor",
    {
        "trmbase/reverb/reflection/dmr/Wpn_SR_Refl_Ext_Cls_01.wav",
        "trmbase/reverb/reflection/dmr/Wpn_SR_Refl_Ext_Cls_02.wav",
        "trmbase/reverb/reflection/dmr/Wpn_SR_Refl_Ext_Cls_03.wav",
        "trmbase/reverb/reflection/dmr/Wpn_SR_Refl_Ext_Cls_04.wav",
        "trmbase/reverb/reflection/dmr/Wpn_SR_Refl_Ext_Cls_05.wav",
        "trmbase/reverb/reflection/dmr/Wpn_SR_Refl_Ext_Cls_06.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.DMR.InDoor",
    {
        "trmbase/reverb/reflection/dmr/Wpn_SR_ReflI_InDoor_Cls.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.Pistol.OutDoor",
    {
        "trmbase/reverb/reflection/pistol/Wpn_PI_Refl_Cls_01.wav",
        "trmbase/reverb/reflection/pistol/Wpn_PI_Refl_Cls_02.wav",
        "trmbase/reverb/reflection/pistol/Wpn_PI_Refl_Cls_03.wav",
        "trmbase/reverb/reflection/pistol/Wpn_PI_Refl_Cls_04.wav",
        "trmbase/reverb/reflection/pistol/Wpn_PI_Refl_Cls_05.wav",
        "trmbase/reverb/reflection/pistol/Wpn_PI_Refl_Cls_06.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.Pistol.InDoor",
    {
        "trmbase/reverb/reflection/pistol/Wpn_PT2_Refl_Int_Large_LR_01.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.Shotgun.OutDoor",
    {
        "trmbase/reverb/reflection/shotgun/Wpn_SG_Refl_Cls_01.wav",
        "trmbase/reverb/reflection/shotgun/Wpn_SG_Refl_Cls_02.wav",
        "trmbase/reverb/reflection/shotgun/Wpn_SG_Refl_Cls_03.wav",
        "trmbase/reverb/reflection/shotgun/Wpn_SG_Refl_Cls_04.wav",
        "trmbase/reverb/reflection/shotgun/Wpn_SG_Refl_Cls_05.wav",
        "trmbase/reverb/reflection/shotgun/Wpn_SG_Refl_Cls_06.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.Shotgun.InDoor",
    {
        "trmbase/reverb/reflection/shotgun/Wpn_SG2_Refl_Int_Large_LR_Molinare_1.wav",
    },
    CHAN_REFLECTION)


AddSound("TRM.Reflection.SMG.OutDoor",
    {
        "trmbase/reverb/reflection/smg/Wpn_SMG_Refl_Cls_01.wav",
        "trmbase/reverb/reflection/smg/Wpn_SMG_Refl_Cls_02.wav",
        "trmbase/reverb/reflection/smg/Wpn_SMG_Refl_Cls_03.wav",
        "trmbase/reverb/reflection/smg/Wpn_SMG_Refl_Cls_04.wav",
        "trmbase/reverb/reflection/smg/Wpn_SMG_Refl_Cls_05.wav",
        "trmbase/reverb/reflection/smg/Wpn_SMG_Refl_Cls_06.wav",
    },
    CHAN_REFLECTION)

AddSound("TRM.Reflection.SMG.InDoor",
    {
        "trmbase/reverb/reflection/smg/SMG_Refl_Indoor_Cls_3P.wav",
    },
    CHAN_REFLECTION)
