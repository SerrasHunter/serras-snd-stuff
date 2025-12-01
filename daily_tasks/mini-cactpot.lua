--[=====[
[[SND Metadata]]
author: SerrasVictoria
version: 1.0.1
description: Teleports to Gold Saucer, walks to Mini Cactpot Trader, and interacts. YesAlready handles ticket purchase.
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

function Main()
    WaitForPlayer()
    Interact(Npc.Name)
    Wait(1)
    return false
end

GoToSeller()
Main()

yield("/echo Mini Cactpot: Completed.")
