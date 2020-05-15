---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects SubscribeVehicleData request with resultCode: "DISALLOWED" if 'handsOffSteering'
-- parameter is not allowed by policy
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData and handsOffSteering is allowed by policies only for App_1
-- 3) App_1 is registered
-- 4) App_1 sends valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 5) HMI sends VehicleInfo.SubscribeVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = SUCCESS",
-- handsOffSteering = <data received from HMI>) to App_1
-- - b) send OnHashChange notification to App_1
-- 6) App_2 is registered
-- 7) App_2 sends valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = DISALLOWED") to App_2
-- - b) not transfer this request to HMI
-- - c) send not OnHashChange notification to App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')
local utils = require("user_modules/utils")
local json = require("modules/json")

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local appId_1 = 1
local appId_2 = 2
local resultCode = "DISALLOWED"

--[[ Local Function ]]
local function updatedPreloadedPTFile()
  local pt = common.getPreloadedPT()
  local pGroups1 = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = {"handsOffSteering"}
      }
    }
  }
  local pGroups2 = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = common.EMPTY_ARRAY
      }
    }
  }
  pt.policy_table.functional_groupings["NewTestCaseGroup1"] = pGroups1
  pt.policy_table.functional_groupings["NewTestCaseGroup2"] = pGroups2
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.app_policies[common.getParams(1).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.getParams(1).fullAppID].groups = { "Base-4", "NewTestCaseGroup1" }
  pt.policy_table.app_policies[common.getParams(2).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.getParams(2).fullAppID].groups = { "Base-4", "NewTestCaseGroup2" }
  common.setPreloadedPT(pt)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update preloaded file", updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { appId_1 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_1",
  common.processSubscriptionRPCsSuccess, { rpc_sub, appId_1 })

common.Title("Test")
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_2 DISALLOWED",
  common.processRPCUnsuccessRequest, { rpc_sub, true, resultCode, appId_2 })
common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
