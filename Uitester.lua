--Ui show cases
--https://www.roblox.com/fr/games/81535567274521/Bee-Garden

-- ════════════════════════════════════════════════════════════════════════════
--  Bee Script — Présentation complète VoidUI v3.0
-- ════════════════════════════════════════════════════════════════════════════
local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/femmehomme90-web/VoidUI/refs/heads/main/voidUI.lua"))()
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")

local player      = Players.LocalPlayer
local purchaseRemote = ReplicatedStorage.Events.PurchaseConveyorEgg

-- ════════════════════════════════════════════════════════════════════════════
--  DÉTECTION DU PLOT
-- ════════════════════════════════════════════════════════════════════════════
local plots       = workspace.Core.Scriptable.Plots
local playerPlot  = nil
local playerPlotId = nil

for i = 1, 5 do
    local plot = plots[tostring(i)]
    if plot then
        local honeyPot = plot:FindFirstChild("HoneyPot")
        if honeyPot and honeyPot:GetAttribute("OwnerName") == player.Name then
            playerPlot   = plot
            playerPlotId = tostring(i)
            break
        end
    end
end

if not playerPlot then
    VoidUI:Notify({ Title = "Bee Script", Message = "Aucun plot trouvé !", Type = "error", Duration = 4 })
    return
end

-- ════════════════════════════════════════════════════════════════════════════
--  ÉTAT GLOBAL DU SCRIPT
-- ════════════════════════════════════════════════════════════════════════════
local State = {
    autoBuy       = false,
    autoFarm      = false,
    walkSpeed     = 16,
    buyDelay      = 0.7,
    selectedEggs  = {},
    eggsBought    = 0,
    honeyCollected = 0,
    farmMode      = "Safe",
    uiColor       = Color3.fromRGB(130, 80, 255),
}

-- ════════════════════════════════════════════════════════════════════════════
--  FENÊTRE PRINCIPALE
-- ════════════════════════════════════════════════════════════════════════════
local Window = VoidUI:CreateWindow({
    Title       = "Bee Script",
    Size        = UDim2.new(0, 580, 0, 460),
    TabPosition = "top",
})

-- ════════════════════════════════════════════════════════════════════════════
--  ONGLET 1 — EGGS
-- ════════════════════════════════════════════════════════════════════════════
local TabEggs = Window:AddTab("Eggs")

local iconList = player.PlayerGui.Main.Frames.Conveyor.ConveyorInfo.InfoFrame.List

local function getItems()
    local items = {}
    for _, frame in ipairs(iconList:GetChildren()) do
        if frame:IsA("Frame") and frame.Name ~= "Template" then
            local icon = frame:FindFirstChild("Icon", true)
            table.insert(items, {
                Name = frame.Name,
                Icon = icon and icon.Image or "",
            })
        end
    end
    return items
end

-- Référence au CardGrid pour pouvoir le recréer au refresh
local cardGrid = nil

local function refreshEggs()
    State.selectedEggs = {}
    TabEggs:Clear()

    TabEggs:AddLabel("Oeufs disponibles")

    cardGrid = TabEggs:AddCardGrid({
        Items    = getItems(),
        Columns  = 3,
        Callback = function(selected)
            State.selectedEggs = selected
            local count = 0
            for _ in pairs(selected) do count = count + 1 end
            VoidUI:Notify({
                Title    = "Sélection",
                Message  = count .. " oeuf(s) sélectionné(s)",
                Type     = "info",
                Duration = 1.5,
            })
        end,
    })

    TabEggs:AddButton({
        Label    = "Actualiser la liste",
        Colors   = { Color3.fromRGB(130, 80, 255), Color3.fromRGB(220, 80, 160) },
        Callback = function()
            refreshEggs()
            VoidUI:Notify({
                Title    = "Bee Script",
                Message  = "Liste des oeufs mise à jour !",
                Type     = "info",
                Duration = 2,
            })
        end,
    })
end

refreshEggs()

-- ════════════════════════════════════════════════════════════════════════════
--  ONGLET 2 — AUTO FARM
-- ════════════════════════════════════════════════════════════════════════════
local TabFarm = Window:AddTab("Farm")

TabFarm:AddLabel("Automatisation")

-- Toggle Auto-Buy
local toggleBuy = TabFarm:AddToggle({
    Label    = "Auto-Buy Eggs",
    Default  = false,
    Callback = function(v)
        State.autoBuy = v
        VoidUI:Notify({
            Title    = "Auto-Buy",
            Message  = v and "Activé sur le plot " .. playerPlotId or "Désactivé",
            Type     = v and "success" or "warning",
            Duration = 2,
        })
    end,
})

-- Toggle Auto-Farm Honey
local toggleFarm = TabFarm:AddToggle({
    Label    = "Auto-Farm Honey",
    Default  = false,
    Callback = function(v)
        State.autoFarm = v
        VoidUI:Notify({
            Title    = "Auto-Farm",
            Message  = v and "Récolte automatique activée !" or "Récolte arrêtée",
            Type     = v and "success" or "warning",
            Duration = 2,
        })
    end,
})

TabFarm:AddLabel("Paramètres de vitesse")

-- Slider Walk Speed
TabFarm:AddSlider({
    Label    = "Walk Speed",
    Min      = 16,
    Max      = 100,
    Default  = 16,
    Suffix   = " st/s",
    Callback = function(v)
        State.walkSpeed = v
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = v
        end
    end,
})

-- Slider Délai entre achats
TabFarm:AddSlider({
    Label    = "Délai achat (ms)",
    Min      = 3,
    Max      = 20,
    Default  = 7,
    Suffix   = "00ms",
    Callback = function(v)
        State.buyDelay = v / 10
    end,
})

TabFarm:AddLabel("Mode de farm")

-- Dropdown Mode
TabFarm:AddDropdown({
    Label    = "Mode",
    Options  = { "Safe", "Fast", "Aggressive" },
    Callback = function(v)
        State.farmMode = v
        local types = { Safe = "info", Fast = "warning", Aggressive = "error" }
        VoidUI:Notify({
            Title    = "Mode sélectionné",
            Message  = "Farm en mode : " .. v,
            Type     = types[v] or "info",
            Duration = 2,
        })
    end,
})

-- MultiToggle options de farm
TabFarm:AddMultiToggle({
    Label    = "Options avancées",
    Options  = { "Skip Common", "Priorité Légendaires", "Anti-AFK", "Log achats" },
    Callback = function(selected)
        local list = {}
        for k in pairs(selected) do table.insert(list, k) end
        -- options actives mises à jour silencieusement
    end,
})

-- ════════════════════════════════════════════════════════════════════════════
--  ONGLET 3 — STATS
-- ════════════════════════════════════════════════════════════════════════════
local TabStats = Window:AddTab("Stats")

TabStats:AddLabel("Statistiques de session")

-- Barre de progression oeufs achetés
local progressBuy = TabStats:AddProgressBar({
    Label  = "Oeufs achetés",
    Value  = 0,
    Max    = 50,
    Suffix = " / 50",
})

-- Barre de progression honey collecté
local progressHoney = TabStats:AddProgressBar({
    Label  = "Honey collecté",
    Value  = 0,
    Max    = 1000,
    Suffix = " ml",
})

TabStats:AddLabel("Infos du plot")

-- TextInput pour tag personnalisé
local inputTag = TabStats:AddTextInput({
    Label       = "Tag du plot",
    Placeholder = "ex: Main Farm, Test...",
    Callback    = function(v)
        VoidUI:Notify({
            Title    = "Tag enregistré",
            Message  = '"' .. v .. '" — Plot ' .. playerPlotId,
            Type     = "success",
            Duration = 2,
        })
    end,
})

TabStats:AddLabel("Réinitialisation")

-- Bouton reset stats
TabStats:AddButton({
    Label    = "Remettre les stats à zéro",
    Callback = function()
        State.eggsBought    = 0
        State.honeyCollected = 0
        progressBuy:SetValue(0)
        progressHoney:SetValue(0)
        VoidUI:Notify({
            Title    = "Stats réinitialisées",
            Message  = "Compteurs remis à zéro.",
            Type     = "warning",
            Duration = 2,
        })
    end,
})

-- ════════════════════════════════════════════════════════════════════════════
--  ONGLET 4 — PARAMÈTRES
-- ════════════════════════════════════════════════════════════════════════════
local TabSettings = Window:AddTab("Paramètres")

TabSettings:AddLabel("Interface")

-- Color Picker couleur d'accent (cosmétique demo)
TabSettings:AddColorPicker({
    Label    = "Couleur personnelle",
    Default  = Color3.fromRGB(130, 80, 255),
    Callback = function(c)
        State.uiColor = c
    end,
})

-- Keybind pour toggle de l'UI
TabSettings:AddKeybind({
    Label    = "Afficher / Masquer UI",
    Default  = Enum.KeyCode.RightShift,
    Callback = function(key)
        VoidUI:Notify({
            Title    = "Keybind",
            Message  = "Touche pressée : " .. key.Name,
            Type     = "info",
            Duration = 1.5,
        })
    end,
})

TabSettings:AddLabel("Notifications de test")

-- Boutons de test des 4 types de notifs
TabSettings:AddButton({
    Label    = "Notif — Success",
    Colors   = { Color3.fromRGB(30, 160, 90), Color3.fromRGB(55, 210, 120) },
    Callback = function()
        VoidUI:Notify({ Title = "Succès !", Message = "Opération réussie.", Type = "success", Duration = 3 })
    end,
})
TabSettings:AddButton({
    Label    = "Notif — Warning",
    Colors   = { Color3.fromRGB(180, 120, 0), Color3.fromRGB(255, 185, 40) },
    Callback = function()
        VoidUI:Notify({ Title = "Attention", Message = "Vérifiez vos paramètres.", Type = "warning", Duration = 3 })
    end,
})
TabSettings:AddButton({
    Label    = "Notif — Error",
    Colors   = { Color3.fromRGB(160, 30, 50), Color3.fromRGB(230, 55, 75) },
    Callback = function()
        VoidUI:Notify({ Title = "Erreur", Message = "Une erreur s'est produite.", Type = "error", Duration = 3 })
    end,
})
TabSettings:AddButton({
    Label    = "Notif — Info",
    Callback = function()
        VoidUI:Notify({ Title = "Information", Message = "Bee Script v1.0 actif.", Type = "info", Duration = 3 })
    end,
})

TabSettings:AddLabel("Système")

TabSettings:AddButton({
    Label    = "Détruire l'UI",
    Colors   = { Color3.fromRGB(180, 30, 50), Color3.fromRGB(230, 55, 75) },
    Callback = function()
        floatBtn:Destroy()
        overlay:Destroy()
        VoidUI:DestroyAll()
    end,
})

-- ════════════════════════════════════════════════════════════════════════════
--  BOUTON FLOTTANT
-- ════════════════════════════════════════════════════════════════════════════
local floatBtn = VoidUI:CreateFloatingButton({
    Text     = "🐝 Farm",
    Position = UDim2.new(1, -80, 0.5, -26),
    Size     = UDim2.new(0, 64, 0, 52),
    Callback = function()
        local newState = not toggleFarm:GetValue()
        toggleFarm:SetValue(newState)
        VoidUI:Notify({
            Title   = "Bouton rapide",
            Message = "Auto-Farm " .. (newState and "ON" or "OFF"),
            Type    = newState and "success" or "warning",
            Duration = 1.5,
        })
    end,
})

-- ════════════════════════════════════════════════════════════════════════════
--  OVERLAY D'INFOS EN TEMPS RÉEL
-- ════════════════════════════════════════════════════════════════════════════
local overlay = VoidUI:CreateOverlay({
    Position = UDim2.new(0, 16, 0, 120),
    Width    = 170,
    Items    = {
        { Type = "text",      Text  = "🐝 Bee Script",   Id = "title",  Bold = true,  TextSize = 13, Color = Color3.fromRGB(160, 110, 255) },
        { Type = "separator" },
        { Type = "text",      Text  = "Plot : " .. playerPlotId,  Id = "plot",   TextSize = 11 },
        { Type = "text",      Text  = "Oeufs achetés : 0",        Id = "bought", TextSize = 11 },
        { Type = "text",      Text  = "Honey : 0 ml",             Id = "honey",  TextSize = 11 },
        { Type = "separator" },
        { Type = "text",      Text  = "Auto-Buy : OFF",           Id = "abuy",   TextSize = 11, Color = Color3.fromRGB(230, 55, 75) },
        { Type = "text",      Text  = "Auto-Farm : OFF",          Id = "afarm",  TextSize = 11, Color = Color3.fromRGB(230, 55, 75) },
        { Type = "separator" },
        { Type = "text",      Text  = "Mode : Safe",              Id = "mode",   TextSize = 11, Color = Color3.fromRGB(60, 155, 255) },
    },
})

-- ════════════════════════════════════════════════════════════════════════════
--  LOGIQUE AUTO-BUY
-- ════════════════════════════════════════════════════════════════════════════
local eggs = playerPlot:FindFirstChild("Eggs")
if not eggs then
    VoidUI:Notify({ Title = "Erreur", Message = "Pas de dossier Eggs sur le plot.", Type = "error", Duration = 4 })
    return
end

local function tryBuyEgg(egg)
    if not State.autoBuy then return end
    local baseName = egg:GetAttribute("baseName")
    if baseName and State.selectedEggs[baseName] then
        task.wait(State.buyDelay + math.random(0, 3) / 10)
        purchaseRemote:FireServer(egg.Name, playerPlotId)
        State.eggsBought = State.eggsBought + 1
        progressBuy:SetValue(math.min(State.eggsBought, 50))
        overlay:SetText("bought", "Oeufs achetés : " .. State.eggsBought)
    end
end

for _, egg in ipairs(eggs:GetChildren()) do
    task.spawn(function() tryBuyEgg(egg) end)
end

eggs.ChildAdded:Connect(function(egg)
    task.spawn(function() tryBuyEgg(egg) end)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  BOUCLE DE MISE À JOUR DE L'OVERLAY (toutes les secondes)
-- ════════════════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(1) do
        -- Statuts Auto-Buy / Auto-Farm
        overlay:SetText("abuy",  "Auto-Buy : "  .. (State.autoBuy  and "ON" or "OFF"))
        overlay:SetText("afarm", "Auto-Farm : " .. (State.autoFarm and "ON" or "OFF"))
        overlay:SetColor("abuy",
            State.autoBuy  and Color3.fromRGB(55, 210, 120) or Color3.fromRGB(230, 55, 75))
        overlay:SetColor("afarm",
            State.autoFarm and Color3.fromRGB(55, 210, 120) or Color3.fromRGB(230, 55, 75))

        -- Mode de farm
        local modeColors = {
            Safe       = Color3.fromRGB(60, 155, 255),
            Fast       = Color3.fromRGB(255, 185, 40),
            Aggressive = Color3.fromRGB(230, 55, 75),
        }
        overlay:SetText("mode",  "Mode : " .. State.farmMode)
        overlay:SetColor("mode", modeColors[State.farmMode] or Color3.fromRGB(160, 155, 190))

        -- Simulation honey si auto-farm actif (à remplacer par la vraie logique)
        if State.autoFarm then
            State.honeyCollected = State.honeyCollected + math.random(5, 20)
            progressHoney:SetValue(math.min(State.honeyCollected, 1000))
            overlay:SetText("honey", "Honey : " .. State.honeyCollected .. " ml")
        end

        -- Sync walk speed au respawn
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = State.walkSpeed
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  NOTIFICATION DE DÉMARRAGE
-- ════════════════════════════════════════════════════════════════════════════
VoidUI:Notify({
    Title    = "Bee Script",
    Message  = "Chargé sur le plot " .. playerPlotId .. " · Sélectionne tes oeufs !",
    Type     = "success",
    Duration = 4,
})
