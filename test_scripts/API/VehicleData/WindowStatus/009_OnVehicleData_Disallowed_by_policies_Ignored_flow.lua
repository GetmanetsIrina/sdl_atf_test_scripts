---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL does not forward the OnVehicleData notification with 'windowStatus' parameter to App in
-- case `windowStatus` parameter does not exist in apps assigned policies.
--
-- In case:
-- 1) `windowStatus` param does not exist in app's assigned policies for OnVehicleData RPC.
-- 2) App is subscribed to `windowStatus` data.
-- 3) HMI sends valid OnVehicleData notification with all parameters of `windowStatus` structure.
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

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

local notExpected = 0

--[[ Local Function ]]
local function pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "windowStatus"}
      },
      OnVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "prndl" }
      }
    }
  }
  tbl.policy_table.functional_groupings.NewVehicleDataGroup = VDgroup
  tbl.policy_table.app_policies[common.getParams().fullAppID].groups = { "Base-4", "NewVehicleDataGroup" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("OnVehicleData with windowStatus data", common.sendOnVehicleData, { windowStatusData, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
