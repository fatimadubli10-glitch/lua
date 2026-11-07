local PowertrainSolver = {}
PowertrainSolver.__index = PowertrainSolver

function PowertrainSolver.new(config)
    return setmetatable({
        Config = config,
        Gear = 1,
        RPM = config.IdleRPM,
        Throttle = 0,
        ShiftTimer = 0,
        WheelSpeed = 0,
        EngineForce = 0,
    }, PowertrainSolver)
end

function PowertrainSolver:RequestShift(direction: number)
    if self.ShiftTimer > 0 then
        return false
    end

    local target = math.clamp(self.Gear + math.sign(direction), 1, #self.Config.GearRatios)
    if target == self.Gear then
        return false
    end

    self.Gear = target
    self.ShiftTimer = self.Config.ShiftDuration
    return true
end

function PowertrainSolver:GetRatio(): number
    return self.Config.GearRatios[self.Gear] * self.Config.FinalDrive
end

function PowertrainSolver:Update(throttle: number, wheelSpeed: number, deltaTime: number): number
    self.Throttle += (throttle - self.Throttle) * (1 - math.exp(-self.Config.ThrottleResponse * deltaTime))
    self.WheelSpeed = math.abs(wheelSpeed)
    self.ShiftTimer = math.max(0, self.ShiftTimer - deltaTime)

    local coupledRPM = self.WheelSpeed * self:GetRatio() * 60 / (math.pi * 2)
    local targetRPM = math.max(self.Config.IdleRPM, coupledRPM + self.Throttle * 1200)
    self.RPM += (targetRPM - self.RPM) * math.clamp(deltaTime * 7, 0, 1)
    self.RPM = math.clamp(self.RPM, self.Config.IdleRPM, self.Config.MaximumRPM)

    if self.RPM >= self.Config.ShiftUpRPM then
        self:RequestShift(1)
    elseif self.RPM <= self.Config.ShiftDownRPM then
        self:RequestShift(-1)
    end

    local rpmAlpha = self.RPM / self.Config.MaximumRPM
    local torqueScale = 1 - rpmAlpha * 0.32
    local shiftScale = if self.ShiftTimer > 0 then 0.4 else 1
    self.EngineForce = self.Throttle * self.Config.EngineForce * torqueScale * shiftScale
    return self.EngineForce
end

function PowertrainSolver:GetState()
    return {
        Gear = self.Gear,
        RPM = self.RPM,
        Throttle = self.Throttle,
        ShiftTimer = self.ShiftTimer,
        EngineForce = self.EngineForce,
    }
end

function PowertrainSolver:Reset()
    self.Gear = 1
    self.RPM = self.Config.IdleRPM
    self.Throttle = 0
    self.ShiftTimer = 0
    self.EngineForce = 0
end

return PowertrainSolver
