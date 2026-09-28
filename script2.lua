-- Khởi tạo giao diện menu
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "KingLegacy_AutoHop"
ScreenGui.ResetOnSpawn = false

MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.5, -100, 0.4, -85)
MainFrame.Size = UDim2.new(0, 200, 0, 140)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "King Legacy Auto Hop"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14

ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
ToggleButton.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleButton.Size = UDim2.new(0.8, 0, 0, 40)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Trạng thái: TẮT"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 15

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.1, 0, 0.75, 0)
StatusLabel.Size = UDim2.new(0.8, 0, 0, 25)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "Trạng thái: Đang nghỉ"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 13

_G.AutoHopRunning = false

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Hàm dịch chuyển mượt mà tới mục tiêu (Rương / Boss)
local function TweenTo(targetPosition)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    
    local distance = (hrp.Position - targetPosition).Magnitude
    local speed = 300 -- Tốc độ bay (studs/s)
    local timeToTravel = distance / speed
    
    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPosition + Vector3.new(0, 5, 0))})
    
    tween:Play()
    task.wait(timeToTravel)
end

-- Hàm đổi Server thông minh
local function HopServer()
    StatusLabel.Text = "Đang tìm server khác..."
    local success, serverList = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and serverList and serverList.data then
        for _, server in ipairs(serverList.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end
end

-- Hàm kiểm tra và tìm Rương hoặc Boss Sea King / Hydra
local function FindAndCollectTarget()
    local foundTarget = false
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if _G.AutoHopRunning == false then break end
        
        local name = obj.Name:lower()
        -- Kiểm tra rương hoặc boss
        if name:find("chest") or name:find("seaking") or name:find("hydra") then
            -- Nếu tìm thấy đối tượng có phần cơ thể/vị trí hợp lệ
            local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
            
            if targetPart then
                foundTarget = true
                StatusLabel.Text = "Đã thấy: " .. obj.Name
                print("Đang dịch chuyển tới mục tiêu: " .. obj.Name)
                
                -- Bay tới vị trí mục tiêu
                TweenTo(targetPart.Position)
                task.wait(1)
                break
            end
        end
    end
    
    return foundTarget
end

-- Xử lý nút bấm Bật/Tắt
ToggleButton.MouseButton1Click:Connect(function()
    _G.AutoHopRunning = not _G.AutoHopRunning
    if _G.AutoHopRunning then
        ToggleButton.Text = "Trạng thái: BẬT"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
        StatusLabel.Text = "Đang quét mục tiêu..."
    else
        ToggleButton.Text = "Trạng thái: TẮT"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
        StatusLabel.Text = "Đã dừng."
    end
end)

-- Vòng lặp chính xử lý tính năng
task.spawn(function()
    while true do
        task.wait(2)
        if _G.AutoHopRunning then
            local successFound = FindAndCollectTarget()
            if not successFound then
                -- Nếu không tìm thấy rương hay boss trong server này -> Đổi server ngay
                StatusLabel.Text = "Không thấy mục tiêu, đổi server..."
                HopServer()
                task.wait(10) -- Chờ thời gian load đổi server
            else
                task.wait(3)
            end
        end
    end
end)
