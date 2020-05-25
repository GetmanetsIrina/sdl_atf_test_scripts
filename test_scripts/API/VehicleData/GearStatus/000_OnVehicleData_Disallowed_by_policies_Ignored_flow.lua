---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL does not forward the OnVehicleData notification with 'gearStatus' parameter to App in case
-- `gearStatus` parameter does not exist in apps assigned policies.
--
-- Preconditions:
-- 1) `gearStatus` param does not exist in app's assigned policies for OnVehicleData RPC.
-- 2) App is subscribed to `gearStatus` data.
-- In case:
-- 1) HMI sends valid OnVehicleData notification with all parameters of `gearStatus` structure.
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local notExpected = 0

--[[ Local Function ]]
local function pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gearStatus" }
      },
      OnVehicleData = {
        hmi_levels = { "BACKGROUND", "LIMITED", "FULL" },
        parameters = { "gps" }
      }
    }
  }
  tbl.policy_table.functional_groupings.NewVehicleDataGroup = VDgroup
  tbl.policy_table.app_policies[common.getAppParams().fullAppID].groups = { "Base-4", "NewVehicleDataGroup" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions, { false })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData, { common.getGearStatusParams(), notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
