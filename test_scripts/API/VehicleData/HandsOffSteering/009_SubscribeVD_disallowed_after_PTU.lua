---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects SubscribeVehicleData request with resultCode: "DISALLOWED" if 'handsOffSteering'
-- parameter is not allowed by policy after PTU
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData and handsOffSteering is allowed by policies
-- 3) App is registered
-- 4) App sends valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 5) HMI sends VehicleInfo.SubscribeVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = SUCCESS",
-- handsOffSteering = <data received from HMI>) to App
-- - b) send OnHashChange notification to App
-- 6) App is unsubscribed on handsOffSteering parameter
-- 7) PTU is performed with disabling permissions for handsOffSteering parameter
-- 8) App sends valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
-- - c) not send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local onVDValue = true
local resultCode = { success = false, resultCode = "DISALLOWED" }
local pExpTimes = 0

--[[ Local Function ]]
local function ptUpdate(pt)
  local pGroups = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = common.EMPTY_ARRAY
      },
      OnVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = { "handsOffSteering" }
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
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter App",
  common.processSubscriptionRPCsSuccess, { rpc_sub })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter",
  common.processSubscriptionRPCsSuccess, { rpc_unsub })

common.Title("Test")
common.Step("Policy Table Update with disabling permissions for handsOffSteering",
  common.policyTableUpdate, { ptUpdate })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter DISALLOWED after PTU",
  common.processRPCUnsuccessRequest, { rpc_sub, true, resultCode })
common.Step("Check that App is not subscribed", common.onVehicleData, { onVDValue, pExpTimes })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
