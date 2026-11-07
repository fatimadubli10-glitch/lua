local VehicleUnitConversion = {}

function VehicleUnitConversion.StudsPerSecondToKilometersPerHour(speed: number, studsPerMeter: number?): number
    return speed / (studsPerMeter or 1) * 3.6
end

function VehicleUnitConversion.KilometersPerHourToStudsPerSecond(speed: number, studsPerMeter: number?): number
    return speed / 3.6 * (studsPerMeter or 1)
end

function VehicleUnitConversion.StudsPerSecondToMilesPerHour(speed: number, studsPerMeter: number?): number
    return speed / (studsPerMeter or 1) * 2.236936
end

function VehicleUnitConversion.MilesPerHourToStudsPerSecond(speed: number, studsPerMeter: number?): number
    return speed / 2.236936 * (studsPerMeter or 1)
end

function VehicleUnitConversion.NewtonsToRobloxForce(newtons: number, scale: number?): number
    return newtons * (scale or 1)
end

function VehicleUnitConversion.KilogramsToRobloxMass(kilograms: number, scale: number?): number
    return kilograms * (scale or 1)
end

return VehicleUnitConversion
