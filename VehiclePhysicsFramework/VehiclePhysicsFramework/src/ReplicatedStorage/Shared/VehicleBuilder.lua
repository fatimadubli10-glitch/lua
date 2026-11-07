local VehicleBuilder = {}

local WheelLayout = {
    {Name = "WheelFL", Front = true, Left = true, Steerable = true, Driven = true, Braked = true},
    {Name = "WheelFR", Front = true, Left = false, Steerable = true, Driven = true, Braked = true},
    {Name = "WheelRL", Front = false, Left = true, Steerable = false, Driven = true, Braked = true},
    {Name = "WheelRR", Front = false, Left = false, Steerable = false, Driven = true, Braked = true},
}

function VehicleBuilder.FindRoot(model: Model, config): BasePart?
    local root = model:FindFirstChild(config.RootName, true)
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

function VehicleBuilder.FindSeat(model: Model, config): Seat?
    local seat = model:FindFirstChild(config.SeatName, true)
    if seat and (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
        return seat
    end
    return nil
end

function VehicleBuilder.FindWheels(model: Model)
    local definitions = {}
    local errors = {}

    for _, entry in ipairs(WheelLayout) do
        local attachment = model:FindFirstChild(entry.Name, true)
        if attachment and attachment:IsA("Attachment") then
            table.insert(definitions, {
                Name = entry.Name,
                Attachment = attachment,
                Front = entry.Front,
                Left = entry.Left,
                Steerable = entry.Steerable,
                Driven = entry.Driven,
                Braked = entry.Braked,
            })
        else
            table.insert(errors, "Missing wheel attachment " .. entry.Name)
        end
    end

    return definitions, errors
end

function VehicleBuilder.Validate(model: Model, config)
    local errors = {}
    local root = VehicleBuilder.FindRoot(model, config)
    local seat = VehicleBuilder.FindSeat(model, config)
    local wheels, wheelErrors = VehicleBuilder.FindWheels(model)

    if not root then
        table.insert(errors, "VehicleRoot BasePart missing")
    elseif root.Anchored then
        table.insert(errors, "VehicleRoot must be unanchored")
    end

    if not seat then
        table.insert(errors, "VehicleSeat or Seat missing")
    end

    for _, message in ipairs(wheelErrors) do
        table.insert(errors, message)
    end

    if root then
        local mass = root.AssemblyMass
        if mass < config.MinimumMass or mass > config.MaximumMass then
            table.insert(errors, string.format("Assembly mass %.1f is outside configured range", mass))
        end
    end

    return #errors == 0, errors, root, seat, wheels
end

return VehicleBuilder
