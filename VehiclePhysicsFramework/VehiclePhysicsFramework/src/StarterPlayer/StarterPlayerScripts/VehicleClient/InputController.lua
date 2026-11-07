local UserInputService = game:GetService("UserInputService")

local InputController = {}
InputController.__index = InputController

function InputController.new()
    return setmetatable({
        Enabled = false,
        Connections = {},
        ThrottleHeld = false,
        BrakeHeld = false,
        LeftHeld = false,
        RightHeld = false,
        HandbrakeHeld = false,
        GearUpPressed = false,
        GearDownPressed = false,
        Values = {
            Throttle = 0,
            Brake = 0,
            Steering = 0,
            Handbrake = false,
            GearUp = false,
            GearDown = false,
        },
    }, InputController)
end

function InputController:Refresh()
    self.Values.Throttle = if self.ThrottleHeld then 1 else 0
    self.Values.Brake = if self.BrakeHeld then 1 else 0
    self.Values.Steering = (if self.RightHeld then 1 else 0) - (if self.LeftHeld then 1 else 0)
    self.Values.Handbrake = self.HandbrakeHeld
end

function InputController:HandleBegan(input, processed)
    if processed or not self.Enabled then
        return
    end

    local key = input.KeyCode
    if key == Enum.KeyCode.W or key == Enum.KeyCode.Up then
        self.ThrottleHeld = true
    elseif key == Enum.KeyCode.S or key == Enum.KeyCode.Down then
        self.BrakeHeld = true
    elseif key == Enum.KeyCode.A or key == Enum.KeyCode.Left then
        self.LeftHeld = true
    elseif key == Enum.KeyCode.D or key == Enum.KeyCode.Right then
        self.RightHeld = true
    elseif key == Enum.KeyCode.Space then
        self.HandbrakeHeld = true
    elseif key == Enum.KeyCode.E then
        self.GearUpPressed = true
    elseif key == Enum.KeyCode.Q then
        self.GearDownPressed = true
    end

    self:Refresh()
end

function InputController:HandleEnded(input)
    local key = input.KeyCode
    if key == Enum.KeyCode.W or key == Enum.KeyCode.Up then
        self.ThrottleHeld = false
    elseif key == Enum.KeyCode.S or key == Enum.KeyCode.Down then
        self.BrakeHeld = false
    elseif key == Enum.KeyCode.A or key == Enum.KeyCode.Left then
        self.LeftHeld = false
    elseif key == Enum.KeyCode.D or key == Enum.KeyCode.Right then
        self.RightHeld = false
    elseif key == Enum.KeyCode.Space then
        self.HandbrakeHeld = false
    end

    self:Refresh()
end

function InputController:Enable()
    if self.Enabled then
        return
    end
    self.Enabled = true

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        self:HandleBegan(input, processed)
    end))

    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        self:HandleEnded(input)
    end))
end

function InputController:Disable()
    self.Enabled = false
    self.ThrottleHeld = false
    self.BrakeHeld = false
    self.LeftHeld = false
    self.RightHeld = false
    self.HandbrakeHeld = false
    self.GearUpPressed = false
    self.GearDownPressed = false
    self:Refresh()

    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
end

function InputController:GetValues()
    return {
        Throttle = self.Values.Throttle,
        Brake = self.Values.Brake,
        Steering = self.Values.Steering,
        Handbrake = self.Values.Handbrake,
        GearUp = self.GearUpPressed,
        GearDown = self.GearDownPressed,
    }
end

function InputController:ConsumeGearEdges()
    local up = self.GearUpPressed
    local down = self.GearDownPressed
    self.GearUpPressed = false
    self.GearDownPressed = false
    return up, down
end

return InputController
