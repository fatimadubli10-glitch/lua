local WheelState = {}
WheelState.__index = WheelState

function WheelState.new(definition, config)
    return setmetatable({
        Definition = definition,
        Config = config,
        Contact = false,
        HitPosition = Vector3.zero,
        HitNormal = Vector3.yAxis,
        Material = Enum.Material.Asphalt,
        Length = config.RestLength,
        PreviousLength = config.RestLength,
        CompressionVelocity = 0,
        SpringForce = 0,
        NormalLoad = 0,
        SurfaceGrip = 1,
        SlipRatio = 0,
        SlipAngle = 0,
        LongitudinalForce = 0,
        LateralForce = 0,
        AngularVelocity = 0,
        SteeringAngle = 0,
        LastContact = 0,
    }, WheelState)
end

function WheelState:UpdateContact(result: RaycastResult?, origin: Vector3, deltaTime: number)
    self.PreviousLength = self.Length

    if result then
        local distance = (origin - result.Position).Magnitude
        self.Length = math.clamp(
            distance - self.Config.WheelRadius,
            self.Config.MinimumLength,
            self.Config.MaximumLength
        )
        self.Contact = true
        self.HitPosition = result.Position
        self.HitNormal = result.Normal
        self.Material = result.Material
        self.LastContact = os.clock()
    else
        self.Length = self.Config.MaximumLength
        self.Contact = false
        self.SpringForce = 0
        self.NormalLoad = 0
    end

    if deltaTime > 0 then
        self.CompressionVelocity = (self.PreviousLength - self.Length) / deltaTime
    else
        self.CompressionVelocity = 0
    end
end

function WheelState:Reset()
    self.Contact = false
    self.Length = self.Config.RestLength
    self.PreviousLength = self.Config.RestLength
    self.CompressionVelocity = 0
    self.SpringForce = 0
    self.NormalLoad = 0
    self.SlipRatio = 0
    self.SlipAngle = 0
    self.LongitudinalForce = 0
    self.LateralForce = 0
    self.AngularVelocity = 0
end

function WheelState:GetCompression(): number
    return math.max(self.Config.RestLength - self.Length, 0)
end

function WheelState:GetDroop(): number
    return math.max(self.Length - self.Config.RestLength, 0)
end

function WheelState:GetTravelAlpha(): number
    return math.clamp(
        (self.Config.MaximumLength - self.Length)
            / math.max(self.Config.MaximumLength - self.Config.MinimumLength, 0.001),
        0,
        1
    )
end

function WheelState:IsRecentlyGrounded(grace: number): boolean
    return self.Contact or os.clock() - self.LastContact <= grace
end

return WheelState
