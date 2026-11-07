local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared.VehicleConfig)
local MathUtility = require(Shared.MathUtility)
local VehicleRaycaster = require(Shared.VehicleRaycaster)
local WheelState = require(Shared.WheelState)
local SuspensionSolver = require(Shared.SuspensionSolver)
local TireModel = require(Shared.TireModel)
local AerodynamicsSolver = require(Shared.AerodynamicsSolver)
local SteeringSolver = require(Shared.SteeringSolver)
local PowertrainSolver = require(Shared.PowertrainSolver)
local VehicleTelemetry = require(Shared.VehicleTelemetry)

local VehicleSimulation = {}
VehicleSimulation.__index = VehicleSimulation

function VehicleSimulation.new(state)
    local self = setmetatable({
        State = state,
        Raycaster = VehicleRaycaster.new(state.Model, Config.Suspension.CollisionGroup),
        Telemetry = VehicleTelemetry.new(Config.Telemetry),
        WheelStates = {},
        Wheelbase = 2.8,
        TrackWidth = 1.6,
    }, VehicleSimulation)

    state.Powertrain = PowertrainSolver.new(Config.Powertrain)

    for _, definition in ipairs(state.WheelDefinitions) do
        self.WheelStates[definition.Name] = WheelState.new(definition, Config.Suspension)
    end

    state.Wheels = self.WheelStates
    return self
end

function VehicleSimulation:GetWheelOrigin(wheel)
    return wheel.Definition.Attachment.WorldPosition
end

function VehicleSimulation:UpdateContacts(deltaTime: number)
    local root = self.State.Root
    for name, wheel in pairs(self.WheelStates) do
        local origin = self:GetWheelOrigin(wheel)
        local rayOrigin, rayDirection = SuspensionSolver.CalculateRay(root.CFrame, origin, Config.Suspension)
        local result = self.Raycaster:CastGround(rayOrigin, rayDirection, name)
        wheel:UpdateContact(result, origin, deltaTime)
    end
end

function VehicleSimulation:ApplySuspension(deltaTime: number)
    local root = self.State.Root
    for _, wheel in pairs(self.WheelStates) do
        wheel.SpringForce = SuspensionSolver.CalculateSpringForce(wheel, Config.Suspension)
        wheel.NormalLoad = SuspensionSolver.CalculateLoad(
            wheel.SpringForce,
            wheel.HitNormal,
            root.CFrame.UpVector
        )
        SuspensionSolver.ApplyWheelForce(root, wheel, deltaTime)
    end

    local frontLeft = self.WheelStates.WheelFL
    local frontRight = self.WheelStates.WheelFR
    local rearLeft = self.WheelStates.WheelRL
    local rearRight = self.WheelStates.WheelRR

    if frontLeft and frontRight then
        local leftForce, rightForce = SuspensionSolver.CalculateAntiRoll(
            frontLeft,
            frontRight,
            Config.Suspension.FrontAntiRollRate
        )
        SuspensionSolver.ApplyAntiRoll(root, frontLeft, leftForce, deltaTime)
        SuspensionSolver.ApplyAntiRoll(root, frontRight, rightForce, deltaTime)
    end

    if rearLeft and rearRight then
        local leftForce, rightForce = SuspensionSolver.CalculateAntiRoll(
            rearLeft,
            rearRight,
            Config.Suspension.RearAntiRollRate
        )
        SuspensionSolver.ApplyAntiRoll(root, rearLeft, leftForce, deltaTime)
        SuspensionSolver.ApplyAntiRoll(root, rearRight, rightForce, deltaTime)
    end
end

function VehicleSimulation:GetWheelVelocity(wheel)
    return self.State.Root:GetVelocityAtPosition(self:GetWheelOrigin(wheel))
end

function VehicleSimulation:CalculateWheelAxes(wheel, steeringAngle: number)
    local root = self.State.Root
    local normal = wheel.HitNormal
    local forward = SteeringSolver.GetWheelForward(root.CFrame, steeringAngle, normal)
    local right = MathUtility.SafeUnit(forward:Cross(normal), root.CFrame.RightVector)
    return forward, right
end

function VehicleSimulation:ApplyTireForces(deltaTime: number)
    local state = self.State
    local root = state.Root
    local speed = root.AssemblyLinearVelocity.Magnitude
    local baseAngle = SteeringSolver.CalculateBaseAngle(
        state.Input.Steering,
        speed,
        Config.Chassis
    )

    for _, wheel in pairs(self.WheelStates) do
        if not wheel.Contact or wheel.NormalLoad <= 0 then
            continue
        end

        local definition = wheel.Definition
        local steeringAngle = if definition.Steerable then baseAngle else 0
        wheel.SteeringAngle = steeringAngle

        if definition.Steerable then
            steeringAngle = SteeringSolver.CalculateAckermann(
                baseAngle,
                self.Wheelbase,
                self.TrackWidth,
                definition.Left
            )
        end

        local forward, right = self:CalculateWheelAxes(wheel, steeringAngle)
        local velocity = self:GetWheelVelocity(wheel)
        local forwardSpeed = velocity:Dot(forward)
        local lateralSpeed = velocity:Dot(right)
        local wheelSurfaceSpeed = wheel.AngularVelocity * Config.Suspension.WheelRadius

        wheel.SlipRatio = TireModel.CalculateSlipRatio(forwardSpeed, wheelSurfaceSpeed)
        wheel.SlipAngle = TireModel.CalculateSlipAngle(forwardSpeed, lateralSpeed)
        wheel.SurfaceGrip = TireModel.GetSurfaceGrip(wheel.Material, Config.Tires.SurfaceGrip)

        local longitudinal, lateral = TireModel.CalculateForces(
            wheel.SlipRatio,
            wheel.SlipAngle,
            wheel.NormalLoad,
            wheel.SurfaceGrip,
            definition.Front,
            Config.Tires
        )

        local drivenForce = 0
        if definition.Driven then
            local engineScale = if state.Input.Throttle < 0
                then Config.Powertrain.ReverseForce / Config.Powertrain.EngineForce
                else 1
            drivenForce = state.EngineForce * engineScale / 4
        end

        local brakeDistribution = if definition.Front
            then Config.Tires.BrakeBias
            else 1 - Config.Tires.BrakeBias
        local brakeForce = state.Input.Brake * Config.Chassis.BrakeForce * brakeDistribution / 2

        if state.Input.Handbrake and not definition.Front then
            brakeForce += Config.Chassis.HandbrakeForce * (1 - Config.Tires.HandbrakeRearGrip)
        end

        longitudinal += drivenForce
        longitudinal -= math.sign(forwardSpeed) * brakeForce
        longitudinal, lateral = TireModel.ApplyFrictionCircle(
            longitudinal,
            lateral,
            wheel.NormalLoad,
            wheel.SurfaceGrip
        )

        wheel.LongitudinalForce = longitudinal
        wheel.LateralForce = lateral

        local combinedForce = forward * longitudinal + right * lateral
        root:ApplyImpulseAtPosition(combinedForce * deltaTime, wheel.HitPosition)

        local angularAcceleration = (drivenForce - longitudinal) / math.max(Config.Suspension.WheelRadius, 0.1)
        wheel.AngularVelocity += angularAcceleration * deltaTime
        wheel.AngularVelocity *= math.exp(-0.35 * deltaTime)
    end
end

function VehicleSimulation:ApplyAerodynamics(deltaTime: number)
    local state = self.State
    local root = state.Root
    local velocity = root.AssemblyLinearVelocity
    local speed = velocity.Magnitude
    local localVelocity = root.CFrame:VectorToObjectSpace(velocity)

    local frontHeight = (self.WheelStates.WheelFL.Length + self.WheelStates.WheelFR.Length) * 0.5
    local rearHeight = (self.WheelStates.WheelRL.Length + self.WheelStates.WheelRR.Length) * 0.5
    local rideScale = AerodynamicsSolver.CalculateRideHeightScale(
        frontHeight,
        rearHeight,
        Config.Suspension.RestLength,
        Config.Aerodynamics
    )

    local downforce = AerodynamicsSolver.CalculateDownforce(speed, Config.Aerodynamics, rideScale)
    local lift = AerodynamicsSolver.CalculateLift(speed, Config.Aerodynamics)
    local drag = AerodynamicsSolver.CalculateDrag(velocity, Config.Aerodynamics)
    local sideForce = root.CFrame:VectorToWorldSpace(
        AerodynamicsSolver.CalculateSideForce(localVelocity, Config.Aerodynamics)
    )
    local yawDamping = AerodynamicsSolver.CalculateYawDamping(
        root.AssemblyAngularVelocity,
        root.CFrame.UpVector,
        Config.Aerodynamics
    )

    local verticalForce = -root.CFrame.UpVector * (downforce - lift)
    root:ApplyImpulse((drag + sideForce + verticalForce) * deltaTime)
    root:ApplyAngularImpulse(yawDamping * deltaTime)

    state.Downforce = downforce
    state.DragMagnitude = drag.Magnitude
end

function VehicleSimulation:UpdatePowertrain(deltaTime: number)
    local root = self.State.Root
    local forwardSpeed = root.AssemblyLinearVelocity:Dot(root.CFrame.LookVector)
    self.State.EngineForce = self.State.Powertrain:Update(
        self.State.Input.Throttle,
        forwardSpeed,
        deltaTime
    )

    if self.State.Input.GearUp then
        self.State.Powertrain:RequestShift(1)
    elseif self.State.Input.GearDown then
        self.State.Powertrain:RequestShift(-1)
    end
end

function VehicleSimulation:ApplyRollingResistance(deltaTime: number)
    local root = self.State.Root
    local velocity = root.AssemblyLinearVelocity
    if velocity.Magnitude < 0.1 then
        return
    end

    local magnitude = velocity.Magnitude * Config.Chassis.RollingResistance * root.AssemblyMass
    root:ApplyImpulse(-velocity.Unit * magnitude * deltaTime)
end

function VehicleSimulation:LimitSpeed()
    local root = self.State.Root
    local forwardSpeed = root.AssemblyLinearVelocity:Dot(root.CFrame.LookVector)
    local maximum = if forwardSpeed >= 0
        then Config.Chassis.MaximumForwardSpeed
        else Config.Chassis.MaximumReverseSpeed

    if math.abs(forwardSpeed) > maximum then
        local target = math.sign(forwardSpeed) * maximum
        local correction = target - forwardSpeed
        root:ApplyImpulse(root.CFrame.LookVector * correction * root.AssemblyMass)
    end
end

function VehicleSimulation:Step(deltaTime: number)
    if self.State.Destroyed or not self.State.Active then
        return
    end

    self.State:UpdateAcceleration(deltaTime)
    self:UpdateContacts(deltaTime)
    self:UpdatePowertrain(deltaTime)
    self:ApplySuspension(deltaTime)
    self:ApplyTireForces(deltaTime)
    self:ApplyAerodynamics(deltaTime)
    self:ApplyRollingResistance(deltaTime)
    self:LimitSpeed()
    self.Telemetry:Capture(self.State, os.clock())
end

function VehicleSimulation:Destroy()
    self.Raycaster:Destroy()
    self.Telemetry:Clear()
    table.clear(self.WheelStates)
end

return VehicleSimulation
