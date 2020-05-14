---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL receive DATA_ALREADY_SUBSCRIBED to SubscribeVehicleData request if App already subscribed
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData and handsOffSteering is allowed by policies
-- 3) App is registered and subscribed on handsOffSteering VD
-- 4) App sends valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = DATA_ALREADY_SUBSCRIBED") to App
-- - b) not send OnHashChange notification to App
-- - c) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local resultCode = "DATA_ALREADY_SUBSCRIBED"
local onVDValue = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc })

common.Title("Test")
common.Step("App sends RPC " .. rpc .. " on already subscribed parameter",
  common.appAlreadySubUnsubscribed, { rpc, resultCode })
common.Step("Check that App is subscribed", common.onVehicleData, { onVDValue })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
