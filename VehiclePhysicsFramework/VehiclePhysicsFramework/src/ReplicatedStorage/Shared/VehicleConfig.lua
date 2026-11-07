local VehicleConfig = {}

VehicleConfig.Simulation = {
    FixedStep = 1 / 120,
    MaximumSubsteps = 8,
    MaximumFrameDelta = 1 / 15,
    InputTimeout = 0.4,
    SnapshotInterval = 1 / 15,
    TelemetryInterval = 0.1,
}

VehicleConfig.Chassis = {
    RootName = "VehicleRoot",
    SeatName = "VehicleSeat",
    MinimumMass = 100,
    MaximumMass = 6000,
    MaximumForwardSpeed = 190,
    MaximumReverseSpeed = 38,
    MaximumSteeringAngle = math.rad(34),
    HighSpeedSteeringReduction = 0.55,
    SteeringResponse = 5,
    BrakeForce = 9500,
    HandbrakeForce = 14500,
    RollingResistance = 0.012,
    MaximumAngularSpeed = 14,
}

VehicleConfig.Suspension = {
    WheelRadius = 1.25,
    RestLength = 1.1,
    MinimumLength = 0.32,
    MaximumLength = 1.65,
    ProbePadding = 0.2,
    SpringRate = 39000,
    CompressionDamping = 4600,
    ReboundDamping = 5400,
    BumpStopRate = 110000,
    MaximumSpringForce = 105000,
    FrontAntiRollRate = 9500,
    RearAntiRollRate = 7600,
    CollisionGroup = "Default",
}

VehicleConfig.Tires = {
    LongitudinalStiffness = 1.3,
    LateralStiffness = 1.5,
    PeakSlipRatio = 0.14,
    PeakSlipAngle = math.rad(8),
    SlidingFloor = 0.42,
    FrontGrip = 1,
    RearGrip = 1,
    BrakeBias = 0.62,
    HandbrakeRearGrip = 0.2,
    SurfaceGrip = {
        Asphalt = 1,
        Concrete = 0.96,
        Metal = 1.02,
        Brick = 0.88,
        Cobblestone = 0.82,
        Grass = 0.6,
        Ground = 0.58,
        Sand = 0.5,
        Mud = 0.42,
        Ice = 0.15,
        Wood = 0.75,
    },
}

VehicleConfig.Powertrain = {
    EngineForce = 11200,
    ReverseForce = 4200,
    EngineBrakeForce = 550,
    IdleRPM = 850,
    MaximumRPM = 7800,
    ShiftUpRPM = 6900,
    ShiftDownRPM = 2300,
    ShiftDuration = 0.2,
    FinalDrive = 3.5,
    GearRatios = {3.15, 2.18, 1.58, 1.22, 0.98, 0.8},
    ThrottleResponse = 4.5,
}

VehicleConfig.Aerodynamics = {
    AirDensity = 1.225,
    DragCoefficient = 0.33,
    FrontalArea = 2.15,
    DownforceCoefficient = 1.9,
    ReferenceArea = 2.1,
    MaximumDownforce = 72000,
    MaximumDrag = 20000,
    FrontBalance = 0.52,
    SideForceCoefficient = 0.65,
    YawDamping = 1350,
    LiftCoefficient = -0.06,
    GroundEffectStrength = 0.12,
}

VehicleConfig.Camera = {
    Enabled = true,
    PositionFrequency = 5.5,
    PositionDamping = 0.92,
    RotationFrequency = 4.3,
    RotationDamping = 0.9,
    FOVFrequency = 3.5,
    VelocityLag = 0.016,
    AccelerationLag = 0.0015,
    MaximumPositionOffset = 1.35,
    MaximumRotationOffset = math.rad(8),
    BaseFOV = 70,
    MaximumFOV = 89,
    FOVPerSpeed = 0.05,
    CollisionRadius = 0.35,
    CollisionPadding = 0.16,
}

VehicleConfig.Network = {
    MaximumInput = 1,
    MaximumSequenceGap = 120,
    CorrectionDistance = 6,
    CorrectionVelocity = 20,
}

VehicleConfig.Telemetry = {
    Enabled = true,
    HistorySeconds = 45,
    SampleInterval = 0.1,
}

return VehicleConfig
