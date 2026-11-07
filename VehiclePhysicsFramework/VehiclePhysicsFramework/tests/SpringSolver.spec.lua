local SpringSolver = require(game.ReplicatedStorage.Shared.SpringSolver)

return function()
    local spring = SpringSolver.new(Vector3.zero, 6, 0.9)
    spring:SetTarget(Vector3.new(10, 0, 0))

    for _ = 1, 600 do
        spring:Step(1 / 120)
    end

    assert((spring:GetPosition() - spring:GetTarget()).Magnitude < 0.1)
    assert(spring:GetVelocity().Magnitude < 0.1)

    spring:Reset(Vector3.zero)
    spring:Impulse(Vector3.new(5, 0, 0))
    assert(spring:GetVelocity().X > 0)

    local clone = spring:Clone()
    assert(clone:GetPosition() == spring:GetPosition())
    assert(clone:GetVelocity() == spring:GetVelocity())
end
