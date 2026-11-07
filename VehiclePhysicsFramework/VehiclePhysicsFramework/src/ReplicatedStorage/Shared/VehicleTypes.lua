export type InputState = {
    Throttle: number,
    Brake: number,
    Steering: number,
    Handbrake: boolean,
    GearUp: boolean,
    GearDown: boolean,
    Sequence: number,
    ClientTime: number,
}

export type WheelDefinition = {
    Name: string,
    Attachment: Attachment,
    Front: boolean,
    Left: boolean,
    Steerable: boolean,
    Driven: boolean,
    Braked: boolean,
}

export type WheelState = {
    Definition: WheelDefinition,
    Contact: boolean,
    HitPosition: Vector3,
    HitNormal: Vector3,
    Material: Enum.Material,
    Length: number,
    PreviousLength: number,
    CompressionVelocity: number,
    SpringForce: number,
    NormalLoad: number,
    SurfaceGrip: number,
    SlipRatio: number,
    SlipAngle: number,
    LongitudinalForce: number,
    LateralForce: number,
    AngularVelocity: number,
    SteeringAngle: number,
}

export type Snapshot = {
    Sequence: number,
    ServerTime: number,
    CFrame: CFrame,
    LinearVelocity: Vector3,
    AngularVelocity: Vector3,
    Gear: number,
    RPM: number,
}

return {}
