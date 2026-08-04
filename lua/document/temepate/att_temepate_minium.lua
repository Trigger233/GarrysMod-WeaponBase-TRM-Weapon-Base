ATTACHMENT.Base = "att_base" --配件的基础配件 这个配件会继承基础配件的属性和功能 你可以在这里设置一个基础配件的名字来让这个配件继承它的属性和功能 如果不设置或者设置为nil则不会继承任何基础配件
ATTACHMENT.Name = "Attachment Name"
ATTACHMENT.Category = nil --配件分类 这个决定了这个配件可以安装在哪些槽位上 你可以在武器的Attachments里定义一个槽位的Category来让它能安装对应分类的配件
ATTACHMENT.Bonemerge = nil -- true(默认) = EF_BONEMERGE跟随动画, false = FollowBone+偏移 如果是武器专有配件可以用

function ATTACHMENT:Stats(weapon) --在这里修改武器属性 这个函数会在配件安装时调用
    
end