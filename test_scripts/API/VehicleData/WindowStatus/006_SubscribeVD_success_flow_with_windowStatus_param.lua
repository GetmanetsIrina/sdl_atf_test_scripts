---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Successful processing of SubscribeVehicleData with `windowStatus` param.
--
-- In case:
-- 1) App sends SubscribeVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI responds with `SUCCESS` result to `windowStatus` vehicle data and SubscribeVehicleData request.
-- SDL does:
--  a) respond `SUCCESS`, success:true and with `windowStatus` data to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
