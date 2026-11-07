local VehicleDebug = {}

function VehicleDebug.Log(enabled: boolean, ...)
    if enabled then
        print("[VehiclePhysics]", ...)
    end
end

function VehicleDebug.Warn(enabled: boolean, ...)
    if enabled then
        warn("[VehiclePhysics]", ...)
    end
end

function VehicleDebug.DrawRay(origin: Vector3, direction: Vector3, color: Color3, duration: number?)
    local part = Instance.new("Part")
    part.Name = "VehicleRayDebug"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Size = Vector3.new(0.035, 0.035, direction.Magnitude)
    part.CFrame = CFrame.lookAt(origin + direction * 0.5, origin + direction)
    part.Parent = workspace
    game:GetService("Debris"):AddItem(part, duration or 0.08)
    return part
end

function VehicleDebug.DrawPoint(position: Vector3, color: Color3, duration: number?)
    local part = Instance.new("Part")
    part.Name = "VehiclePointDebug"
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(0.16, 0.16, 0.16)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Parent = workspace
    game:GetService("Debris"):AddItem(part, duration or 0.08)
    return part
end

return VehicleDebug
