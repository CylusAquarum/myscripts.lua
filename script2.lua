-- [[ KING LEGACY: HYPER-SPEED BOSS HUNTER (100% TARGET HOP) ]] --

if _G.KingScriptRunning then
    _G.KingScriptRunning = false
    task.wait(0.5)
end
_G.KingScriptRunning = true

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Hàm quét siêu tốc tìm Sea King hoặc Hydra
local function findTargetBoss()
    local success, result = pcall(function()
        for _, v in ipairs(Workspace:GetChildren()) do
            if v and v:IsA("Model") then
                local name = v.Name:lower()
                -- Lọc tất cả các dạng tên của Sea King hoặc Hydra
                if name:find("seaking") or name:find("hydra") or name:find("sea king") then
                    return v
                end
            end
        end
        return nil
    end)
    return success and result
end

-- Hàm dịch chuyển nhặt rương tốc độ cao
local function collectChestsFast()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        for _, v in ipairs(Workspace:GetChildren()) do
            if not _G.KingScriptRunning then break end
            if v and v:IsA("Model") then
                local name = v.Name:lower()
                if name:find("chest") then
                    local targetPart = v:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        rootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.2) -- Thời gian ngắn để ăn rương cực nhanh
                    end
                end
            end
        end
    end)
end

-- Hàm Server Hop chớp nhoáng không dây dưa
local function instantServerHop()
    print("[Hyper-Hop] Server này không có mục tiêu. Đang nhảy sang server khác lập tức...")
    pcall(function()
        local servers = {}
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(url))
        
        if response and response.data then
            for _, server in ipairs(response.data) do
                if server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end

        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end

-- Vòng lặp chính tối ưu tốc độ lọc server
task.spawn(function()
    while _G.KingScriptRunning do
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart", 10)
        
        if not rootPart then
            task.wait(1)
            continue
        end

        -- Chỉ chờ tối ưu 2 giây để map kịp load danh sách thực thể
        task.wait(2)

        -- Quét nhanh trong vòng 2 giây xem có Boss hay không
        local targetFound = false
        for i = 1, 2 do
            if findTargetBoss() then
                targetFound = true
                break
            end
            task.wait(0.5)
        end

        if targetFound then
            print("[Hyper-Hop] 🎯 ĐÃ TÌM THẤY SERVER CÓ SEA KING / HYDRA! Tiến hành farm rương...")
            
            -- Trụ lại server này để gom sạch rương cho đến khi Boss biến mất hoặc tối đa 45 giây
            local timeout = 0
            while _G.KingScriptRunning and findTargetBoss() and timeout < 45 do
                collectChestsFast()
                task.wait(0.8)
                timeout = timeout + 1
            end
            
            print("[Hyper-Hop] Đã vét sạch rương. Tiếp tục đi săn server khác...")
            task.wait(0.5)
            instantServerHop()
            task.wait(8) -- Chờ tải sang server mới
        else
            -- KHÔNG CÓ BOSS -> Bỏ qua ngay lập tức, không lãng phí 1 giây nào
            instantServerHop()
            task.wait(6) -- Thời gian ngắn để kịp chuyển server liên tục
        end
        
        task.wait(1)
    end
end)

print("[King Script] Chế độ Săn Boss Siêu Tốc đã kích hoạt thành công!")
