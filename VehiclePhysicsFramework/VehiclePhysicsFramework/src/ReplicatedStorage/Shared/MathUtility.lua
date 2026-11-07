local MathUtility = {}

function MathUtility.Clamp(value: number, minimum: number, maximum: number): number
    return math.clamp(value, minimum, maximum)
end

function MathUtility.ClampVector(value: Vector3, maximum: number): Vector3
    local magnitude = value.Magnitude
    if magnitude <= maximum or magnitude <= 1e-6 then
        return value
    end
    return value * (maximum / magnitude)
end

function MathUtility.SafeUnit(value: Vector3, fallback: Vector3): Vector3
    if value.Magnitude <= 1e-6 then
        return fallback
    end
    return value.Unit
end

function MathUtility.ProjectOnPlane(value: Vector3, normal: Vector3): Vector3
    return value - normal * value:Dot(normal)
end

function MathUtility.ExpAlpha(response: number, deltaTime: number): number
    return 1 - math.exp(-math.max(response, 0) * math.max(deltaTime, 0))
end

function MathUtility.MoveTowards(current: number, target: number, maximumDelta: number): number
    local difference = target - current
    if math.abs(difference) <= maximumDelta then
        return target
    end
    return current + math.sign(difference) * maximumDelta
end

function MathUtility.SafeDivide(numerator: number, denominator: number, fallback: number?): number
    if math.abs(denominator) <= 1e-7 then
        return fallback or 0
    end
    return numerator / denominator
end

function MathUtility.Remap(value: number, inputMinimum: number, inputMaximum: number, outputMinimum: number, outputMaximum: number): number
    local alpha = MathUtility.SafeDivide(value - inputMinimum, inputMaximum - inputMinimum)
    alpha = math.clamp(alpha, 0, 1)
    return outputMinimum + (outputMaximum - outputMinimum) * alpha
end

function MathUtility.SmoothStep(value: number): number
    local alpha = math.clamp(value, 0, 1)
    return alpha * alpha * (3 - 2 * alpha)
end

function MathUtility.IsFinite(value: number): boolean
    return value == value and value ~= math.huge and value ~= -math.huge
end

function MathUtility.IsFiniteVector(value: Vector3): boolean
    return MathUtility.IsFinite(value.X)
        and MathUtility.IsFinite(value.Y)
        and MathUtility.IsFinite(value.Z)
end

function MathUtility.LerpAngle(first: number, second: number, alpha: number): number
    local difference = (second - first + math.pi) % (math.pi * 2) - math.pi
    return first + difference * math.clamp(alpha, 0, 1)
end

function MathUtility.QuadraticResistance(speed: number, coefficient: number): number
    return speed * math.abs(speed) * coefficient
end

function MathUtility.VectorToLocal(frame: CFrame, vector: Vector3): Vector3
    return frame:VectorToObjectSpace(vector)
end

function MathUtility.VectorToWorld(frame: CFrame, vector: Vector3): Vector3
    return frame:VectorToWorldSpace(vector)
end

function MathUtility.Average(values: {number}): number
    if #values == 0 then
        return 0
    end
    local total = 0
    for _, value in ipairs(values) do
        total += value
    end
    return total / #values
end

function MathUtility.Deadzone(value: number, threshold: number): number
    if math.abs(value) <= threshold then
        return 0
    end
    return math.sign(value) * ((math.abs(value) - threshold) / (1 - threshold))
end

return MathUtility
