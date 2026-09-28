-- [[ KING LEGACY: ULTIMATE SEA KING & HYDRA CHEST/FRUIT FARM ]] --

-- Cấu hình tùy chọn
_G.webhook = _G.webhook or "Enter"
_G.fixhop = _G.fixhop or false
_G.y = _G.y or 1500 -- Độ cao an toàn để bay lên trước khi hop server

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
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- 1. Tự động nhấn phím Enter khi vừa vào game
task.spawn(function()
    pcall(function()
        task.wait(2)
        VirtualUser:Button1Down(Vector2.new(0,0))
        VirtualUser:Button1Up(Vector2.new(0,0))
        -- Gửi sự kiện nhấn phím Enter
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        print("[King Script] Đã tự động nhấn Enter thành công!")
    end)
end)

-- Hàm kiểm tra xem trong server có Sea King hoặc Hydra không
local function hasTargetBoss()
    local success, result = pcall(function()
        -- Kiểm tra trong Workspace chung
        for _, v in ipairs(Workspace:GetChildren()) do
            if v and v:IsA("Model") then
                local name = v.Name:lower()
                if name:find("seaking") or name:find("hydra") or name:find("sea king") then
                    return true
                end
            end
        end
        
        -- Kiểm tra trong thư mục Enemies (nếu có)
        if Workspace:FindFirstChild("Enemies") then
            for _, v in ipairs(Workspace.Enemies:GetChildren()) do
                local name = v.Name:lower()
                if name:find("seaking") or name:find("hydra") or name:find("sea king") then
                    return true
                end
            end
        end

        return false
    end)
    return success and result
end

-- Hàm tự động cất/nhặt trái cây rơi ra từ rương vào túi (nếu game hỗ trợ prompt hoặc touch)
local function collectFruits()
    pcall(function()
        for _, v in ipairs(Workspace:GetChildren()) do
            if v and v:IsA("Tool") and v:FindFirstChild("Handle") then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    -- Dịch chuyển nhẹ đến trái cây để nhặt vào túi
                    character.HumanoidRootPart.CFrame = v.Handle.CFrame
                    task.wait(0.3)
                end
            end
        end
    end)
end

-- Hàm tìm và dịch chuyển đến rương an toàn của boss
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
                        task.wait(0.4) 
                        -- Kiểm tra xem có trái cây rơi ra quanh đó không để nhặt
                        collectFruits()
                    end
                end
            end
        end
    end)
end

-- Hàm Server Hop tối ưu
local function serverHop()
    print("[King Script] Đang tìm server mới có Sea King / Hydra...")
    
    local success, err = pcall(function()
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

    if not success then
        task.wait(3)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
end

-- Vòng lặp hoạt động chính
task.spawn(function()
    while _G.RunningKingScript do
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        
        if not humanoidRootPart then
            task.wait(2)
            continue
        end

        print("[King Script] Đã vào game, đang quét môi trường (Chờ 6 giây để load thực thể)...")
        
        -- Chờ để game tải các thực thể boss xuất hiện trên biển
        local waitTimer = 0
        local found = false
        while waitTimer < 6 do
            if hasTargetBoss() then
                found = true
                break
            end
            task.wait(1)
            waitTimer = waitTimer + 1
        end

        if found then
            print("[King Script] Phát hiện Sea King hoặc Hydra! Đang tiến hành farm rương & trái cây...")
            
            local timeout = 0
            while _G.RunningKingScript and hasTargetBoss() and timeout < 35 do
                teleportAndCollectChests()
                collectFruits()
                task.wait(1)
                timeout = timeout + 1
            end
            
            print("[King Script] Đã quét xong rương. Đang dịch chuyển lên cao để an toàn...")
            pcall(function()
                -- Dịch chuyển lên độ cao cực lớn (_G.y) để ẩn nấp trước khi đổi server
                local currentPos = humanoidRootPart.CFrame
                humanoidRootPart.CFrame = CFrame.new(currentPos.X, _G.y, currentPos.Z)
            end)
            task.wait(2)
            
            serverHop()
            task.wait(15)
        else
            print("[King Script] Không thấy Sea King / Hydra. Đang dịch chuyển lên cao và đổi server...")
            pcall(function()
                local currentPos = humanoidRootPart.CFrame
                humanoidRootPart.CFrame = CFrame.new(currentPos.X, _G.y, currentPos.Z)
            end)
            task.wait(1)
            
            serverHop()
            task.wait(15)
        end
        
        task.wait(2)
    end
end)

print("[King Script] Khởi chạy thành công toàn bộ tính năng tự động!")
