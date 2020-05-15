---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App if 'handsOffSteering' parameter is not
-- allowed by policy
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) 'handsOffSteering' is Not allowed by policies
-- 3) App is registered
-- 4) App is subscribed on handsOffSteering parameter
-- 5) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) ignored this notification and not transfer to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local value = { true, false }
local rpc_sub = "SubscribeVehicleData"
local pExpTimes = 0
local VDGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = {"handsOffSteering"}
    },
    OnVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = common.EMPTY_ARRAY
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc_sub })

common.Title("Test")
for _, v in pairs(value) do
  common.Step("HMI sends OnVD notification not allowed by policy, parameter-" .. tostring(v),
  common.onVehicleData, { v, pExpTimes })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
