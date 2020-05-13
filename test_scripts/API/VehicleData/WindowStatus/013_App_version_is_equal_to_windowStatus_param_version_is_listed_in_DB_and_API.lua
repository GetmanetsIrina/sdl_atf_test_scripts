---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL successfully processes VD RPC with new `windowStatus` param in case app version is equal to 6.2
-- Preconditions:
-- 1) App is registered with syncMsgVersion=6.2
-- 2) New param `windowStatus` has since=6.2 in DB and API
-- In case:
-- 1) App requests Get/Sub/UnsubVehicleData with windowStatus=true.
-- 2) HMI sends valid OnVehicleData notification with all parameters of `windowStatus` structure.
-- SDL does:
--  a) process the requests successful.
--  b) process the OnVehicleData notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

-- [[ Test Configuration ]]
common.getParams(1).syncMsgVersion.majorVersion = 6
common.getParams(1).syncMsgVersion.minorVersion = 2

--[[ Local Variables ]]
local windowStatusData = {
  {
    location = { col = 49, row = 49, level = 49, colspan = 49, rowspan = 49, levelspan = 49 },
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
common.Step("App unsubscribes to windowStatus data", common.subUnScribeVD, { "UnsubscribeVehicleData" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
