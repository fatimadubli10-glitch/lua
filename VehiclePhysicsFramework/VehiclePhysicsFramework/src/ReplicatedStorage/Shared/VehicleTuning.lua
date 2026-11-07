local VehicleTuning = {}

function VehicleTuning.CalculateSpringRate(targetFrequency: number, sprungMass: number): number
    local angularFrequency = targetFrequency * math.pi * 2
    return angularFrequency * angularFrequency * sprungMass
end

function VehicleTuning.CalculateDamping(springRate: number, sprungMass: number, dampingRatio: number): number
    return 2 * dampingRatio * math.sqrt(math.max(springRate * sprungMass, 0))
end

function VehicleTuning.CalculateWheelSprungMass(totalMass: number, wheelCount: number, frontWeightBias: number, front: boolean): number
    local axleShare = if front then frontWeightBias else 1 - frontWeightBias
    return totalMass * axleShare / math.max(wheelCount / 2, 1)
end

function VehicleTuning.EstimateRideFrequency(springRate: number, sprungMass: number): number
    if sprungMass <= 0 then
        return 0
    end
    return math.sqrt(springRate / sprungMass) / (math.pi * 2)
end

function VehicleTuning.EstimateStaticCompression(sprungMass: number, springRate: number, gravity: number): number
    if springRate <= 0 then
        return 0
    end
    return sprungMass * gravity / springRate
end

function VehicleTuning.EstimateAeroForce(speed: number, density: number, coefficient: number, area: number): number
    return 0.5 * density * speed * speed * coefficient * area
end

function VehicleTuning.EstimateStoppingDistance(speed: number, deceleration: number): number
    if deceleration <= 0 then
        return math.huge
    end
    return speed * speed / (2 * deceleration)
end

function VehicleTuning.EstimateLateralAcceleration(speed: number, radius: number): number
    if radius <= 0 then
        return math.huge
    end
    return speed * speed / radius
end

function VehicleTuning.EstimateRequiredGrip(speed: number, radius: number, gravity: number): number
    return VehicleTuning.EstimateLateralAcceleration(speed, radius) / gravity
end

return VehicleTuning
