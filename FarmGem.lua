local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- 1. HÀM TWEEN (Lướt xuyên tường)
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

-- 2. TẠO UI (Bảng đen hiển thị)
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AutoFarmStatus"
screenGui.ResetOnSpawn = false

local statusLabel = Instance.new("TextLabel", screenGui)
statusLabel.Size = UDim2.new(0, 350, 0, 50)
statusLabel.Position = UDim2.new(0.5, -175, 0.1, 0)
statusLabel.BackgroundColor3 = Color3.new(0, 0, 0)
statusLabel.BackgroundTransparency = 0.5
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextScaled = true
statusLabel.Text = " Đang khởi động... "

local function updateStatus(text)
    statusLabel.Text = text
end

-- 3. HÀM RESET & PLAY AGAIN (Lì lợm, không Webhook)
local function resetAndPlayAgain()
    if _G.CurrentTween then _G.CurrentTween:Cancel() _G.CurrentTween = nil end
    updateStatus("♻️ Đang Reset...")
    
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = 0
    end

    task.wait(2) 

    local clicked = false
    local startTime = tick()
    while not clicked and (tick() - startTime < 15) do
        local pGui = player:FindFirstChild("PlayerGui")
        if pGui then
            for _, v in pairs(pGui:GetDescendants()) do
                if v:IsA("TextButton") and v.Text:find("Play Again") then
                    if v.Visible or v.Transparency < 1 then
                        updateStatus("✅ Đang nhấn Play Again...")
                        task.wait(0.5)
                        pcall(function()
                            if getconnections then
                                for _, c in pairs(getconnections(v.MouseButton1Click)) do c:Fire() end
                                for _, c in pairs(getconnections(v.Activated)) do c:Fire() end
                            end
                            v:Activate()
                        end)
                        clicked = true; break
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- 4. HÀM SỬA MÁY
local function interact(prompt)
    updateStatus("⚡ Đang sửa máy...")
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

-- 5. LOGIC CHÍNH
function startAutoFarm()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    local hum = char:WaitForChild("Humanoid", 10)
    if not root or not hum then return end
    
    local startTime = tick()
    local targetPart = nil

    -- TRẢ LẠI CƠ CHẾ QUÉT KIÊN TRÌ CỦA KIỆT
    updateStatus("🔍 Đang quét tìm máy phát điện... ")
    repeat
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Enabled then
                local text = (v.ActionText .. v.ObjectText):lower()
                if text:find("repair") or text:find("power") then
                    targetPart = v.Parent:IsA("BasePart") and v.Parent or v.Parent:FindFirstChildWhichIsA("BasePart", true)
                    if targetPart then break end
                end
            end
        end
        if not targetPart then task.wait(1) end -- Nếu chưa thấy thì đợi 1 giây quét lại
    until targetPart

    updateStatus("✅ Đã tìm thấy máy!")
    local prompt = targetPart:FindFirstChildWhichIsA("ProximityPrompt", true)
    prompt.HoldDuration = 0

    -- GHIM NHÌN (Trả lại tính năng nhìn thẳng vào máy)
    local camCon = RunService.RenderStepped:Connect(function()
        if targetPart and targetPart.Parent and char.Parent then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
        end
    end)

    local connection
    connection = RunService.Stepped:Connect(function()
        local timeElapsed = tick() - startTime
        
        -- Hết giờ hoặc chết thì reset
        if timeElapsed > 100 or hum.Health <= 0 then
            if _G.CurrentTween then _G.CurrentTween:Cancel() _G.CurrentTween = nil end
            if camCon then camCon:Disconnect() end
            connection:Disconnect()
            resetAndPlayAgain()
            return
        end

        local dist = (root.Position - targetPart.Position).Magnitude
        updateStatus(math.floor(dist) .. "m | Reset sau: " .. math.floor(100 - timeElapsed) .. "s")

        -- LOGIC BAY TWEEN
        if dist > 6 then
            if not _G.CurrentTween then
                -- Bay thấp xuống 5 block để xuyên tường/sàn
                _G.CurrentTween = tweenTo(targetPart.CFrame * CFrame.new(0, -5, 0), 40)
            end
        else
            -- Đã đến nơi
            if _G.CurrentTween then _G.CurrentTween:Cancel() _G.CurrentTween = nil end
            interact(prompt)
            
            -- Sửa xong máy
            if not prompt.Enabled or not prompt.Parent then
                if camCon then camCon:Disconnect() end
                connection:Disconnect()
                updateStatus("✅ Xong! Đợi 1s...")
                task.wait(1)
                resetAndPlayAgain()
            end
        end

        -- XUYÊN TƯỜNG CƯỠNG ÉP
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

-- KHỞI CHẠY
startAutoFarm()
