local VehicleRaycaster = {}
VehicleRaycaster.__index = VehicleRaycaster

function VehicleRaycaster.new(vehicle: Model, collisionGroup: string)
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = {vehicle}
    parameters.IgnoreWater = false
    parameters.CollisionGroup = collisionGroup

    return setmetatable({
        Vehicle = vehicle,
        Parameters = parameters,
        Results = {},
    }, VehicleRaycaster)
end

function VehicleRaycaster:Cast(origin: Vector3, direction: Vector3, key: string): RaycastResult?
    if direction.Magnitude <= 1e-6 then
        self.Results[key] = nil
        return nil
    end
    local result = workspace:Raycast(origin, direction, self.Parameters)
    self.Results[key] = result
    return result
end

function VehicleRaycaster:CastGround(origin: Vector3, direction: Vector3, key: string, minimumNormalY: number?): RaycastResult?
    local result = self:Cast(origin, direction, key)
    if not result then
        return nil
    end
    if result.Normal.Y < (minimumNormalY or -0.2) then
        return nil
    end
    return result
end

function VehicleRaycaster:CastMany(casts: {{Origin: Vector3, Direction: Vector3, Key: string}})
    local results = {}
    for _, cast in ipairs(casts) do
        results[cast.Key] = self:Cast(cast.Origin, cast.Direction, cast.Key)
    end
    return results
end

function VehicleRaycaster:GetResult(key: string): RaycastResult?
    return self.Results[key]
end

function VehicleRaycaster:RefreshFilter()
    self.Parameters.FilterDescendantsInstances = {self.Vehicle}
end

function VehicleRaycaster:Destroy()
    table.clear(self.Results)
end

return VehicleRaycaster
