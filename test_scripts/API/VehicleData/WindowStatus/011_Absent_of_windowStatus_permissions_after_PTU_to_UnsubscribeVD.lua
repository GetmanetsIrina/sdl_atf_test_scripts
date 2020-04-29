---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL rejects the request with resultCode `DISALLOWED` if app tries to unsubscribe from
-- 'windowStatus' and parameter is not present in apps assigned policies after PTU.
-- Preconditions:
-- 1) RPCs(Subscribe/UnsubscribeVehicleData) with the `windowStatus` param exists in app's assigned policies.
-- 2) App sends valid RPCs(Subscribe/UnsubscribeVehicleData) requests with windowStatus=true to the SDL
-- 3) and SDL processes this requests successfully.
-- In case:
-- 1) PTU is performed and UnsubscribeVehicleData RPC with `windowStatus` param is unassigned for the app.
-- 2) App is subscribed to `windowStatus` data.
-- 3) App re-sends UnsubscribeVehicleData request with windowStatus=true to the SDL.
-- SDL does:
-- 1) send UnsubscribeVehicleData response with (success:false, "DISALLOWED") to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Function ]]
local function pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"windowStatus"}
      }
    }
  }
  tbl.policy_table.functional_groupings.NewVehicleDataGroup = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
  {"Base-4", "NewVehicleDataGroup"}
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update local PT", common.updatePreloadedPT)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })
common.Step("App unsubscribes to windowStatus data", common.subUnScribeVD, { "UnsubscribeVehicleData" })

common.Title("Test")
common.Step("PTU with allowed Base-4 group for application", common.policyTableUpdate, { pTUpdateFunc })
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })
common.Step("App unsubscribes to windowStatus data DISALLOWED", common.processRPCFailure, { "UnsubscribeVehicleData" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Restore PreloadedPT", common.restorePreloadedPT)
