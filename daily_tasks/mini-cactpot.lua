--[=====[
[[SND Metadata]]
author: Serras
version: 1.3.0
description: Goes to the Mini Cactpot Broker, interacts, lets YesAlready handle tickets, and ends when final dialog appears.
plugin_dependencies:
- Lifestream
- vnavmesh
- YesAlready
[[End Metadata]]
--]=====]

import("System.Numerics")

Npc = {
    Name = "Mini Cactpot Broker",
    Position = { X = -46.52, Y = 1.60, Z = 20.76 }
}

LogPrefix = "[MiniCactpot]"

Dialog1Part1 = "Your patronage is most appreciated"
Dialog1Part2 = "I hope to see you again tomorrow"

Dialog2Part1 = "Thank you for your patronage"
Dialog2Part2 = "you can only purchase three Mini Cactpot tickets a day"

function Wait(t)
    yield("/wait " .. t)
end

function WaitForPlayer()
    repeat Wait(0.1) until Player.Available and not Player.IsBusy
    Wait(0.1)
end

function WaitForTeleport()
    repeat Wait(0.1) until not Svc.Condition[27]
    Wait(0.1)
    repeat Wait(0.1) until not Svc.Condition[45] and Player.Available and not Player.IsBusy
    Wait(0.1)
end

function WaitForPathRunning(timeout)
    timeout = timeout or 300
    local start = os.clock()
    while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
        if os.clock() - start >= timeout then return false end
        Wait(0.1)
    end
    return true
end

function Teleport(loc)
    IPC.Lifestream.ExecuteCommand(loc)
    Wait(0.1)
    WaitForTeleport()
end

function Interact(name, retries, sleep)
    retries = retries or 20
    sleep = sleep or 0.1
    yield("/target " .. tostring(name))
    local r = 0
    while (Entity == nil or Entity.Target == nil) and r < retries do
        Wait(sleep)
        r = r + 1
    end
    if Entity and Entity.Target and Entity.Target.Name then
        yield("/interact")
        return true
    end
    return false
end

function GetDistanceToPoint(x, y, z)
    local p = Svc.ClientState.LocalPlayer
    if not p or not p.Position then return math.huge end
    local dx = x - p.Position.X
    local dy = y - p.Position.Y
    local dz = z - p.Position.Z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function GoToSeller()
    local dest = Vector3(Npc.Position.X, Npc.Position.Y, Npc.Position.Z)
    if Svc.ClientState.TerritoryType == 144 then
        local dist = GetDistanceToPoint(Npc.Position.X, Npc.Position.Y, Npc.Position.Z)
        if dist > 0 and dist < 100 then
            IPC.vnavmesh.PathfindAndMoveTo(dest, false)
            WaitForPathRunning()
            return
        end
    end
    Teleport("The Gold Saucer")
    IPC.vnavmesh.PathfindAndMoveTo(dest, false)
    WaitForPathRunning()
end

function WaitForFinalDialog(timeout)
    timeout = timeout or 30
    local start = os.clock()
    while os.clock() - start < timeout do
        local talk = Addons.GetAddon("Talk")
        if talk and talk.Ready then
            local node = talk:GetNode(0, 4)
            if node and node.Text then
                local text = node.Text
                if text:find(Dialog1Part1, 1, true) and text:find(Dialog1Part2, 1, true) then
                    return true
                end
                if text:find(Dialog2Part1, 1, true) and text:find(Dialog2Part2, 1, true) then
                    return true
                end
            end
        end
        Wait(0.1)
    end
    return false
end

function Main()
    WaitForPlayer()
    Interact(Npc.Name)
    WaitForFinalDialog(30)
    return false
end

GoToSeller()
Main()

yield("/echo Mini Cactpot: Completed.")
