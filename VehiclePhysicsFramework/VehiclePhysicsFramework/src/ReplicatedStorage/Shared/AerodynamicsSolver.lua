local AerodynamicsSolver = {}

function AerodynamicsSolver.DynamicPressure(speed: number, density: number): number
    return 0.5 * density * speed * speed
end

function AerodynamicsSolver.CalculateDrag(velocity: Vector3, config): Vector3
    local speed = velocity.Magnitude
    if speed < 0.05 then
        return Vector3.zero
    end
    local pressure = AerodynamicsSolver.DynamicPressure(speed, config.AirDensity)
    local force = pressure * config.DragCoefficient * config.FrontalArea
    force = math.min(force, config.MaximumDrag)
    return -velocity.Unit * force
end

function AerodynamicsSolver.CalculateDownforce(speed: number, config, rideScale: number?): number
    local pressure = AerodynamicsSolver.DynamicPressure(speed, config.AirDensity)
    local force = pressure * config.DownforceCoefficient * config.ReferenceArea
    force *= math.clamp(rideScale or 1, 0.65, 1.2)
    return math.clamp(force, 0, config.MaximumDownforce)
end

function AerodynamicsSolver.CalculateLift(speed: number, config): number
    local pressure = AerodynamicsSolver.DynamicPressure(speed, config.AirDensity)
    return pressure * config.LiftCoefficient * config.ReferenceArea
end

function AerodynamicsSolver.CalculateSideForce(localVelocity: Vector3, config): Vector3
    local lateral = localVelocity.X
    return Vector3.new(
        -lateral * math.abs(lateral) * config.SideForceCoefficient,
        0,
        0
    )
end

function AerodynamicsSolver.CalculateYawDamping(angularVelocity: Vector3, up: Vector3, config): Vector3
    return -up * angularVelocity:Dot(up) * config.YawDamping
end

function AerodynamicsSolver.CalculateRideHeightScale(frontHeight: number, rearHeight: number, restLength: number, config): number
    local average = (frontHeight + rearHeight) * 0.5
    local relative = (restLength - average) / math.max(restLength, 0.1)
    return 1 + math.clamp(relative * config.GroundEffectStrength, -0.2, 0.2)
end

function AerodynamicsSolver.SplitDownforce(total: number, frontBalance: number)
    local front = total * math.clamp(frontBalance, 0.1, 0.9)
    return front, total - front
end

return AerodynamicsSolver
