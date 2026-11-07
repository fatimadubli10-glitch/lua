local PowertrainSolver = require(game.ReplicatedStorage.Shared.PowertrainSolver)
local Config = require(game.ReplicatedStorage.Shared.VehicleConfig)

return function()
    local powertrain = PowertrainSolver.new(Config.Powertrain)
    assert(powertrain.Gear == 1)
    assert(powertrain.RPM == Config.Powertrain.IdleRPM)

    for _ = 1, 240 do
        powertrain:Update(1, 45, 1 / 120)
    end

    assert(powertrain.RPM <= Config.Powertrain.MaximumRPM)
    assert(powertrain.EngineForce > 0)

    local previousGear = powertrain.Gear
    powertrain:RequestShift(1)
    assert(powertrain.Gear >= previousGear)
end
