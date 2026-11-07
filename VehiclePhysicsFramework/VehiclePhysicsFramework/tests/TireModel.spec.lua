local TireModel = require(game.ReplicatedStorage.Shared.TireModel)
local Config = require(game.ReplicatedStorage.Shared.VehicleConfig)

return function()
    local grip = TireModel.GetSurfaceGrip(Enum.Material.Asphalt, Config.Tires.SurfaceGrip)
    assert(grip == 1)

    local lowSlip = TireModel.CalculateSlipRatio(20, 20)
    assert(lowSlip == 0)

    local ratio = TireModel.CalculateSlipRatio(20, 25)
    assert(ratio > 0)

    local longitudinal, lateral = TireModel.CalculateForces(
        0.1,
        0.04,
        4000,
        1,
        true,
        Config.Tires
    )

    assert(longitudinal == longitudinal)
    assert(lateral == lateral)
    assert(Vector2.new(longitudinal, lateral).Magnitude <= 4000 * 1.25 + 1)
end
