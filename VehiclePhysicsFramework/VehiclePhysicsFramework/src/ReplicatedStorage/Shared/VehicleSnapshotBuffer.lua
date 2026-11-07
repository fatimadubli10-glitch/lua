local VehicleSnapshotBuffer = {}
VehicleSnapshotBuffer.__index = VehicleSnapshotBuffer

function VehicleSnapshotBuffer.new(capacity: number)
    return setmetatable({
        Capacity = math.max(capacity, 1),
        Entries = {},
        LatestSequence = 0,
    }, VehicleSnapshotBuffer)
end

function VehicleSnapshotBuffer:Push(snapshot)
    if snapshot.Sequence <= self.LatestSequence then
        return false
    end

    self.LatestSequence = snapshot.Sequence
    table.insert(self.Entries, snapshot)

    while #self.Entries > self.Capacity do
        table.remove(self.Entries, 1)
    end

    return true
end

function VehicleSnapshotBuffer:GetLatest()
    return self.Entries[#self.Entries]
end

function VehicleSnapshotBuffer:GetPrevious()
    return self.Entries[#self.Entries - 1]
end

function VehicleSnapshotBuffer:GetInterpolated(serverTime: number)
    if #self.Entries == 0 then
        return nil
    end

    local first = self.Entries[1]
    if serverTime <= first.ServerTime then
        return first
    end

    for index = 2, #self.Entries do
        local previous = self.Entries[index - 1]
        local current = self.Entries[index]
        if serverTime <= current.ServerTime then
            local duration = current.ServerTime - previous.ServerTime
            local alpha = if duration > 0 then (serverTime - previous.ServerTime) / duration else 1
            return {
                Sequence = current.Sequence,
                ServerTime = serverTime,
                CFrame = previous.CFrame:Lerp(current.CFrame, alpha),
                LinearVelocity = previous.LinearVelocity:Lerp(current.LinearVelocity, alpha),
                AngularVelocity = previous.AngularVelocity:Lerp(current.AngularVelocity, alpha),
                Gear = current.Gear,
                RPM = previous.RPM + (current.RPM - previous.RPM) * alpha,
            }
        end
    end

    return self.Entries[#self.Entries]
end

function VehicleSnapshotBuffer:Clear()
    table.clear(self.Entries)
    self.LatestSequence = 0
end

return VehicleSnapshotBuffer
