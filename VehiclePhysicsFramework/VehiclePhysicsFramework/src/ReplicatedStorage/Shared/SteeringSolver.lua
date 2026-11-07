local SteeringSolver = {}

function SteeringSolver.CalculateBaseAngle(input: number, speed: number, chassisConfig): number
    local speedAlpha = math.clamp(speed / chassisConfig.MaximumForwardSpeed, 0, 1)
    local reduction = 1 - speedAlpha * chassisConfig.HighSpeedSteeringReduction
    return math.clamp(input, -1, 1) * chassisConfig.MaximumSteeringAngle * reduction
end

function SteeringSolver.CalculateAckermann(baseAngle: number, wheelbase: number, track: number, leftWheel: boolean): number
    if math.abs(baseAngle) < 1e-5 then
        return 0
    end

    local radius = wheelbase / math.tan(math.abs(baseAngle))
    local innerRadius = math.max(radius - track * 0.5, 0.1)
    local outerRadius = radius + track * 0.5
    local innerAngle = math.atan(wheelbase / innerRadius)
    local outerAngle = math.atan(wheelbase / outerRadius)
    local innerOnLeft = baseAngle > 0
    local isInner = leftWheel == innerOnLeft
    return math.sign(baseAngle) * (if isInner then innerAngle else outerAngle)
end

function SteeringSolver.GetWheelForward(rootCFrame: CFrame, steeringAngle: number, normal: Vector3): Vector3
    local localDirection = CFrame.Angles(0, steeringAngle, 0):VectorToWorldSpace(Vector3.new(0, 0, -1))
    local worldDirection = rootCFrame:VectorToWorldSpace(localDirection)
    local projected = worldDirection - normal * worldDirection:Dot(normal)
    if projected.Magnitude < 1e-5 then
        return rootCFrame.LookVector
    end
    return projected.Unit
end

return SteeringSolver
