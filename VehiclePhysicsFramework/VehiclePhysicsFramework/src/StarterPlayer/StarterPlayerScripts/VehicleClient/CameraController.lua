local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.VehicleConfig)
local SpringSolver = require(ReplicatedStorage.Shared.SpringSolver)
local MathUtility = require(ReplicatedStorage.Shared.MathUtility)

local CameraController = {}
CameraController.__index = CameraController

function CameraController.new()
    return setmetatable({
        Player = Players.LocalPlayer,
        Root = nil,
        PositionSpring = SpringSolver.new(Vector3.zero, Config.Camera.PositionFrequency, Config.Camera.PositionDamping),
        RotationSpring = SpringSolver.new(Vector3.zero, Config.Camera.RotationFrequency, Config.Camera.RotationDamping),
        FOVSpring = SpringSolver.new(Vector3.new(Config.Camera.BaseFOV, 0, 0), Config.Camera.FOVFrequency, 1),
        PreviousVelocity = Vector3.zero,
        Enabled = false,
        PreviousCameraType = nil,
        PreviousCameraSubject = nil,
    }, CameraController)
end

function CameraController:SetVehicle(root: BasePart?)
    self.Root = root
    if root then
        self.PreviousVelocity = root.AssemblyLinearVelocity
        self.PositionSpring:Reset(Vector3.zero)
        self.RotationSpring:Reset(Vector3.zero)
    end
end

function CameraController:CalculateTargets(deltaTime: number)
    local root = self.Root
    if not root then
        return Vector3.zero, Vector3.zero, Config.Camera.BaseFOV
    end

    local velocity = root.AssemblyLinearVelocity
    local acceleration = (velocity - self.PreviousVelocity) / math.max(deltaTime, 1 / 240)
    self.PreviousVelocity = velocity

    local localVelocity = root.CFrame:VectorToObjectSpace(velocity)
    local localAcceleration = root.CFrame:VectorToObjectSpace(acceleration)

    local position = Vector3.new(
        -localVelocity.X * Config.Camera.VelocityLag - localAcceleration.X * Config.Camera.AccelerationLag,
        -localAcceleration.Y * Config.Camera.AccelerationLag,
        localVelocity.Z * Config.Camera.VelocityLag * 0.3
    )
    position = MathUtility.ClampVector(position, Config.Camera.MaximumPositionOffset)

    local rotation = Vector3.new(
        math.clamp(localAcceleration.Z * 0.001, -Config.Camera.MaximumRotationOffset, Config.Camera.MaximumRotationOffset),
        math.clamp(-localVelocity.X * 0.002, -Config.Camera.MaximumRotationOffset, Config.Camera.MaximumRotationOffset),
        math.clamp(-localAcceleration.X * 0.0015, -Config.Camera.MaximumRotationOffset, Config.Camera.MaximumRotationOffset)
    )

    local targetFOV = math.clamp(
        Config.Camera.BaseFOV + velocity.Magnitude * Config.Camera.FOVPerSpeed,
        Config.Camera.BaseFOV,
        Config.Camera.MaximumFOV
    )

    return position, rotation, targetFOV
end

function CameraController:ResolveCollision(position: Vector3, focus: Vector3): Vector3
    local direction = position - focus
    if direction.Magnitude <= 0.01 then
        return position
    end

    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = {self.Player.Character, self.Root}

    local result = workspace:Spherecast(
        focus,
        Config.Camera.CollisionRadius,
        direction,
        parameters
    )

    if result then
        return result.Position + result.Normal * Config.Camera.CollisionPadding
    end

    return position
end

function CameraController:Render(deltaTime: number)
    if not self.Enabled or not self.Root then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local positionTarget, rotationTarget, fovTarget = self:CalculateTargets(deltaTime)
    self.PositionSpring:SetTarget(positionTarget)
    self.RotationSpring:SetTarget(rotationTarget)
    self.FOVSpring:SetTarget(Vector3.new(fovTarget, 0, 0))

    local positionOffset = self.PositionSpring:Step(deltaTime)
    local rotationOffset = self.RotationSpring:Step(deltaTime)
    local fov = self.FOVSpring:Step(deltaTime).X

    local root = self.Root
    local focus = root.Position + root.CFrame.LookVector * 4
    local cameraPosition = root.Position - root.CFrame.LookVector * 10 + root.CFrame.UpVector * 3.5
    cameraPosition += root.CFrame:VectorToWorldSpace(positionOffset)
    cameraPosition = self:ResolveCollision(cameraPosition, focus)

    local baseFrame = CFrame.lookAt(cameraPosition, focus, root.CFrame.UpVector)
    local rotationFrame = CFrame.Angles(rotationOffset.X, rotationOffset.Y, rotationOffset.Z)
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = baseFrame * rotationFrame
    camera.FieldOfView = fov
end

function CameraController:Enable()
    if self.Enabled then
        return
    end
    self.Enabled = true

    local camera = workspace.CurrentCamera
    if camera then
        self.PreviousCameraType = camera.CameraType
        self.PreviousCameraSubject = camera.CameraSubject
    end
end

function CameraController:Disable()
    self.Enabled = false
    self.Root = nil

    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = self.PreviousCameraType or Enum.CameraType.Custom
        camera.CameraSubject = self.PreviousCameraSubject
        camera.FieldOfView = Config.Camera.BaseFOV
    end
end

return CameraController
