-- Lists:
DPS = {22, 25, 30, 34, 35, 39, 41} -- these are not all the values, need to fill with the remaining jobs, only covering
-- vpr, nin, sam, rpr, drg, blm and rdm at the moment.
-- Change this list with all the jobs you possess at level 91+
RemainingClasses = {"Dark Knight", "Viper", "Ninja", "Samurai", "Reaper", "Dragoon", "Black Mage", "Red Mage", "Sage"}

-- Functions:
function PlayerTest()
    repeat
        yield("/wait 0.5")
    until IsPlayerAvailable()
end

-- Requires Pandora's Box:
function SquaredDistance(x1, y1, z1, x2, y2, z2)
    if type(x1) ~= "number" or type(y1) ~= "number" or type(z1) ~= "number" or
        type(x2) ~= "number" or type(y2) ~= "number" or type(z2) ~= "number" then
        return nil
    end

    if GetCharacterCondition(45) then
        return nil
    end

    local success, result = pcall(function()
        local dx = x2 - x1
        local dy = y2 - y1
        local dz = z2 - z1
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        return math.floor(dist + 0.5)
    end)

    if success then
        return result
    else
        return nil
    end
end

function WithinThreeUnits(x1, y1, z1, x2, y2, z2)
    local dist = SquaredDistance(x1, y1, z1, x2, y2, z2)
    if dist then
        return dist <= 3
    else
        return false
    end
end

function RunDuty(dutyId, loops, dutyMode, stoppingLevel)
    ADSetConfig("StopLevelInt", stoppingLevel)
    ADSetConfig("StopLevel", "True")
    ADSetConfig("dutyModeEnum", dutyMode)
    if not ADIsNavigating() then
        ADRun(dutyId, loops)
        yield('/wait 10')
        PlayerTest()
        -- Stuck checker:
        if PathIsRunning() then           
            local retry_timer = 0
            while PathIsRunning() do
                local success1, x1 = pcall(GetPlayerRawXPos)
                local success2, y1 = pcall(GetPlayerRawYPos)
                local success3, z1 = pcall(GetPlayerRawZPos)
                if not (success1 and success2 and success3) then
                    goto continue
                end
                yield('/wait 2')
                local success4, x2 = pcall(GetPlayerRawXPos)
                local success5, y2 = pcall(GetPlayerRawYPos)
                local success6, z2 = pcall(GetPlayerRawZPos)
                if not (success4 and success5 and success6) then
                    goto continue
                end
                if WithinThreeUnits(x1, y1, z1, x2, y2, z2) and PathIsRunning() then
                    yield("/e Stuck checker active, stopping AD and attempting reload unstuck")
                    yield("/ad stop")
                    retry_timer = retry_timer + 1
                    if retry_timer > 4 then -- 4 would be about 8 seconds, with some extra time since it waits a second after reloading
                        yield("/e Stuck checker: Stuck for too long, attempting rebuild")
                        yield("/vnav rebuild")
                    else
                        yield("/e Stuck checker: Reloading vnav")
                        yield("/vnav reload")
                    end
                    yield('/wait 1')
                    yield("/e Stuck checker: Starting AD again")
                    yield("/ad start")
                else
                    retry_timer = 0
                end
                ::continue::
            end
        end
    else
        repeat
            yield('/wait 5')
        until not ADIsNavigating()
    end
    yield('/wait 5')
    PlayerTest()
end

-- At the moment, this only covers levels 91 through 100, will update for the rest of the leveling process and integrate
-- with the Questionable Companion to make it unlock the jobs and automatically do your job quests for low level jobs
-- or jobs that have skills unlocked through the job quest.
function CheckLevelAndRun()
    local function hasValue(tab, val)
        for index, value in ipairs(tab) do
            if value == val then
                return true
            end
        end
        return false
    end
    local level = GetLevel()
    local jobId = GetClassJobId()
    if hasValue(DPS, jobId) then
        yield('/wait 2')
        ADSetConfig("SelectedTrustMembers", "Alphinaud,Krile,Thancred")
    elseif jobId == 32 then
        yield('/wait 2')
        ADSetConfig("SelectedTrustMembers", "Alphinaud,Krile,Estinien")
    else
        yield('/wait 2')
        ADSetConfig("SelectedTrustMembers", "Thancred,Krile,Estinien")
    end
    if level >= 91 and level < 93 then
        RunDuty(1167, 15, "Trust", "93")
        yield('/wait 2')
    elseif level < 95 then
        RunDuty(1193, 15, "Trust", "95")
        yield('/wait 2')
    elseif level < 97 then
        RunDuty(1194, 15, "Trust", "97")
        yield('/wait 2')
    elseif level < 100 then
        RunDuty(1198, 20, "Trust", "100")
        yield('/wait 2')
    end
    if level == 100 then
        for classNum = 1, #RemainingClasses do
            yield('/gearset change "'..RemainingClasses[classNum]..'"')
            yield('/wait 2')
            PlayerTest()
            local newLevel = GetLevel()
            if newLevel < 100 then
                yield('/wait 2')
                break
            end
        end
        CheckLevelAndRun()
    end
end

-- Main:
CheckLevelAndRun()
