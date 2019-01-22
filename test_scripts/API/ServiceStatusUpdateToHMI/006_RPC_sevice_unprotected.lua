---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-- Description:
-- Precondition:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Function]]
local function startRPCServiceUnprotected()

  common.getMobileSession():StartService(7)

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = "RPC" },
    { serviceEvent = "REQUEST_ACCEPTED", serviceType = "RPC" })
  :Times(2)
  :ValidIf(function(_, data)
    if data.payload.appID then
      return false, "SDL sends OnServiceUpdate notification with appID during the first RPC StartService request"
    end
    return true
  end)

  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)

  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)

end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Start Audio Service unprotected", startRPCServiceUnprotected )

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
