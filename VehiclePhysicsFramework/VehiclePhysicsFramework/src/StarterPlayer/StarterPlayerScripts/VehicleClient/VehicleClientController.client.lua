local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.VehicleConfig)
local InputController = require(script.Parent.InputController)
local CameraController = require(script.Parent.CameraController)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("VehicleRemotes")
local inputRemote = remotes:WaitForChild("VehicleInput")
local snapshotRemote = remotes:WaitForChild("VehicleSnapshot")
local occupancyRemote = remotes:WaitForChild("VehicleOccupancy")

local inputController = InputController.new()
local cameraController = CameraController.new()

local currentVehicle = nil
local currentRoot = nil
local inputSequence = 0
local sendAccumulator = 0
local lastSnapshotSequence = 0

local function getRoot(model: Model): BasePart?
    local root = model:FindFirstChild(Config.Chassis.RootName, true)
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function setVehicle(model: Model?)
    currentVehicle = model
    currentRoot = if model then getRoot(model) else nil
    inputSequence = 0
    lastSnapshotSequence = 0

    if currentRoot then
        inputController:Enable()
        cameraController:SetVehicle(currentRoot)
        cameraController:Enable()
    else
        inputController:Disable()
        cameraController:Disable()
    end
end

occupancyRemote.OnClientEvent:Connect(function(model, driver)
    if driver == player then
        setVehicle(model)
    elseif currentVehicle == model then
        setVehicle(nil)
    end
end)

snapshotRemote.OnClientEvent:Connect(function(model, snapshot)
    if model ~= currentVehicle or not currentRoot then
        return
    end
    if typeof(snapshot) ~= "table" or snapshot.Sequence <= lastSnapshotSequence then
        return
    end

    lastSnapshotSequence = snapshot.Sequence

    local positionError = (currentRoot.Position - snapshot.CFrame.Position).Magnitude
    local velocityError = (currentRoot.AssemblyLinearVelocity - snapshot.LinearVelocity).Magnitude

    if positionError > Config.Network.CorrectionDistance
        or velocityError > Config.Network.CorrectionVelocity then
        currentRoot.AssemblyLinearVelocity = snapshot.LinearVelocity
        currentRoot.AssemblyAngularVelocity = snapshot.AngularVelocity
    end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    cameraController:Render(deltaTime)
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if not currentVehicle or not currentRoot or not currentRoot.Parent then
        return
    end

    sendAccumulator += deltaTime
    if sendAccumulator < Config.Simulation.InputTimeout / 8 then
        return
    end
    sendAccumulator = 0

    local values = inputController:GetValues()
    inputSequence += 1

    inputRemote:FireServer({
        Throttle = values.Throttle,
        Brake = values.Brake,
        Steering = values.Steering,
        Handbrake = values.Handbrake,
        GearUp = values.GearUp,
        GearDown = values.GearDown,
        Sequence = inputSequence,
        ClientTime = workspace:GetServerTimeNow(),
    })

    inputController:ConsumeGearEdges()
end)

player.CharacterAdded:Connect(function()
    setVehicle(nil)
end)
