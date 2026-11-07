local VehicleDamageModel = {}
VehicleDamageModel.__index = VehicleDamageModel

function VehicleDamageModel.new()
    return setmetatable({
        EngineHealth = 1,
        SuspensionHealth = {
            WheelFL = 1,
            WheelFR = 1,
            WheelRL = 1,
            WheelRR = 1,
        },
        TireHealth = {
            WheelFL = 1,
            WheelFR = 1,
            WheelRL = 1,
            WheelRR = 1,
        },
        Alignment = Vector2.zero,
        TotalImpactEnergy = 0,
    }, VehicleDamageModel)
end

function VehicleDamageModel:ApplyImpact(energy: number, wheelName: string?)
    local boundedEnergy = math.max(energy, 0)
    self.TotalImpactEnergy += boundedEnergy
    local severity = math.clamp(boundedEnergy / 150000, 0, 0.45)

    if wheelName and self.SuspensionHealth[wheelName] then
        self.SuspensionHealth[wheelName] = math.max(0, self.SuspensionHealth[wheelName] - severity)
        self.TireHealth[wheelName] = math.max(0, self.TireHealth[wheelName] - severity * 0.7)
    else
        self.EngineHealth = math.max(0, self.EngineHealth - severity * 0.25)
    end
end

function VehicleDamageModel:GetSuspensionMultiplier(wheelName: string): number
    return self.SuspensionHealth[wheelName] or 1
end

function VehicleDamageModel:GetTireMultiplier(wheelName: string): number
    return self.TireHealth[wheelName] or 1
end

function VehicleDamageModel:SetAlignment(value: Vector2)
    self.Alignment = Vector2.new(
        math.clamp(value.X, -0.25, 0.25),
        math.clamp(value.Y, -0.25, 0.25)
    )
end

function VehicleDamageModel:Repair()
    self.EngineHealth = 1
    self.TotalImpactEnergy = 0
    self.Alignment = Vector2.zero
    for name in pairs(self.SuspensionHealth) do
        self.SuspensionHealth[name] = 1
        self.TireHealth[name] = 1
    end
end

return VehicleDamageModel
