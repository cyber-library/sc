-- ====================================================================
-- LOADER MASTER: Anti-AFK + Auto-Reconnect + PlotState + GUI + MCP
-- ====================================================================

local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport

local function runMasterHelper()

    -- 2. Auto-Reconnect jika muncul layar Disconnected
    task.spawn(function()
        local GuiService = game:GetService("GuiService")
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        GuiService.ErrorMessageChanged:Connect(function()
            task.wait(3)
            pcall(function()
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end)
        end)
    end)

    -- 3. Koneksi ke MCP Bridge
    task.spawn(function()
        pcall(function()
            getgenv().BridgeURL = "mcp.bosscdid-store.com"
            loadstring(game:HttpGet("https://mcp.bosscdid-store.com/script.luau"))()
        end)
    end)

    -- 4. Tunggu game siap
    if not game:IsLoaded() then game.Loaded:Wait() end
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")
    local lp = Players.LocalPlayer

    -- Hapus GUI lama
    local parentGui = (gethui and gethui()) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or lp:WaitForChild("PlayerGui")
    local oldGui = parentGui:FindFirstChild("TreadmillHelperGUI")
    if oldGui then oldGui:Destroy() end

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

    -- ================= PENCARI PLOT RESMI (PLOTSTATE) =================
    local function findMyPlot()
        local plots = workspace:WaitForChild("Plots", 20)
        if not plots then return nil end

        -- 1. Menggunakan PlotState game resmi (Instan & Akurat)
        local ok, PlotState = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("PlotState"))
        end)
        if ok and PlotState and PlotState.ResolveLocalSlot then
            local slot = PlotState.ResolveLocalSlot()
            if slot then
                local p = plots:FindFirstChild(tostring(slot))
                if p then return p end
            end
        end

        -- 2. Fallback pencocokan Username/DisplayName
        for _, plot in ipairs(plots:GetChildren()) do
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc:IsA("TextLabel") and (desc.Text == lp.Name or desc.Text == lp.DisplayName) then
                    return plot
                end
            end
        end
        return nil
    end

    -- ================= GUI SETUP =================
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TreadmillHelperGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parentGui

    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 230, 0, 195)
    mainFrame.Position = UDim2.new(0.02, 0, 0.35, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Thickness = 1.4
    stroke.Transparency = 0.3

    -- Title Bar
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

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
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

    -- Content Frame
    local content = Instance.new("Frame", mainFrame)
    content.Size = UDim2.new(1, -20, 1, -46)
    content.Position = UDim2.new(0, 10, 0, 42)
    content.BackgroundTransparency = 1

    local statusLabel = Instance.new("TextLabel", content)
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: ⏳ Menghubungkan..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local statsBox = Instance.new("Frame", content)
    statsBox.Size = UDim2.new(1, 0, 0, 68)
    statsBox.Position = UDim2.new(0, 0, 0, 24)
    statsBox.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    statsBox.BorderSizePixel = 0
    Instance.new("UICorner", statsBox).CornerRadius = UDim.new(0, 8)
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
    Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)

    local isOnTreadmill = false
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

    -- ================= AKSI TREADMILL =================
    local function doMountTreadmill()
        if isActionBusy then return end
        isActionBusy = true
        actionBtn.Text = "⏳ Menghubungkan Plot..."

        -- Tunggu save data siap
        pcall(function()
            local Shared = ReplicatedStorage:WaitForChild("Shared", 15)
            if Shared and Shared:FindFirstChild("Save") then
                local Save = require(Shared.Save)
                if not Save.IsLocalDataLoaded() then
                    Save.ProfileReady:Wait()
                end
            end
        end)

        local myPlot = nil
        for attempt = 1, 30 do
            myPlot = findMyPlot()
            if myPlot then break end
            task.wait(0.5)
        end

        if not myPlot then
            actionBtn.Text = "⚠️ Plot Belum Siap"
            task.wait(1.5)
            updateUIState(false)
            isActionBusy = false
            return
        end

        local treadmill = myPlot:WaitForChild("TreadmillBottom", 15)
        if not treadmill then
            actionBtn.Text = "⚠️ Treadmill Hilang"
            task.wait(1.5)
            updateUIState(false)
            isActionBusy = false
            return
        end

        actionBtn.Text = "⏳ Menaiki Treadmill..."
        local okRemotes, Remotes = pcall(require, ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

        for attempt = 1, 6 do
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and treadmill then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = treadmill.CFrame * CFrame.new(0, 2.2, 0)
            end
            task.wait(0.4)

            if okRemotes and Remotes and Remotes.Treadmill and Remotes.Treadmill.AskWearStill then
                local res, msg = Remotes.Treadmill.AskWearStill:InvokeServer()
                if res == true or msg == "Already using treadmill" then
                    updateUIState(true)
                    isActionBusy = false
                    return
                end
            end
            task.wait(0.6)
        end

        updateUIState(true)
        isActionBusy = false
    end

    local function doDismountTreadmill()
        if isActionBusy then return end
        isActionBusy = true
        actionBtn.Text = "⏳ Turun..."

        local okRemotes, Remotes = pcall(require, ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
        if okRemotes and Remotes and Remotes.Treadmill and Remotes.Treadmill.AskDoff then
            pcall(function() Remotes.Treadmill.AskDoff:InvokeServer() end)
        end

        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
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

    -- Leaderstats Listener
    task.spawn(function()
        local leaderstats = lp:WaitForChild("leaderstats", 25)
        if not leaderstats then return end

        local speedObj = leaderstats:WaitForChild("Speed", 15)
        local moneyObj = leaderstats:WaitForChild("Money/s", 15)

        local function updateStats()
            if speedObj then speedLabel.Text = "⚡ Speed: " .. formatNumber(speedObj.Value) end
            if moneyObj then moneyLabel.Text = "💰 Money/s: $" .. formatNumber(moneyObj.Value) end
        end

        updateStats()
        if speedObj then speedObj.Changed:Connect(updateStats) end
        if moneyObj then moneyObj.Changed:Connect(updateStats) end
    end)

    -- Jalankan Auto-Mount saat awal masuk
    task.spawn(function()
        task.wait(2)
        doMountTreadmill()
    end)

    -- Auto-Mount jika respawn
    lp.CharacterAdded:Connect(function()
        task.wait(2.5)
        doMountTreadmill()
    end)
end

-- Pasang ke antrean teleport agar jika rejoin otomatis dieksekusi lagi
if queue then
    queue([[
        local bridge = "https://mcp.bosscdid-store.com"
        loadstring(game:HttpGet(bridge .. "/script.luau"))()
    ]])
end

runMasterHelper()
