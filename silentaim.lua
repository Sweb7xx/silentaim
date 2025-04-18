-- // Rivals Silent Aim Script with Linoria UI

local SilentAim = {
    Enabled = true,
    TeamCheck = true,
    VisibleCheck = true,
    Prediction = 0.13,
    HitChance = 100,
    SelectedPart = "Head",
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function IsOnScreen(part)
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    return onScreen
end

local function IsVisible(part)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500, params)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function GetClosestPlayer()
    local closest, distance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(SilentAim.SelectedPart) then
            if SilentAim.TeamCheck and player.Team == LocalPlayer.Team then continue end
            local part = player.Character[SilentAim.SelectedPart]
            if SilentAim.VisibleCheck and not IsVisible(part) then continue end
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end
            local mousePos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if dist < distance then
                closest = part
                distance = dist
            end
        end
    end
    return closest
end

local function ApplySilentAim()
    local target = GetClosestPlayer()
    if not target then return nil end

    local prediction = (target.Velocity or Vector3.zero) * SilentAim.Prediction
    return target.Position + prediction
end

-- Hook
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if tostring(self) == "Hit" and method == "FireServer" and SilentAim.Enabled and math.random(0, 100) <= SilentAim.HitChance then
        local targetPos = ApplySilentAim()
        if targetPos then
            args[1] = targetPos
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

-- Linoria UI Setup
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Window = Library:CreateWindow({ Title = "Rivals | Silent Aim", Center = true, AutoShow = true })
local Tabs = {
    Main = Window:AddTab("Main"),
    Settings = Window:AddTab("Settings")
}

Tabs.Main:AddToggle("SilentAimEnabled", { Text = "Enable Silent Aim", Default = SilentAim.Enabled })
    :OnChanged(function(val) SilentAim.Enabled = val end)

Tabs.Main:AddSlider("HitChance", {
    Text = "Hit Chance",
    Min = 0,
    Max = 100,
    Default = SilentAim.HitChance,
    Rounding = 0
}):OnChanged(function(val) SilentAim.HitChance = val end)

Tabs.Main:AddSlider("Prediction", {
    Text = "Prediction",
    Min = 0,
    Max = 0.25,
    Default = SilentAim.Prediction,
    Rounding = 3
}):OnChanged(function(val) SilentAim.Prediction = val end)

Tabs.Main:AddDropdown("Part", {
    Values = { "Head", "UpperTorso", "LowerTorso" },
    Default = SilentAim.SelectedPart,
    Multi = false,
    Text = "Target Part"
}):OnChanged(function(val) SilentAim.SelectedPart = val end)

Tabs.Settings:AddToggle("TeamCheck", { Text = "Team Check", Default = SilentAim.TeamCheck })
    :OnChanged(function(val) SilentAim.TeamCheck = val end)

Tabs.Settings:AddToggle("VisibleCheck", { Text = "Visible Check", Default = SilentAim.VisibleCheck })
    :OnChanged(function(val) SilentAim.VisibleCheck = val end)

Library:SetWatermark("Rivals Silent Aim | by You")
Library:Notify("Silent Aim Loaded!")

-- Save config
local Configs = Window:AddTab("Configs")
Library.SaveManager:SetLibrary(Library)
Library.SaveManager:BuildConfigSection(Configs)

