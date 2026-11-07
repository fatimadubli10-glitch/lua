local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.VehicleConfig)

local InputValidator = {}
local LastSequence = {}

local function isFinite(value): boolean
    return typeof(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

function InputValidator.Validate(player: Player, payload)
    if typeof(payload) ~= "table" then
        return nil, "Invalid payload type"
    end

    local sequence = payload.Sequence
    if not isFinite(sequence) or sequence % 1 ~= 0 then
        return nil, "Invalid sequence number"
    end

    local previous = LastSequence[player] or 0
    if sequence <= previous then
        return nil, "Stale input sequence"
    end
    if sequence - previous > Config.Network.MaximumSequenceGap then
        return nil, "Input sequence gap too large"
    end

    if not isFinite(payload.Throttle)
        or not isFinite(payload.Brake)
        or not isFinite(payload.Steering) then
        return nil, "Invalid numeric input"
    end

    LastSequence[player] = sequence

    return {
        Throttle = math.clamp(payload.Throttle, -Config.Network.MaximumInput, Config.Network.MaximumInput),
        Brake = math.clamp(payload.Brake, 0, Config.Network.MaximumInput),
        Steering = math.clamp(payload.Steering, -Config.Network.MaximumInput, Config.Network.MaximumInput),
        Handbrake = payload.Handbrake == true,
        GearUp = payload.GearUp == true,
        GearDown = payload.GearDown == true,
        Sequence = sequence,
        ClientTime = if isFinite(payload.ClientTime) then payload.ClientTime else 0,
    }
end

function InputValidator.Forget(player: Player)
    LastSequence[player] = nil
end

return InputValidator
