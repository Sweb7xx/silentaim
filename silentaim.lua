-- Silent Aim for Rivals with GUI & Toggle
getgenv().SilentAimEnabled = true
getgenv().SilentAimFOV = 120

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "SilentAimGUI"

local statusLabel = Instance.new("TextLabel", ScreenGui)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.Size = UDim2.new(0, 200, 0, 30)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextStrokeTransparency = 0
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 20
statusLabel.Text = "Silent Aim: ON"

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = getgenv().SilentAimFOV
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Transparency = 0.4
fovCircle.Filled = false

-- Toggle Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightShift then
        getgenv().SilentAimEnabled = not getgenv().SilentAimEnabled
        statusLabel.Text = "Silent Aim: " .. (getgenv().SilentAimEnabled and "ON" or "OFF")
        statusLabel.TextColor3 = getgenv().SilentAimEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
end)

-- Update FOV circle
RunService.RenderStepped:Connect(function()
    local mouseLocation = UserInputService:GetMouseLocation()
    fovCircle.Position = Vector2.new(mouseLocation.X, mouseLocation.Y)
    fovCircle.Visible = getgenv().SilentAimEnabled
end)

-- Target selector
local function getClosestEnemy()
    local closestPlayer = nil
    local shortestDistance = getgenv().SilentAimFOV
    local mouse = LocalPlayer:GetMouse()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local distance = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Metatable hook
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if SilentAimEnabled and method == "FindPartOnRayWithIgnoreList" and tostring(self) == "Workspace" then
        local target = getClosestEnemy()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                local origin = args[1].Origin
                local direction = (head.Position - origin).Unit * 1000
                args[1] = Ray.new(origin, direction)
                return oldNamecall(self, unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end)
