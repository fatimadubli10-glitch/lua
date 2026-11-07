# Vehicle Physics Framework

Roblox Luau framework for a custom welded BasePart chassis, raycast suspension, spring camera, tire forces, drivetrain, aerodynamics, server-authoritative simulation, client input, and telemetry.

## Setup

1. Build a vehicle Model with an unanchored `VehicleRoot` BasePart.
2. Add a `VehicleSeat` (or `Seat`) named `VehicleSeat`.
3. Add four Attachments under the root or anywhere under the model: `WheelFL`, `WheelFR`, `WheelRL`, `WheelRR`.
4. Weld the chassis parts into one assembly.
5. Set the Model attribute `VehicleEnabled` to `true`.
6. Install the `src` tree using Rojo and build the place.
7. Tune `VehicleConfig` for the dimensions and mass of the actual vehicle.

## Controls

- W / Up: throttle
- S / Down: brake / reverse
- A / Left and D / Right: steering
- Space: handbrake
- E: upshift
- Q: downshift

## Architecture

- Server owns vehicle physics and validates all input.
- Client sends bounded input samples and runs camera effects.
- Client never submits position, velocity, forces, or contact results.
- Wheel contact is determined by raycasts. Wheel visuals are optional.
- No interface is created by this framework.

## Vehicle model contract

```text
VehicleModel
├── VehicleRoot (BasePart)
├── VehicleSeat (VehicleSeat or Seat)
├── WheelFL (Attachment)
├── WheelFR (Attachment)
├── WheelRL (Attachment)
└── WheelRR (Attachment)
```

The root's forward axis is local -Z. Root up is local +Y.

This repository is a substantial starting framework, not a guarantee that one tuning profile suits every chassis. Validate suspension, tire curves, braking, aerodynamic balance, replication, and collision behavior in Studio with your own vehicle.
