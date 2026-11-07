local Solver = require(game.ReplicatedStorage.Shared.AerodynamicsSolver)
local Config = require(game.ReplicatedStorage.Shared.VehicleConfig)

return function()
    assert(Solver.DynamicPressure(0, Config.Aerodynamics.AirDensity) == 0)
    assert(Solver.CalculateDownforce(0, Config.Aerodynamics) == 0)

    local low = Solver.CalculateDownforce(30, Config.Aerodynamics)
    local high = Solver.CalculateDownforce(60, Config.Aerodynamics)
    assert(high > low)

    local drag = Solver.CalculateDrag(Vector3.new(0, 0, -50), Config.Aerodynamics)
    assert(drag.Z > 0)

    local front, rear = Solver.SplitDownforce(1000, 0.5)
    assert(front == 500)
    assert(rear == 500)
end
