local SpringSolver = {}
SpringSolver.__index = SpringSolver

function SpringSolver.new(initial: Vector3?, frequency: number?, damping: number?, mass: number?)
    local position = initial or Vector3.zero
    return setmetatable({
        Position = position,
        Velocity = Vector3.zero,
        Target = position,
        Frequency = frequency or 5,
        Damping = damping or 0.9,
        Mass = math.max(mass or 1, 0.001),
        MaximumSpeed = math.huge,
    }, SpringSolver)
end

function SpringSolver:Reset(position: Vector3)
    self.Position = position
    self.Target = position
    self.Velocity = Vector3.zero
end

function SpringSolver:SetTarget(target: Vector3)
    self.Target = target
end

function SpringSolver:SetFrequency(frequency: number)
    self.Frequency = math.max(frequency, 0.01)
end

function SpringSolver:SetDamping(damping: number)
    self.Damping = math.max(damping, 0)
end

function SpringSolver:SetMass(mass: number)
    self.Mass = math.max(mass, 0.001)
end

function SpringSolver:SetMaximumSpeed(speed: number)
    self.MaximumSpeed = math.max(speed, 0)
end

function SpringSolver:Impulse(impulse: Vector3)
    self.Velocity += impulse / self.Mass
end

function SpringSolver:Step(deltaTime: number): Vector3
    local remaining = math.max(deltaTime, 0)
    if remaining == 0 then
        return self.Position
    end

    local frequency = math.max(self.Frequency, 0.01)
    local angularFrequency = frequency * math.pi * 2
    local stiffness = angularFrequency * angularFrequency
    local damping = 2 * self.Damping * angularFrequency

    while remaining > 0 do
        local step = math.min(remaining, 1 / 120)
        local displacement = self.Position - self.Target
        local acceleration = -displacement * stiffness - self.Velocity * damping
        self.Velocity += acceleration * step

        if self.Velocity.Magnitude > self.MaximumSpeed then
            self.Velocity = self.Velocity.Unit * self.MaximumSpeed
        end

        self.Position += self.Velocity * step
        remaining -= step
    end

    return self.Position
end

function SpringSolver:StepScalar(deltaTime: number): number
    return self:Step(deltaTime).X
end

function SpringSolver:GetVelocity(): Vector3
    return self.Velocity
end

function SpringSolver:GetPosition(): Vector3
    return self.Position
end

function SpringSolver:GetTarget(): Vector3
    return self.Target
end

function SpringSolver:GetError(): Vector3
    return self.Target - self.Position
end

function SpringSolver:IsSettled(threshold: number?): boolean
    local limit = threshold or 0.001
    return self:GetError().Magnitude <= limit and self.Velocity.Magnitude <= limit
end

function SpringSolver:Clone()
    local clone = SpringSolver.new(self.Position, self.Frequency, self.Damping, self.Mass)
    clone.Target = self.Target
    clone.Velocity = self.Velocity
    clone.MaximumSpeed = self.MaximumSpeed
    return clone
end

return SpringSolver
