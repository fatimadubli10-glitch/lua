local VehicleInputBuffer = {}
VehicleInputBuffer.__index = VehicleInputBuffer

function VehicleInputBuffer.new(capacity: number)
    return setmetatable({
        Capacity = math.max(capacity, 1),
        Entries = {},
        LatestSequence = 0,
    }, VehicleInputBuffer)
end

function VehicleInputBuffer:Push(input)
    if input.Sequence <= self.LatestSequence then
        return false
    end

    self.LatestSequence = input.Sequence
    table.insert(self.Entries, input)

    while #self.Entries > self.Capacity do
        table.remove(self.Entries, 1)
    end

    return true
end

function VehicleInputBuffer:GetLatest()
    return self.Entries[#self.Entries]
end

function VehicleInputBuffer:GetBySequence(sequence: number)
    for index = #self.Entries, 1, -1 do
        local entry = self.Entries[index]
        if entry.Sequence == sequence then
            return entry
        end
    end
    return nil
end

function VehicleInputBuffer:DiscardThrough(sequence: number)
    local retained = {}
    for _, entry in ipairs(self.Entries) do
        if entry.Sequence > sequence then
            table.insert(retained, entry)
        end
    end
    self.Entries = retained
end

function VehicleInputBuffer:Clear()
    table.clear(self.Entries)
    self.LatestSequence = 0
end

function VehicleInputBuffer:Size(): number
    return #self.Entries
end

return VehicleInputBuffer
