---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL responds with ` INVALID_DATA` resultCode on Get/Sub/Unsub/VehicleData requests with new
-- 'windowStatus' parameter in case App is registered with syncMsgVersion less than 6.2.
-- Preconditions:
-- 1) App is registered with syncMsgVersion=5.0
-- 2) New param `windowStatus` has since=6.2 in DB and API
-- In case:
-- 1) App requests Get/Sub/UnsubVehicleData with windowStatus=true.
-- SDL does:
--  a) reject the request with resultCode INVALID_DATA as empty one
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

-- [[ Test Configuration ]]
common.getParams(1).syncMsgVersion.majorVersion = 5
common.getParams(1).syncMsgVersion.minorVersion = 0

--[[ Local Functions ]]
local function ptuFunc(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"windowStatus"}
      },
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"windowStatus"}
      },
      UnsubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"windowStatus"}
      }
    }
  }
  tbl.policy_table.functional_groupings["WindowStatus"] = VDgroup
  tbl.policy_table.app_policies[common.getParams(1).fullAppID].groups = { "Base-4", "WindowStatus" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions, { false })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptuFunc })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for windowStatus INVALID_DATA",
  common.processRPCFailure, { "GetVehicleData", "INVALID_DATA" })

common.Step("SubscribeVehicleData for windowStatus INVALID_DATA",
  common.processRPCFailure, { "SubscribeVehicleData", "INVALID_DATA" })

common.Step("UnsubscribeVehicleData for windowStatus INVALID_DATA",
  common.processRPCFailure, { "UnsubscribeVehicleData", "INVALID_DATA" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
