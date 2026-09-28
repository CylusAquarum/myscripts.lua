-- [[ KING LEGACY: STABLE AUTO HOP & CHEST FARM FOR DELTA ]] --

-- Chống chạy đè nhiều luồng cùng lúc
if _G.RunningKingScript then
    _G.RunningKingScript = false
    task.wait(0.5)
end
_G.RunningKingScript = true

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Hàm kiểm tra xem trong Workspace có Sea King hoặc Hydra không
local function hasTargetBoss()
    local success, result = pcall(function()
        for _, v in ipairs(Workspace:GetChildren()) do
            if v and v:IsA("Model") then
                local name = v.Name:lower()
                if name:find("seaking") or name:find("hydra") then
                    return true
                end
            end
        end
        return false
    end)
    return success and result
end

-- Hàm tìm và dịch chuyển đến rương an toàn
local function teleportAndCollectChests()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        for _, v in ipairs(Workspace:GetChildren()) do
            if not _G.RunningKingScript then break end
            if v and v:IsA("Model") then
                local name = v.Name:lower()
                if name:find("chest") then
                    local targetPart = v:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        -- Dịch chuyển trực tiếp đến rương
                        rootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.4) -- Thời gian nghỉ ngắn để game nhận diện nhặt rương
                    end
                end
            end
        end
    end)
end

-- Hàm Server Hop chống lỗi API Roblox
local function serverHop()
    print("[King Script] Đang tìm server mới để tiếp tục farm...")
    
    local success, err = pcall(function()
        local servers = {}
        local cursor = ""
        
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
            -- Fallback nếu danh sách trống
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)

    -- Nếu lỗi API mạng, ép buộc dùng lệnh Teleport cơ bản sau 3 giây
    if not success then
        task.wait(3)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
end

-- Vòng lặp chính hoạt động bất tử (Continuous Loop)
task.spawn(function()
    while _G.RunningKingScript do
        -- Đợi character load xong hoàn toàn
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        
        if not humanoidRootPart then
            task.wait(2)
            continue
        end

        -- Kiểm tra server hiện tại có Boss mục tiêu không
        if hasTargetBoss() then
            print("[King Script] Phát hiện Sea King hoặc Hydra! Đang tiến hành gom rương...")
            
            local timeout = 0
            -- Vòng lặp quét và nhặt rương liên tục cho đến khi boss biến mất hoặc hết thời gian tối đa (40 giây)
            while _G.RunningKingScript and hasTargetBoss() and timeout < 40 do
                teleportAndCollectChests()
                task.wait(1)
                timeout = timeout + 1
            end
            
            print("[King Script] Đã hoàn thành hoặc hết thời gian ở server này. Đang chuyển server...")
            task.wait(1)
            serverHop()
            -- Chờ tránh việc code chạy tiếp trong lúc đang load màn hình chuyển server
            task.wait(10) 
        else
            -- Nếu server không có Sea King / Hydra, lập tức đổi server ngay
            serverHop()
            task.wait(10)
        end
        
        task.wait(2)
    end
end)

print("[King Script] Đã khởi chạy thành công trên Delta Executor!")
