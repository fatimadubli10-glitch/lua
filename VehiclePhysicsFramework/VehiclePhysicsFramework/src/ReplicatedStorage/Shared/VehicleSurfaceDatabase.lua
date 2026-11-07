local VehicleSurfaceDatabase = {}

local SurfaceProperties = {
    Asphalt = {Grip = 1, Rolling = 0.012, Dust = false, WetGrip = 0.82},
    Concrete = {Grip = 0.96, Rolling = 0.013, Dust = false, WetGrip = 0.8},
    Metal = {Grip = 1.02, Rolling = 0.01, Dust = false, WetGrip = 0.9},
    Brick = {Grip = 0.88, Rolling = 0.02, Dust = false, WetGrip = 0.72},
    Cobblestone = {Grip = 0.82, Rolling = 0.024, Dust = false, WetGrip = 0.68},
    Grass = {Grip = 0.6, Rolling = 0.035, Dust = true, WetGrip = 0.48},
    Ground = {Grip = 0.58, Rolling = 0.04, Dust = true, WetGrip = 0.45},
    Sand = {Grip = 0.5, Rolling = 0.07, Dust = true, WetGrip = 0.42},
    Mud = {Grip = 0.42, Rolling = 0.09, Dust = true, WetGrip = 0.3},
    Ice = {Grip = 0.15, Rolling = 0.008, Dust = false, WetGrip = 0.12},
    Wood = {Grip = 0.75, Rolling = 0.025, Dust = false, WetGrip = 0.62},
}

function VehicleSurfaceDatabase.Get(material: Enum.Material)
    return SurfaceProperties[material.Name] or {
        Grip = 0.72,
        Rolling = 0.02,
        Dust = false,
        WetGrip = 0.6,
    }
end

function VehicleSurfaceDatabase.GetGrip(material: Enum.Material, wet: boolean?): number
    local properties = VehicleSurfaceDatabase.Get(material)
    return if wet then properties.WetGrip else properties.Grip
end

function VehicleSurfaceDatabase.GetRollingResistance(material: Enum.Material): number
    return VehicleSurfaceDatabase.Get(material).Rolling
end

function VehicleSurfaceDatabase.IsLoose(material: Enum.Material): boolean
    return VehicleSurfaceDatabase.Get(material).Dust
end

function VehicleSurfaceDatabase.GetAll()
    return table.clone(SurfaceProperties)
end

return VehicleSurfaceDatabase
