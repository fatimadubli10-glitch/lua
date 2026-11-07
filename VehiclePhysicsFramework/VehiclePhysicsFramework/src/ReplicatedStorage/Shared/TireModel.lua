local TireModel = {}

local function responseCurve(slip: number, peak: number, floorGrip: number): number
    local normalized = math.abs(slip) / math.max(peak, 0.0001)
    local rise = 1 - math.exp(-normalized * 1.9)
    local falloff = 1 / (1 + math.max(normalized - 1, 0) * 0.38)
    return math.max(floorGrip, rise * falloff)
end

function TireModel.GetSurfaceGrip(material: Enum.Material, surfaces): number
    return surfaces[material.Name] or 0.72
end

function TireModel.CalculateSlipRatio(forwardSpeed: number, wheelSpeed: number): number
    local denominator = math.max(math.abs(forwardSpeed), math.abs(wheelSpeed), 2)
    return (wheelSpeed - forwardSpeed) / denominator
end

function TireModel.CalculateSlipAngle(forwardSpeed: number, lateralSpeed: number): number
    return math.atan2(lateralSpeed, math.max(math.abs(forwardSpeed), 0.5))
end

function TireModel.CalculateForces(slipRatio: number, slipAngle: number, normalLoad: number, grip: number, front: boolean, config)
    local axleGrip = if front then config.FrontGrip else config.RearGrip
    local longitudinalResponse = responseCurve(slipRatio, config.PeakSlipRatio, config.SlidingFloor)
    local lateralResponse = responseCurve(slipAngle, config.PeakSlipAngle, config.SlidingFloor)

    local longitudinal = slipRatio * config.LongitudinalStiffness * normalLoad * longitudinalResponse
    local lateral = -slipAngle * config.LateralStiffness * normalLoad * lateralResponse
    longitudinal *= grip * axleGrip
    lateral *= grip * axleGrip

    return TireModel.ApplyFrictionCircle(longitudinal, lateral, normalLoad, grip * axleGrip)
end

function TireModel.ApplyFrictionCircle(longitudinal: number, lateral: number, normalLoad: number, grip: number)
    local maximum = math.max(normalLoad * grip * 1.25, 0)
    local combined = Vector2.new(longitudinal, lateral)
    if combined.Magnitude > maximum and combined.Magnitude > 0 then
        combined = combined.Unit * maximum
    end
    return combined.X, combined.Y
end

function TireModel.CalculateRollingResistance(speed: number, normalLoad: number, coefficient: number): number
    return -math.sign(speed) * normalLoad * coefficient
end

return TireModel
