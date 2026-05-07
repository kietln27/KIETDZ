local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- TẠO UI HIỂN THỊ TRẠNG THÁI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AutoFarmStatus"

local statusLabel = Instance.new("TextLabel", screenGui)
statusLabel.Size = UDim2.new(0, 300, 0, 50)
statusLabel.Position = UDim2.new(0.5, -150, 0.1, 0) -- Nằm ở giữa phía trên
statusLabel.BackgroundColor3 = Color3.new(0, 0, 0)
statusLabel.BackgroundTransparency = 0.5
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextScaled = true
statusLabel.Text = "🤖 Hệ thống: Đang khởi động..."

-- Hàm để đổi chữ nhanh
local function updateStatus(text)
    statusLabel.Text = "🤖 " .. text
end

-- 1. Hàm tìm đúng cái bảng điện Nhà Máy
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
                    if d < dist then 
                        dist = d
                        target = p 
                    end
                end
            end
        end
    end
    return target
end

-- 2. Vòng lặp chờ đợi cho đến khi tìm thấy
local targetPart = nil
updateStatus("Đang quét tìm bảng điện...")

repeat
    targetPart = getPowerPlantTarget()
    if not targetPart then
        task.wait(1) 
    end
until targetPart

-- 3. Khi đã tìm thấy, tiến hành GHIM NHÌN
updateStatus("Đã thấy: " .. targetPart.Name .. " - Đang di chuyển!")

RunService.RenderStepped:Connect(function()
    if targetPart and targetPart.Parent and player.Character then
        local currentPos = camera.CFrame.Position
        camera.CFrame = CFrame.lookAt(currentPos, targetPart.Position)
    end
end)
task.wait(1)


-- Hàm kích hoạt Prompt an toàn
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

-- HÀM RESET XONG MỚI ĐỢI NHẤN PLAY AGAIN
local function resetAndPlayAgain()
updateStatus("♻️ Đang Reset...")
    task.wait(0.2)

    -- Thực hiện Reset qua Menu
    VIM:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
    task.wait(0.2)

    for i = 1, 2 do
        VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.15)
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.15)
    end
    task.wait(0.1)

    local screen = workspace.CurrentCamera.ViewportSize
    for i = 1, 2 do
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.5)
        VIM:SendMouseButtonEvent(screen.X / 2, screen.Y / 2, 0, true, game, 1)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(screen.X / 2, screen.Y / 2, 0, false, game, 1)
        task.wait(0.2)
    end

    -- Bước 2: Đợi hiện bảng để nhấn Play Again
    local clicked = false
    while not clicked do
        local pGui = player:FindFirstChild("PlayerGui")
        if pGui then
            for _, v in pairs(pGui:GetDescendants()) do
                if v:IsA("TextButton") and v.Text:find("Play Again") and v.Visible then
                    GuiService.SelectedObject = v
                    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    
                    VIM:SendMouseButtonEvent(screen.X / 2, screen.Y / 2, 0, true, game, 1)
                    task.wait(0.05)
                    VIM:SendMouseButtonEvent(screen.X / 2, screen.Y / 2, 0, false, game, 1)
                    
                    clicked = true
                    break
                end
            end
        end
        task.wait(0.5)
    end
end

local function startAutoFarm()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    local hum = char:WaitForChild("Humanoid", 10)
    
    if not root or not hum then return end

  local startTime = tick() -- BẮT ĐẦU ĐẾM GIỜ

    local function getTarget()
        local best, minDist = nil, math.huge
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Enabled then
                local info = (v.ActionText .. v.ObjectText):lower()
                if info:find("repair") or info:find("power") then
                    local p = v.Parent:IsA("BasePart") and v.Parent or v.Parent:FindFirstChildWhichIsA("BasePart", true)
                    if p then
                        local d = (root.Position - p.Position).Magnitude
                        if d < minDist then minDist = d; best = v end
                    end
                end
            end
        end
        return best
    end

    local prompt = getTarget()
    if prompt then
        prompt.HoldDuration = 0
        local targetPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
        
        local floor = Instance.new("Part", workspace)
        floor.Size = Vector3.new(15, 0.2, 15)
        floor.Anchored, floor.CanCollide = true, true
        floor.Transparency = 0.8
        floor.Color = Color3.new(0, 1, 1)

        local connection
        connection = RunService.Stepped:Connect(function()
        -- KIỂM TRA HẾT 2 PHÚT --
        local timeElapsed = tick() - startTime
            if timeElapsed > 120 then 
                connection:Disconnect() 
                if floor then floor:Destroy() end 
                resetAndPlayAgain() 
                return
            end
            -- KIỂM TRA CHẾT ĐỂ PLAY AGAIN
            if hum.Health <= 0 or not char.Parent then
                connection:Disconnect()
                if floor then floor:Destroy() end
                resetAndPlayAgain()
                return
            end

            if not char or not root or not prompt.Parent or not hum then 
                if floor then floor:Destroy() end
                if connection then connection:Disconnect() end
                return 
            end

            -- GIỮ SÀN PHẲNG
            local flatRotation = CFrame.Angles(0, math.rad(root.Orientation.Y), 0)
            floor.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.05, root.Position.Z) * flatRotation
            
            -- QUÉT TƯỜNG (CODE GỐC CỦA BẠN)
            local isInsideWall = false
            local rParams = RaycastParams.new()
            rParams.FilterDescendantsInstances = {char, floor}
            rParams.FilterType = Enum.RaycastFilterType.Blacklist
            local rayOrigin = root.Position + Vector3.new(0, 1.5, 0) 
            local rayFront = workspace:Raycast(rayOrigin, root.CFrame.LookVector * 1, rParams)

            local oParams = OverlapParams.new()
            oParams.FilterDescendantsInstances = {char, floor}
            oParams.FilterType = Enum.RaycastFilterType.Blacklist
            local checkCFrame = root.CFrame * CFrame.new(0, 1.5, 0)
            local partsInBody = workspace:GetPartBoundsInBox(checkCFrame, Vector3.new(1.8, 1, 1.8), oParams)

            if (rayFront and rayFront.Instance and rayFront.Instance.CanCollide) then
                isInsideWall = true
            else
                for _, part in pairs(partsInBody) do
                    if part.CanCollide then isInsideWall = true; break end
                end
            end

            -- CHỈNH TỐC ĐỘ: PHANH LẠI KHI CÁCH 5 STUD
            local dist = (root.Position - targetPart.Position).Magnitude
            
            -- CẬP NHẬT UI CÓ ĐẾM NGƯỢC
            updateStatus(math.floor(dist) .. "m | Còn lại: " .. math.floor(120 - timeElapsed) .. "s")

            if dist < 5 then
                hum.WalkSpeed = 0
            elseif isInsideWall then
                hum.WalkSpeed = 7
            else
                hum.WalkSpeed = 30
            end
            
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end

            hum:MoveTo(targetPart.Position)

            -- ĐẾN NƠI THÌ DỊCH XUỐNG SÂU
            if dist < 7 then
                root.CFrame = targetPart.CFrame * CFrame.new(0, -5, 0)
                
                interact(prompt)
                task.wait(0.5) 
                
                if not prompt.Enabled or not prompt.Parent then
                    connection:Disconnect()
                    if floor then floor:Destroy() end
                    resetAndPlayAgain()
                end
            end
        end)
    end
end

player.CharacterAdded:Connect(function()
    task.wait(3)
    startAutoFarm()
end)

startAutoFarm()
