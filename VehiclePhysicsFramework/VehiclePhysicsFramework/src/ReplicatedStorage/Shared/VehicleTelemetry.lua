local VehicleTelemetry = {}
VehicleTelemetry.__index = VehicleTelemetry

function VehicleTelemetry.new(config)
    return setmetatable({
        Config = config,
        Samples = {},
        LastSample = 0,
        SampleCount = 0,
    }, VehicleTelemetry)
end

function VehicleTelemetry:Capture(state, now: number)
    if not self.Config.Enabled or now - self.LastSample < self.Config.SampleInterval then
        return
    end

    self.LastSample = now
    local travel = {}
    local contacts = 0

    for name, wheel in pairs(state.Wheels) do
        travel[name] = wheel.Length
        if wheel.Contact then
            contacts += 1
        end
    end

    local powertrain = state.Powertrain:GetState()
    local sample = {
        Time = now,
        Speed = state.Root.AssemblyLinearVelocity.Magnitude,
        ForwardSpeed = state.Root.AssemblyLinearVelocity:Dot(state.Root.CFrame.LookVector),
        LateralSpeed = state.Root.AssemblyLinearVelocity:Dot(state.Root.CFrame.RightVector),
        Acceleration = state.Acceleration.Magnitude,
        Gear = powertrain.Gear,
        RPM = powertrain.RPM,
        Throttle = state.Input.Throttle,
        Brake = state.Input.Brake,
        Steering = state.Input.Steering,
        WheelContacts = contacts,
        Suspension = travel,
        Downforce = state.Downforce,
        Drag = state.DragMagnitude,
    }

    table.insert(self.Samples, sample)
    self.SampleCount += 1

    local maximumSamples = math.ceil(self.Config.HistorySeconds / self.Config.SampleInterval)
    while #self.Samples > maximumSamples do
        table.remove(self.Samples, 1)
    end
end

function VehicleTelemetry:GetLatest()
    return self.Samples[#self.Samples]
end

function VehicleTelemetry:GetSamples()
    return table.clone(self.Samples)
end

function VehicleTelemetry:GetAverageSpeed()
    local total = 0
    for _, sample in ipairs(self.Samples) do
        total += sample.Speed
    end
    if #self.Samples == 0 then
        return 0
    end
    return total / #self.Samples
end

function VehicleTelemetry:GetMaximumSpeed()
    local maximum = 0
    for _, sample in ipairs(self.Samples) do
        maximum = math.max(maximum, sample.Speed)
    end
    return maximum
end

function VehicleTelemetry:Clear()
    table.clear(self.Samples)
    self.LastSample = 0
    self.SampleCount = 0
end

return VehicleTelemetry
