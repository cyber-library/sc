--// ==========================================
--// BULLETPROOF MCP LOADER (ANTI-DC & REJOIN)
--// Domain: mcp.bosscdid-store.com
--// ==========================================

getgenv().BridgeURL = "mcp.bosscdid-store.com"

local LOADER_CODE = [[
    getgenv().BridgeURL = "mcp.bosscdid-store.com"
    local maxRetries = 10
    local retryDelay = 2

    for attempt = 1, maxRetries do
        local ok, err = pcall(function()
            local src = game:HttpGet("https://mcp.bosscdid-store.com/script.luau")
            loadstring(src)()
        end)
        if ok then
            print("[MCP Loader] Berhasil terhubung ke MCP Server!")
            break
        else
            warn(("[MCP Loader] Gagal connect (percobaan %d/%d): %s"):format(attempt, maxRetries, tostring(err)))
            task.wait(retryDelay)
        end
    end
]]

--// 1. Teleport Queue (Memastikan script aktif lagi setelah pindah Map/Server)
local function setupQueue()
    local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if queue then
        pcall(function()
            queue(LOADER_CODE)
        end)
    end
end
setupQueue()

-- Daftarkan ulang queue setiap kali teleport diinisiasi
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
        setupQueue()
    end
end)

--// 2. Anti-Kick / Auto-Rejoin Handler
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local isRejoining = false
local function attemptRejoin()
    if isRejoining then return end
    isRejoining = true
    warn("[MCP Anti-DC] Terdeteksi Disconnect/Kick! Mempersiapkan Auto-Rejoin dalam 3 detik...")
    
    setupQueue()
    task.wait(3)

    pcall(function()
        if #game.JobId > 0 then
            -- Coba masuk kembali ke server yang sama
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
        else
            -- Jika server sudah tutup, masuk ke server baru di game yang sama
            TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
        end
    end)
    
    -- Fallback jika teleport pertama gagal dalam 10 detik
    task.wait(10)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end)
end

-- Hook deteksi popup disconnect/kick dari Roblox Engine
pcall(function()
    GuiService.ErrorMessageChanged:Connect(function()
        attemptRejoin()
    end)
end)

-- Hook alternatif jika GuiService diproteksi
pcall(function()
    local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
    if promptGui then
        local promptOverlay = promptGui:WaitForChild("promptOverlay", 5)
        if promptOverlay then
            promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    attemptRejoin()
                end
            end)
        end
    end
end)

--// 3. Eksekusi Loader MCP Utama
task.spawn(function()
    loadstring(LOADER_CODE)()
end)
