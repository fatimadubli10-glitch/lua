local VehicleTuning = require(game.ReplicatedStorage.Shared.VehicleTuning)

return function()
    local springRate = VehicleTuning.CalculateSpringRate(2, 250)
    assert(springRate > 0)

    local damping = VehicleTuning.CalculateDamping(springRate, 250, 0.9)
    assert(damping > 0)

    local frequency = VehicleTuning.EstimateRideFrequency(springRate, 250)
    assert(math.abs(frequency - 2) < 1e-5)

    local stoppingDistance = VehicleTuning.EstimateStoppingDistance(30, 10)
    assert(stoppingDistance == 45)

    assert(VehicleTuning.EstimateLateralAcceleration(20, 10) == 40)
end
