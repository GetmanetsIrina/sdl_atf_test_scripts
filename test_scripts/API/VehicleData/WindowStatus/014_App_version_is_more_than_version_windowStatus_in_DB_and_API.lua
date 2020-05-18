---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL successfully processes VD RPC with new `windowStatus` param in case app version is greater than 6.2
--
-- Preconditions:
-- 1) App is registered with syncMsgVersion=7.0
-- 2) New param in `windowStatus` has since=6.2 in DB and API
-- In case:
-- 1) App requests Get/Sub/UnsubVehicleData with windowStatus=true.
-- 2) HMI sends valid OnVehicleData notification with all parameters of `windowStatus` structure.
-- SDL does:
-- 1) process the requests successful.
-- 2) process the OnVehicleData notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

-- [[ Test Configuration ]]
common.getParams().syncMsgVersion.majorVersion = 7
common.getParams().syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local windowStatusData = {
  {
    location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
    state = {
      approximatePosition = 50,
      deviation = 50
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for windowStatus", common.getVehicleData, { windowStatusData })
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })
common.Step("OnVehicleData with windowStatus data", common.sendOnVehicleData, { windowStatusData })
common.Step("App unsubscribes from windowStatus data", common.subUnScribeVD, { "UnsubscribeVehicleData" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
