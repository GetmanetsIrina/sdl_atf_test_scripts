---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL rejects the RPCs(Get/Subscribe/UnsubscribeVehicleData) requests with resultCode: DISALLOWED
-- if app tries to get `windowStatus` vehicle data in case `windowStatus` param does not exist in assigned policies.
-- In case:
-- 1) RPCs(Get/Subscribe/UnsubscribeVehicleData) with the `windowStatus` and param does not exist in app's assigned policies.
-- 2) App sends valid RPCs(Get/Subscribe/UnsubscribeVehicleData) requests with windowStatus=true to the SDL.
-- SDL does:
--  a) send response RPCs(Get/Subscribe/UnsubscribeVehicleData) with (success:false, "DISALLOWED") to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions, { false })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData with windowStatus DISALLOWED", common.processRPCFailure, { "GetVehicleData", "DISALLOWED" })
common.Step("SubscribeVehicleData with windowStatus DISALLOWED", common.processRPCFailure, { "SubscribeVehicleData", "DISALLOWED" })
common.Step("UnsubscribeVehicleData with windowStatus DISALLOWED", common.processRPCFailure, { "UnsubscribeVehicleData", "DISALLOWED" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
