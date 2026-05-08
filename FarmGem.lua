local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- 1. HÀM TWEEN (Giữ nguyên của Kiệt)
local function tweenTo(targetCFrame, speed)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / speed
    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

-- 2. TẠO UI (Giữ nguyên của Kiệt)
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AutoFarmStatus"
screenGui.ResetOnSpawn = false

local statusLabel = Instance.new("TextLabel", screenGui)
statusLabel.Size = UDim2.new(0, 350, 0, 50)
statusLabel.Position = UDim2.new(0.5, -150, 0.1, 0)
statusLabel.BackgroundColor3 = Color3.new(0, 0, 0)
statusLabel.BackgroundTransparency = 0.5
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextScaled = true
statusLabel.Text = " Đang khởi động... "

local function updateStatus(text)
    statusLabel.Text = text
end

-- 3. HÀM TÌM MỤC TIÊU (Giữ nguyên của Kiệt)
local function getPowerPlantTarget()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local target, dist = nil, math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled then
            local text = (v.ActionText .. v.ObjectText):lower()
            if text:find("repair") or text:find("power") then
                local p = v.Parent:IsA("BasePart") and v.Parent or v.Parent:FindFirstChildWhichIsA("BasePart", true)
                if p then
                    local d = (char.HumanoidRootPart.Position - p.Position).Magnitude
                    if d < dist then dist = d; target = p end
                end
            end
        end
    end
    return target
end

-- 4. HÀM RESET & PLAY AGAIN (Bản fix lì lợm)
local function resetAndPlayAgain()
    if _G.CurrentTween then _G.CurrentTween:Cancel() _G.CurrentTween = nil end
    updateStatus("♻️ Đang Reset...")
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = 0
    end
    task.wait(3.5) 
    local clicked = false
    local startTime = tick()
    while not clicked and (tick() - startTime < 15) do
        local pGui = player:FindFirstChild("PlayerGui")
        if pGui then
            for _, v in pairs(pGui:GetDescendants()) do
                if v:IsA("TextButton") and v.Text:find("Play Again") and v.Visible then
                    task.wait(0.5)
                    pcall(function()
                        if getconnections then
                            for _, c in pairs(getconnections(v.MouseButton1Click)) do c:Fire() end
                        end
                        v:Activate()
                    end)
                    clicked = true; break
                end
            end
        end
        task.wait(1)
    end
end

-- 5. HÀM INTERACT
local function interact(prompt)
    updateStatus(" ⚡ Đang sửa máy... ")
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        task.spawn(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.1)
            prompt:InputHoldEnd()
        end)
    end
end

-- 6. LOGIC CHÍNH (Sửa lỗi thiếu end và lặp tween)
function startAutoFarm()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    local hum = char:WaitForChild("Humanoid", 10)
    if not root or not hum then return end
    local startTime = tick()

    local targetPart = nil
    repeat
        targetPart = getPowerPlantTarget()
        if not targetPart then task.wait(1) end
    until targetPart

    -- Ghim nhìn
    local camCon = RunService.RenderStepped:Connect(function()
        if targetPart and targetPart.Parent and player.Character then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
        end
    end)

    local prompt
