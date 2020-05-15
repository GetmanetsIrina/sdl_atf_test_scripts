---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects GetVehicleData request with resultCode: "DISALLOWED" if 'handsOffSteering'
-- parameter is not allowed by policy after PTU
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC GetVehicleData and handsOffSteering is allowed by policies
-- 3) App is registered
-- 4) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 5) HMI sends VehicleInfo.GetVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = SUCCESS", handsOffSteering = <data received from
-- HMI>) to App
-- 6) PTU is performed with disabling permissions for handsOffSteering parameter
-- 7) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local value = true
local rpc = "GetVehicleData"
local resultCode = "DISALLOWED"

-- [[ Local Function ]]
local function ptUpdate(pt)
  local pGroups = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = common.EMPTY_ARRAY
      }
    }
  }
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.app_policies[common.getParams(1).fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("RPC GetVehicleData", common.getVehicleData, { value })

common.Title("Test")
common.Step("Policy Table Update with disabling permissions for handsOffSteering",
  common.policyTableUpdate, { ptUpdate })
common.Step("RPC GetVehicleData, DISALLOWED after PTU", common.processRPCUnsuccessRequest, { rpc, true, resultCode })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
