local SuspensionSolver = {}

function SuspensionSolver.CalculateSpringForce(wheel, config): number
    if not wheel.Contact then
        return 0
    end

    local compression = config.RestLength - wheel.Length
    local spring = compression * config.SpringRate
    local dampingRate = if wheel.CompressionVelocity >= 0
        then config.CompressionDamping
        else config.ReboundDamping
    local damping = wheel.CompressionVelocity * dampingRate
    local bump = math.max(config.MinimumLength - wheel.Length, 0) * config.BumpStopRate
    return math.clamp(spring + damping + bump, 0, config.MaximumSpringForce)
end

function SuspensionSolver.CalculateLoad(force: number, normal: Vector3, chassisUp: Vector3): number
    local alignment = math.max(normal:Dot(chassisUp), 0.18)
    return force / alignment
end

function SuspensionSolver.CalculateAntiRoll(leftWheel, rightWheel, rate: number)
    local leftCompression = leftWheel:GetCompression()
    local rightCompression = rightWheel:GetCompression()
    local force = (leftCompression - rightCompression) * rate

    if not leftWheel.Contact then
        force = math.min(force, 0)
    end
    if not rightWheel.Contact then
        force = math.max(force, 0)
    end

    return -force, force
end

function SuspensionSolver.CalculateRay(rootCFrame: CFrame, origin: Vector3, config)
    local direction = -rootCFrame.UpVector
    local distance = config.MaximumLength + config.WheelRadius + config.ProbePadding
    return origin, direction * distance
end

function SuspensionSolver.CalculateForceAtWheel(wheel, rootUp: Vector3): Vector3
    if not wheel.Contact or wheel.SpringForce <= 0 then
        return Vector3.zero
    end
    return wheel.HitNormal * wheel.SpringForce
end

function SuspensionSolver.ApplyWheelForce(root: BasePart, wheel, deltaTime: number)
    local force = SuspensionSolver.CalculateForceAtWheel(wheel, root.CFrame.UpVector)
    if force.Magnitude > 0 then
        root:ApplyImpulseAtPosition(force * deltaTime, wheel.HitPosition)
    end
end

function SuspensionSolver.ApplyAntiRoll(root: BasePart, wheel, force: number, deltaTime: number)
    if wheel.Contact and force ~= 0 then
        root:ApplyImpulseAtPosition(root.CFrame.UpVector * force * deltaTime, wheel.HitPosition)
    end
end

return SuspensionSolver
