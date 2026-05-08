--script for the game https://www.roblox.com/fr/games/102192921830821/Build-A-Farm-Factory
--only an autobuy in it 

local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/femmehomme90-web/VoidUI/refs/heads/main/voidUI.lua"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- Récupération des seeds
local hold = lp.PlayerGui.Main.Menus.Index.Inner.ScrollingFrame.Hold

local items = {}
for _, frame in ipairs(hold:GetChildren()) do
    if frame:IsA("Frame") and frame.Name ~= "Example" then
        local icon = frame:FindFirstChild("Icon")
        if icon and icon:IsA("ImageLabel") then
            table.insert(items, {
                Name = frame.Name,
                Icon = icon.Image,
            })
        end
    end
end

-- Récupération du plot du joueur
local myPlot = nil
for _, plot in ipairs(workspace.Plots:GetChildren()) do
    if plot:GetAttribute("Owner") == lp.UserId then
        myPlot = plot
        break
    end
end

-- Retourne l'index d'un stump (Stump=1, Stump_2=2, etc.)
local function getStumpIndex(stump)
    local n = stump.Name:match("_(%d+)$")
    return n and tonumber(n) or 1
end

-- Récupère les stumps triés par index
local function getStumps()
    local stumps = {}
    for _, child in ipairs(myPlot:GetChildren()) do
        if child.Name:match("^Stump") then
            table.insert(stumps, child)
        end
    end
    table.sort(stumps, function(a, b)
        return getStumpIndex(a) < getStumpIndex(b)
    end)
    return stumps
end

-- UI
local Win = VoidUI:CreateWindow({
    Title = "Seed Buyer",
    Size  = UDim2.new(0, 580, 0, 480),
})

local Tab = Win:AddTab("Seeds")

-- Toggle Auto Sell
local sellRunning = false
Tab:AddToggle({
    Label   = "Auto Sell (20s)",
    Default = false,
    Callback = function(v)
        sellRunning = v
        if not sellRunning then return end
        task.spawn(function()
            while sellRunning do
                ReplicatedStorage.Communication.SellCrate:FireServer()
                task.wait(20)
            end
        end)
    end,
})

local selected = {}

Tab:AddCardGrid({
    Items    = items,
    Columns  = 4,
    Callback = function(s) selected = s end,
})

local running = false

Tab:AddToggle({
    Label   = "Auto Buy",
    Default = false,
    Callback = function(v)
        running = v
        if not running then return end

        task.spawn(function()
            while running do
                ReplicatedStorage.Communication.DoRoll:InvokeServer()
                task.wait(0.7)

                for _, stump in ipairs(getStumps()) do
                    local ok, title = pcall(function()
                        return stump.Model.BuyableDisplay.Title.Text
                    end)
                    if ok and selected[title] then
                        local idx = getStumpIndex(stump)
                        ReplicatedStorage.Communication.BuySeeds:FireServer(idx)
                        task.wait(0.1)
                    end
                end
            end
        end)
    end,
})
