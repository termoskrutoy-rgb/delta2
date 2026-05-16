TOOL.Category = "ACT"
TOOL.Name = "Скилл"

TOOL.ClientConVar["id"] = "heal"
TOOL.ClientConVar["name"] = "Heal Prayer"
TOOL.ClientConVar["desc"] = "Восстанавливает немного здоровья."
TOOL.ClientConVar["cost"] = "16"
-- Новые ConVar для интеграции с твоей ритм-системой delta2
TOOL.ClientConVar["chart"] = "default"
TOOL.ClientConVar["no_rhythm"] = "0"

if CLIENT then
    language.Add("tool.act_skill.name", "Выдача навыков")
    language.Add("tool.act_skill.desc", "ЛКМ: выдать игроку | ПКМ: выдать себе")

    function TOOL:BuildCPanel()
        self:AddControl("Header", { Description = "Настройка и выдача кастомных навыков ACT" })

        self:AddControl("ComboBox", {
            Label = "Пресеты скиллов",
            MenuButton = 1,
            Folder = "act_skills_presets", 
            CVars = {"act_skill_id", "act_skill_name", "act_skill_desc", "act_skill_cost", "act_skill_chart", "act_skill_no_rhythm"}
        })

        self:AddControl("TextBox", { Label = "ID скилла", Command = "act_skill_id" })
        self:AddControl("TextBox", { Label = "Название скилла", Command = "act_skill_name" })
        
        local label = vgui.Create("DLabel", self)
        label:SetText("Описание скилла:")
        label:SetDark(true)
        label:Dock(TOP)
        self:AddItem(label)

        local txt = vgui.Create("DTextEntry", self)
        txt:SetConVar("act_skill_desc")
        txt:SetMultiline(true) 
        txt:SetTall(100)
        txt:Dock(TOP)
        self:AddItem(txt)

        self:AddControl("TextBox", { Label = "Стоимость (%)", Command = "act_skill_cost" })

        -------------------------------------------------------------------------
        -- ИНТЕГРАЦИЯ ЧАРТОВ ИЗ ТВОЕГО РЕПОЗИТОРИЯ
        -------------------------------------------------------------------------
        -- Выпадающий список чартов, зарегистрированных в твоем cl_rhythm.lua
        local chartCombo = vgui.Create("DComboBox", self)
        chartCombo:SetConVar("act_skill_chart")
        chartCombo:Dock(TOP)
        chartCombo:DockMargin(0, 10, 0, 5)
        
        -- Считываем чарты из твоей глобальной таблицы RhythmSystem
        if RhythmSystem and RhythmSystem.Charts then
            for chartName, _ in pairs(RhythmSystem.Charts) do
                chartCombo:AddChoice(chartName, chartName)
            end
        else
            -- Дефолтные чарты из твоего мода, если таблицы еще не инициализированы в памяти
            chartCombo:AddChoice("default", "default")
            chartCombo:AddChoice("hard", "hard")
            chartCombo:AddChoice("chaos", "chaos")
        end
        chartCombo:ChooseOptionID(1)
        self:AddItem(chartCombo)

        -- Чекбокс отключения ритм-игры
        local noRhythmCheck = vgui.Create("DCheckBoxLabel", self)
        noRhythmCheck:SetText("Кастовать моментально (Без ритм-игры)")
        noRhythmCheck:SetConVar("act_skill_no_rhythm")
        noRhythmCheck:Dock(TOP)
        noRhythmCheck:DockMargin(0, 5, 0, 0)
        self:AddItem(noRhythmCheck)
    end
end

function TOOL:LeftClick(tr)
    if CLIENT then return true end
    local ent = tr.Entity
    if IsValid(ent) and ent:IsPlayer() then self:DoGive(ent) end
    return true
end

function TOOL:RightClick(tr)
    if CLIENT then return true end
    self:DoGive(self:GetOwner())
    return true
end

function TOOL:DoGive(target)
    local owner = self:GetOwner()
    if not IsValid(owner) or not IsValid(target) then return end

    local id = owner:GetInfo("act_skill_id") or "heal"
    local skillData = {
        name = owner:GetInfo("act_skill_name") or "Скилл",
        desc = owner:GetInfo("act_skill_desc") or "",
        cost = tonumber(owner:GetInfo("act_skill_cost")) or 0,
        -- Передаем настройки ритм-игры внутрь структуры скилла игрока
        chart = owner:GetInfo("act_skill_chart") or "default",
        no_rhythm = tonumber(owner:GetInfo("act_skill_no_rhythm")) or 0
    }
    
    target.ActSkillsList = target.ActSkillsList or {}
    target.ActSkillsList[id] = skillData
    
    net.Start("UpdateActSkills")
        net.WriteTable(target.ActSkillsList)
    net.Send(target)
    
    -- Скрытое оповещение для админов (чистый текст, без мусора)
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and (ply:IsAdmin() or ply:IsSuperAdmin()) then
            ply:SendLua([[
                chat.AddText(
                    Color(135, 206, 250), "]] .. owner:Nick() .. [[", 
                    Color(255, 255, 255), " выдал скилл \"", 
                    Color(255, 160, 0), "]] .. skillData.name .. [[", 
                    Color(255, 255, 255), "\" игроку ", 
                    Color(135, 206, 250), "]] .. target:Nick() .. [["
                )
            ]])
        end
    end
end