-- 配件模板 他们应该被放在  lua/trmbase/attachments/ 目录下 支持次级目录
-- Base配件 其他配件可以以这个为基础进行修改 你也可以创建自己的Base配件来让其他配件以它为基础
-- 你可以在这个文件里定义一个配件的属性 通过修改这些属性
-- 以下配件如果用了特定功能，需要给上一个ATTACHMENT.Base = "att_base" 来继承这个Base配件 这样就能让这个配件拥有Base配件的功能了
ATTACHMENT.Name = "att_base" --配件名字 这个会显示在配件栏里 可以本地化，vgui里已经有GetPhrase了
ATTACHMENT.Category = nil --配件分类 这个决定了这个配件可以安装在哪些槽位上 你可以在武器的Attachments里定义一个槽位的Category来让它能安装对应分类的配件
ATTACHMENT.Selectable = true --是否能被玩家选择安装 有些配件可能只是用来修改武器属性或者被其他配件调用的 这种配件就不需要Selectable

ATTACHMENT.Description = nil --还没做 

-- 渲染相关字段
ATTACHMENT.Model = nil     -- 模型路径
ATTACHMENT.Bonemerge = nil -- true(默认) = EF_BONEMERGE跟随动画, false = FollowBone+偏移 如果是武器专有配件可以用

ATTACHMENT.Pos = Vector(0, 0, 0) --模型位置偏移 如果Bonemerge为false则这个位置是相对于Bone的偏移 如果Bonemerge为true则这个位置是相对于配件安装时的骨骼位置的偏移
ATTACHMENT.Angles = Angle(0, 0, 0) --模型角度偏移 如果Bonemerge为false则这个角度是相对于Bone的偏移 如果Bonemerge为true则这个角度是相对于配件安装时的骨骼位置的偏移


--Laser 配件相关字段 你可以定义一个Laser字段来让这个配件在渲染时自动帮你画出激光 具体的渲染逻辑在trmbase里已经写好了 你只需要定义这个字段并设置好参数就行了

ATTACHMENT.Laser = {  --激光相关设置 att_laser可以通过定义这个字段来让它在渲染时自动帮你画出激光
    Attach = "Laser",
    Color = Color(255, 0, 0, 197),
    Width = 1,
    DotSize = 4,
}

-- 材质缓存（放在配件表上，不是 self） 激光的材质
local lineMat = nil
local dotMat = nil

function ATTACHMENT:GetLineMat()
    if not lineMat then
        lineMat = Material("sprites/physbeam")
    end
    return lineMat
end

function ATTACHMENT:GetDotMat()
    if not dotMat then
        dotMat = CreateMaterial("trmbase_laserdot", "UnLitGeneric", {
            ["$basetexture"] = "sun/overlay",
            ['$additive'] = 1,
            ['$vertexalpha'] = 1,
            ['$vertexcolor'] = 1,
        })
    end
    return dotMat
end

--Global
function ATTACHMENT:ChangeWeaponStats(weapon)
    --在这里修改武器属性 这个函数会在配件安装和卸载时调用

end
--Reticle 配件相关字段 你可以定义一个Sight字段来让这个配件在渲染时自动帮你画出准星 具体的渲染逻辑在trmbase里已经写好了 你只需要定义这个字段并设置好参数就行了
ATTACHMENT.Sight = {
    Pos = Vector(0.00, 0, -0.45), --准星位置偏移 这个位置是相对于玩家视角的偏移 你可以调整这个位置来让视角对准准星
    Align = "reticle", --准星对齐方式的附件名字
    Material = Material(), --准星材质 你可以在这里设置一个材质来让这个配件显示一个准星 如果不设置或者设置为nil则不会显示准星
    Size = 2.56, --准星大小 这个值会乘以屏幕高度来计算准星的实际大小 你可以调整这个值来让准星变大或者变小
    Color = Color(255, 0, 0), --准星颜色 这个颜色会乘以材质的颜色来计算准星的实际颜色 你可以调整这个颜色来让准星变成不同的颜色
    HideMaterial = { 2 }, --还没做好 这个字段是一个材质索引的表 你可以在这里设置一些材质索引来让这个配件安装时自动隐藏武器模型上的某些材质 例如你可以用它来隐藏原本的准星材质来避免和新的准星重叠 你需要知道你要隐藏的材质在模型里的索引才能使用这个功能
    Rotate = 90, --准星旋转 这个值是准星的旋转角度 你可以调整这个值来让准星旋转到不同的角度
}
function ATTACHMENT:Render(weapon, model) --渲染的函数 这个函数会在配件安装时调用 model是配件的模型 你可以通过修改model来改变它的外观 例如调整位置或者隐藏某些子模型等    
    model:DrawModel() 
end


function ATTACHMENT:ScaleTableValue(tableData, mul) --这个函数可以用来递归地调整一个表里所有数值的大小 例如你可以用它来成比例地调整一个配件对武器属性的影响
    if not tableData then return end
    for key, val in pairs(tableData) do
        if istable(val) then
            self:ScaleTableValue(val, mul)
        else
            tableData[key] = val * mul -- ✅ 直接修改原表的值
        end
    end
end

function ATTACHMENT:Remove(weapon, model) --卸载时的函数 这个函数会在配件卸载时调用 model是配件的模型 你可以通过修改model来改变它的外观 例如调整位置或者隐藏某些子模型等
    model:Remove()
end

--
