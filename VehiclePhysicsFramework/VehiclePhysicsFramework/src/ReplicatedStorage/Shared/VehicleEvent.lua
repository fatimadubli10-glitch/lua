local VehicleEvent = {}
VehicleEvent.__index = VehicleEvent

function VehicleEvent.new()
    return setmetatable({
        Listeners = {},
        NextId = 0,
        Destroyed = false,
    }, VehicleEvent)
end

function VehicleEvent:Connect(callback)
    assert(not self.Destroyed, "Event is destroyed")
    assert(typeof(callback) == "function", "Callback must be a function")

    self.NextId += 1
    local id = self.NextId
    local connected = true

    self.Listeners[id] = callback

    local connection = {}
    function connection:Disconnect()
        if not connected then
            return
        end
        connected = false
        self.Listeners = nil
    end

    connection.Disconnect = function()
        if not connected then
            return
        end
        connected = false
        self.Listeners[id] = nil
    end

    return connection
end

function VehicleEvent:Fire(...)
    if self.Destroyed then
        return
    end

    local callbacks = {}
    for _, callback in pairs(self.Listeners) do
        table.insert(callbacks, callback)
    end

    for _, callback in ipairs(callbacks) do
        task.spawn(callback, ...)
    end
end

function VehicleEvent:Once(callback)
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function VehicleEvent:Destroy()
    self.Destroyed = true
    table.clear(self.Listeners)
end

return VehicleEvent
