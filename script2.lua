-- [[ KING LEGACY: ADVANCED SEA KING & HYDRA OPTIMIZED SCRIPT ]] --

_G.webhook = _G.webhook or "Enter"
_G.fixhop = _G.fixhop or false
_G.y = _G.y or 1500

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

-- 1. Tự động nhấn phím Enter khi vào game
task.spawn(function()
    pcall(function()
        task.wait(2)
        VirtualUser:Button1Down(Vector2.new(0,0))
        VirtualUser:Button1Up(Vector2.new(0,0))
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        print("[King Script] Đã tự động nhấn Enter!")
    end)
end)

-- Hàm quét siêu rộng tìm Sea King, Hydra hoặc các thực thể biển liên quan
local function hasTargetBoss()
    local success, result = pcall(function()
        -- Duyệt qua toàn bộ Workspace
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v and (v:IsA("Model") or v:IsA("Folder")) then
                local name = v.Name:lower()
                if name:find("seaking") or name:find("hydra") or name:find("sea king") or name:find("terror") then
                    return true
                end
            end
        end
        return false
    end)
    return success and result
end

-- Hàm nhặt trái cây
local function collectFruits()
    pcall(function()
        for _, v in ipairs(Workspace:GetChildren()) do
            if v and v:IsA("Tool") and v:FindFirstChild("Handle") then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = v.Handle.CFrame
                    task.wait(0.3)
                end
            end
        end
    end)
end

-- Hàm nhặt rương
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
                        rootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.4) 
                        collectFruits()
                    end
                end
            end
        end
    end)
end

-- Hàm Server Hop thông minh hơn (tránh lặp lại các server vừa check)
local visitedServers = {}

local function serverHop()
    print("[King Script] Đang tìm server mới...")
    local success, err = pcall(function()
        local servers = {}
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(url))
        
        if response and response.data then
            for _, server in ipairs(response.data) do
                if server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    -- Kiểm tra xem server này đã vào gần đây chưa để tránh quay vòng
                    local alreadyVisited = false
                    for _, id in ipairs(visitedServers) do
                        if id == server.id then alreadyVisited = true break end
                    end
                    
                    if not alreadyVisited then
                        table.insert(servers, server.id)
                    end
                end
            end
        end

        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            table.insert(visitedServers, randomServer)
            if #visitedServers > 20 then table.remove(visitedServers, 1) end -- Giữ bộ nhớ gọn
            
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
        else
            visitedServers = {} -- Reset nếu hết server sạch
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

-- Vòng lặp chính
task.spawn(function()
    while _G.RunningKingScript do
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        
        if not humanoidRootPart then
            task.wait(2)
            continue
        end

        print("[King Script] Đã vào server mới. Đang quét kỹ môi trường (Chờ 10 giây để tải sự kiện biển)...")
        
        -- Tăng thời gian chờ lên 10 giây vì Sea King/Hydra đôi khi load chậm hơn các object khác
        local waitTimer = 0
        local found = false
        while waitTimer < 10 do
            if hasTargetBoss() then
                found = true
                break
            end
            task.wait(1)
            waitTimer = waitTimer + 1
        end

        if found then
            print("[King Script] Phát hiện Sea King hoặc Hydra! Tiến hành farm...")
            local timeout = 0
            while _G.RunningKingScript and hasTargetBoss() and timeout < 40 do
                teleportAndCollectChests()
                collectFruits()
                task.wait(1)
                timeout = timeout + 1
            end
            
            print("[King Script] Hoàn thành. Bay lên cao an toàn...")
            pcall(function()
                local currentPos = humanoidRootPart.CFrame
                humanoidRootPart.CFrame = CFrame.new(currentPos.X, _G.y, currentPos.Z)
            end)
            task.wait(2)
            serverHop()
            task.wait(15)
        else
            print("[King Script] Không thấy boss. Bay lên cao và đổi server...")
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

print("[King Script] Đã nâng cấp thuật toán quét sâu và chống lặp server!")
