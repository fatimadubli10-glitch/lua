local VehicleRuntimeState = {}
VehicleRuntimeState.__index = VehicleRuntimeState

function VehicleRuntimeState.new(model: Model, root: BasePart, seat: Seat, definitions)
    return setmetatable({
        Model = model,
        Root = root,
        Seat = seat,
        WheelDefinitions = definitions,
        Wheels = {},
        Driver = nil,
        Active = false,
        Destroyed = false,
        Input = {
            Throttle = 0,
            Brake = 1,
            Steering = 0,
            Handbrake = false,
            GearUp = false,
            GearDown = false,
            Sequence = 0,
            ClientTime = 0,
        },
        LastInputTime = os.clock(),
        LastVelocity = root.AssemblyLinearVelocity,
        Acceleration = Vector3.zero,
        Downforce = 0,
        DragMagnitude = 0,
        SnapshotSequence = 0,
        EngineForce = 0,
        Powertrain = nil,
    }, VehicleRuntimeState)
end

function VehicleRuntimeState:SetInput(input)
    self.Input = input
    self.LastInputTime = os.clock()
end

function VehicleRuntimeState:ResetInput()
    self.Input = {
        Throttle = 0,
        Brake = 1,
        Steering = 0,
        Handbrake = false,
        GearUp = false,
        GearDown = false,
        Sequence = self.Input.Sequence,
        ClientTime = self.Input.ClientTime,
    }
end

function VehicleRuntimeState:UpdateAcceleration(deltaTime: number)
    if deltaTime <= 0 then
        return
    end
    local velocity = self.Root.AssemblyLinearVelocity
    self.Acceleration = (velocity - self.LastVelocity) / deltaTime
    self.LastVelocity = velocity
end

function VehicleRuntimeState:Destroy()
    self.Destroyed = true
    self.Active = false
    table.clear(self.Wheels)
end

return VehicleRuntimeState
