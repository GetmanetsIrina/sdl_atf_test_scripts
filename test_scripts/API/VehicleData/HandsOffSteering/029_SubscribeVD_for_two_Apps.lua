---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes SubscribeVehicleData RPC for two Apps with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData and handsOffSteering is allowed by policies
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
-- - a) send SubscribeVehicleData response with (success = true, resultCode = SUCCESS",
-- handsOffSteering = <data received from HMI>) to App_2
-- - b) send OnHashChange notification to App_2
-- - c) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local rpc_sub = "SubscribeVehicleData"
local appId_1 = 1
local appId_2 = 2
local isExpectedSubscribeVDonHMI = true
local notExpectedSubscribeVDonHMI = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { appId_1 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_1",
  common.processSubscriptionRPCsSuccess, { rpc_sub, appId_1, isExpectedSubscribeVDonHMI })

common.Title("Test")
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_2",
  common.processSubscriptionRPCsSuccess, { rpc_sub, appId_2, notExpectedSubscribeVDonHMI })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
