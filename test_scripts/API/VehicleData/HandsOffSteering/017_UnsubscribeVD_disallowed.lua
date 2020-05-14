---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects UnsubscribeVehicleData request with resultCode: "DISALLOWED" if
-- 'handsOffSteering' parameter is not allowed by policy
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) SubscribeVehicleData and handsOffSteering is allowed by policies
-- 3) UnsubscribeVehicleData and handsOffSteering is Not allowed by policies
-- 4) App is registered and subscribed on handsOffSteering parameter
-- 5) App sends valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
-- - c) not send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local VDGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = {"handsOffSteering"}
    },
    UnsubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = common.EMPTY_ARRAY
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.precondition, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc_sub })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter DISALLOWED",
  common.processRPCDisallowed, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
