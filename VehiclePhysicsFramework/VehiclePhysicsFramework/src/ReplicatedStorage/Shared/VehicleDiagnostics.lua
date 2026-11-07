local VehicleDiagnostics = {}

function VehicleDiagnostics.ValidateFiniteVector(value: Vector3, label: string)
    local errors = {}
    if value.X ~= value.X or value.Y ~= value.Y or value.Z ~= value.Z then
        table.insert(errors, label .. " contains NaN")
    end
    if math.abs(value.X) == math.huge or math.abs(value.Y) == math.huge or math.abs(value.Z) == math.huge then
        table.insert(errors, label .. " contains infinity")
    end
    return #errors == 0, errors
end

function VehicleDiagnostics.ValidateRoot(root: BasePart)
    local errors = {}
    if root.Anchored then
        table.insert(errors, "Root is anchored")
    end
    if root.AssemblyMass <= 0 then
        table.insert(errors, "Root assembly mass is not positive")
    end
    local linearValid, linearErrors = VehicleDiagnostics.ValidateFiniteVector(root.AssemblyLinearVelocity, "Linear velocity")
    local angularValid, angularErrors = VehicleDiagnostics.ValidateFiniteVector(root.AssemblyAngularVelocity, "Angular velocity")
    if not linearValid then
        table.move(linearErrors, 1, #linearErrors, #errors + 1, errors)
    end
    if not angularValid then
        table.move(angularErrors, 1, #angularErrors, #errors + 1, errors)
    end
    return #errors == 0, errors
end

function VehicleDiagnostics.DescribeWheel(wheel)
    return {
        Name = wheel.Definition.Name,
        Contact = wheel.Contact,
        Length = wheel.Length,
        Compression = wheel:GetCompression(),
        Droop = wheel:GetDroop(),
        SpringForce = wheel.SpringForce,
        NormalLoad = wheel.NormalLoad,
        SlipRatio = wheel.SlipRatio,
        SlipAngle = wheel.SlipAngle,
        Grip = wheel.SurfaceGrip,
    }
end

function VehicleDiagnostics.DescribeVehicle(state)
    local wheels = {}
    for name, wheel in pairs(state.Wheels) do
        wheels[name] = VehicleDiagnostics.DescribeWheel(wheel)
    end

    local powertrain = state.Powertrain:GetState()
    return {
        Model = state.Model:GetFullName(),
        Active = state.Active,
        Driver = if state.Driver then state.Driver.UserId else nil,
        Speed = state.Root.AssemblyLinearVelocity.Magnitude,
        ForwardSpeed = state.Root.AssemblyLinearVelocity:Dot(state.Root.CFrame.LookVector),
        AngularSpeed = state.Root.AssemblyAngularVelocity.Magnitude,
        EngineRPM = powertrain.RPM,
        Gear = powertrain.Gear,
        Downforce = state.Downforce,
        Drag = state.DragMagnitude,
        Wheels = wheels,
    }
end

return VehicleDiagnostics
