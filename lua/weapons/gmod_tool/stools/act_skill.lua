TOOL.Category = "ACT"
TOOL.Name = "Скилл"
TOOL.ClientConVar["id"] = "defense"
TOOL.ClientConVar["name"] = "Защита"
TOOL.ClientConVar["desc"] = "Уменьшает получаемый урон в зависимости от вашего значения ЗЩТ. Повышает ПОТОК на 16%"
TOOL.ClientConVar["cost"] = "0"

if CLIENT then
    language.Add("tool.act_skill.name", "Выдача навыков")
    language.Add("tool.act_skill.desc", "ЛКМ: выдать игроку | ПКМ: выдать себе")

    function TOOL:BuildCPanel()
        -- 1. Заголовок
        self:AddControl("Header", { Description = "Настройка навыка" })

        -- 2. ПРЕСЕТЫ (Теперь с плюсиком)
        -- Folder: "act_skills" — это папка в garrysmod/settings/presets/act_skills
        self:AddControl("ComboBox", {
            Label = "Пресеты скиллов",
            MenuButton = 1, -- Это активирует кнопку управления (плюсик/меню)
            Folder = "act_skills", 
            Options = {
                ["Защита"] = {
                    act_skill_id = "defense",
                    act_skill_name = "Защита",
                    act_skill_desc = "Уменьшает получаемый урон в зависимости от значения ЗЩТ. Повышает ПОТОК на 16%",
                    act_skill_cost = "0"
                }
            },
            CVars = {
                "act_skill_id",
                "act_skill_name",
                "act_skill_desc",
                "act_skill_cost"
            }
        })

        -- 3. Поля ввода
        self:AddControl("TextBox", { Label = "ID (технический)", Command = "act_skill_id" })
        self:AddControl("TextBox", { Label = "Название", Command = "act_skill_name" })
        
        -- 4. Увеличенное поле для описания
        local label = vgui.Create("DLabel", self)
        label:SetText("Описание скилла:")
        label:SetDark(true)
        label:Dock(TOP)
        label:DockMargin(10, 5, 10, 0)
        self:AddItem(label)

        local txt = vgui.Create("DTextEntry", self)
        txt:SetConVar("act_skill_desc")
        txt:SetMultiline(true) 
        txt:SetTall(100) -- Сделал чуть повыше для удобства
        txt:SetPlaceholderText("Введите описание здесь...")
        txt:Dock(TOP)
        txt:DockMargin(10, 0, 10, 5)
        self:AddItem(txt)

        -- 5. Стоимость
        self:AddControl("TextBox", { Label = "Стоимость (число)", Command = "act_skill_cost" })
    end
end

-- Остальная часть (GiveSkill, LeftClick, RightClick) остается без изменений
local function GiveSkill(target, owner, id, data)
    if not IsValid(target) or not target:IsPlayer() then return end
    
    target.ActSkillsList = target.ActSkillsList or {}
    target.ActSkillsList[id] = data

    net.Start("UpdateActSkills")
        net.WriteTable(target.ActSkillsList)
    net.Send(target)
end

function TOOL:LeftClick(tr)
    if CLIENT then return true end
    if not (IsValid(tr.Entity) and tr.Entity:IsPlayer()) then return false end
    
    local o = self:GetOwner()
    local id = o:GetInfo("act_skill_id")
    local skillData = {
        name = o:GetInfo("act_skill_name"),
        desc = o:GetInfo("act_skill_desc"),
        cost = tonumber(o:GetInfo("act_skill_cost")) or 0
    }
    
    GiveSkill(tr.Entity, o, id, skillData)
    o:ChatPrint("Вы выдали навык '" .. skillData.name .. "' игроку " .. tr.Entity:Nick())
    return true
end

function TOOL:RightClick(tr)
    if CLIENT then return true end
    local o = self:GetOwner()
    local id = o:GetInfo("act_skill_id")
    local skillData = {
        name = o:GetInfo("act_skill_name"),
        desc = o:GetInfo("act_skill_desc"),
        cost = tonumber(o:GetInfo("act_skill_cost")) or 0
    }
    
    GiveSkill(o, o, id, skillData)
    o:ChatPrint("Вы выдали навык '" .. skillData.name .. "' себе")
    return true
end