local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.VehicleConfig)
local VehicleBuilder = require(ReplicatedStorage.Shared.VehicleBuilder)
local VehicleRuntimeState = require(ReplicatedStorage.Shared.VehicleRuntimeState)
local InputValidator = require(script.Parent.InputValidator)
local VehicleSimulation = require(script.Parent.VehicleSimulation)

local VehicleService = {}
VehicleService.__index = VehicleService

function VehicleService.new()
    return setmetatable({
        Vehicles = {},
        PlayerVehicles = {},
        Remotes = {},
        Accumulator = 0,
        SnapshotAccumulator = 0,
        Started = false,
        Connections = {},
    }, VehicleService)
end

function VehicleService:GetOrCreateFolder()
    local folder = ReplicatedStorage:FindFirstChild("VehicleRemotes")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "VehicleRemotes"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

function VehicleService:GetOrCreateRemote(folder: Folder, name: string): RemoteEvent
    local remote = folder:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    if remote then
        remote:Destroy()
    end
    local created = Instance.new("RemoteEvent")
    created.Name = name
    created.Parent = folder
    return created
end

function VehicleService:InitializeRemotes()
    local folder = self:GetOrCreateFolder()
    self.Remotes.Input = self:GetOrCreateRemote(folder, "VehicleInput")
    self.Remotes.Snapshot = self:GetOrCreateRemote(folder, "VehicleSnapshot")
    self.Remotes.Occupancy = self:GetOrCreateRemote(folder, "VehicleOccupancy")
end

function VehicleService:RegisterVehicle(model: Model): boolean
    if self.Vehicles[model] then
        return true
    end

    local valid, errors, root, seat, definitions = VehicleBuilder.Validate(model, Config.Chassis)
    if not valid then
        warn("Vehicle registration rejected", model:GetFullName(), table.concat(errors, " | "))
        return false
    end

    local state = VehicleRuntimeState.new(model, root, seat, definitions)
    local simulation = VehicleSimulation.new(state)
    local record = {
        State = state,
        Simulation = simulation,
        SeatConnection = nil,
    }

    self.Vehicles[model] = record
    record.SeatConnection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        self:UpdateOccupant(model)
    end)

    self:UpdateOccupant(model)
    return true
end

function VehicleService:UpdateOccupant(model: Model)
    local record = self.Vehicles[model]
    if not record then
        return
    end

    local humanoid = record.State.Seat.Occupant
    local player = if humanoid then Players:GetPlayerFromCharacter(humanoid.Parent) else nil
    local previous = record.State.Driver

    if previous and previous ~= player then
        self.PlayerVehicles[previous] = nil
        InputValidator.Forget(previous)
        record.State:ResetInput()
    end

    record.State.Driver = player
    record.State.Active = player ~= nil

    if player then
        self.PlayerVehicles[player] = model
        record.State.Root:SetNetworkOwner(nil)
    end

    self.Remotes.Occupancy:FireAllClients(model, player)
end

function VehicleService:ReceiveInput(player: Player, payload)
    local model = self.PlayerVehicles[player]
    if not model then
        return
    end

    local record = self.Vehicles[model]
    if not record or record.State.Driver ~= player or not record.State.Active then
        return
    end

    local input, reason = InputValidator.Validate(player, payload)
    if not input then
        if reason then
            warn("Rejected vehicle input", player.UserId, reason)
        end
        return
    end

    record.State:SetInput(input)
end

function VehicleService:StepVehicles(deltaTime: number)
    for model, record in pairs(self.Vehicles) do
        if not model.Parent or record.State.Destroyed then
            self:UnregisterVehicle(model)
            continue
        end

        local state = record.State
        if state.Active and os.clock() - state.LastInputTime > Config.Simulation.InputTimeout then
            state:ResetInput()
        end

        record.Simulation:Step(deltaTime)
    end
end

function VehicleService:SendSnapshots()
    for model, record in pairs(self.Vehicles) do
        local state = record.State
        if not state.Active or not state.Driver then
            continue
        end

        state.SnapshotSequence += 1
        self.Remotes.Snapshot:FireClient(state.Driver, model, {
            Sequence = state.SnapshotSequence,
            ServerTime = workspace:GetServerTimeNow(),
            CFrame = state.Root.CFrame,
            LinearVelocity = state.Root.AssemblyLinearVelocity,
            AngularVelocity = state.Root.AssemblyAngularVelocity,
            Gear = state.Powertrain:GetState().Gear,
            RPM = state.Powertrain:GetState().RPM,
        })
    end
end

function VehicleService:UnregisterVehicle(model: Model)
    local record = self.Vehicles[model]
    if not record then
        return
    end

    if record.SeatConnection then
        record.SeatConnection:Disconnect()
    end

    local driver = record.State.Driver
    if driver then
        self.PlayerVehicles[driver] = nil
        InputValidator.Forget(driver)
    end

    record.Simulation:Destroy()
    record.State:Destroy()
    self.Vehicles[model] = nil
end

function VehicleService:DiscoverVehicles()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Model") and descendant:GetAttribute("VehicleEnabled") == true then
            self:RegisterVehicle(descendant)
        end
    end
end

function VehicleService:BindDiscovery()
    table.insert(self.Connections, workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Model") and descendant:GetAttribute("VehicleEnabled") == true then
            task.defer(function()
                if descendant.Parent then
                    self:RegisterVehicle(descendant)
                end
            end)
        end
    end))
end

function VehicleService:BindPlayers()
    table.insert(self.Connections, Players.PlayerRemoving:Connect(function(player)
        local model = self.PlayerVehicles[player]
        if model then
            local record = self.Vehicles[model]
            if record then
                record.State.Active = false
                record.State.Driver = nil
                record.State:ResetInput()
            end
        end
        self.PlayerVehicles[player] = nil
        InputValidator.Forget(player)
    end))
end

function VehicleService:BindSimulation()
    table.insert(self.Connections, RunService.Heartbeat:Connect(function(deltaTime)
        self.Accumulator += math.min(deltaTime, Config.Simulation.MaximumFrameDelta)
        local steps = 0

        while self.Accumulator >= Config.Simulation.FixedStep
            and steps < Config.Simulation.MaximumSubsteps do
            self:StepVehicles(Config.Simulation.FixedStep)
            self.Accumulator -= Config.Simulation.FixedStep
            steps += 1
        end

        if steps >= Config.Simulation.MaximumSubsteps then
            self.Accumulator = 0
        end

        self.SnapshotAccumulator += deltaTime
        if self.SnapshotAccumulator >= Config.Simulation.SnapshotInterval then
            self.SnapshotAccumulator %= Config.Simulation.SnapshotInterval
            self:SendSnapshots()
        end
    end))
end

function VehicleService:Start()
    if self.Started then
        return
    end
    self.Started = true
    self:InitializeRemotes()

    table.insert(self.Connections, self.Remotes.Input.OnServerEvent:Connect(function(player, payload)
        self:ReceiveInput(player, payload)
    end))

    self:DiscoverVehicles()
    self:BindDiscovery()
    self:BindPlayers()
    self:BindSimulation()
end

function VehicleService:Destroy()
    for model in pairs(self.Vehicles) do
        self:UnregisterVehicle(model)
    end
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
    self.Started = false
end

return VehicleService
