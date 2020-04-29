---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL rejects the request with resultCode DISALLOWED if app tries to get vehicle data in case
-- `windowStatus` parameter is not present in apps assigned policies after PTU.
-- Preconditions:
-- 1) RPCs(Get/SubscribeVehicleData) with the `windowStatus` param exists in app's assigned policies.
-- 2) App sends valid RPCs(Get/SubscribeVehicleData) requests with windowStatus=true to the SDL
-- 3) and SDL processes this requests successfully.
-- In case:
-- 1) Policy Table Update is performed and "WindowStatus" functional group is unassigned for the app.
-- 2) App re-sends RPCs(Get/SubscribeVehicleData) request with windowStatus=true to the SDL.
-- SDL does:
-- 1) send response RPCs(Get/SubscribeVehicleData) with (success:false, "DISALLOWED") to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update local PT", common.updatePreloadedPT)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App sends GetVehicleData for windowStatus", common.getVehicleData, { common.windowStatusData })
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("PTU with allowed Base-4 group for application", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("GetVehicleData for windowStatus DISALLOWED", common.processRPCFailure, { "GetVehicleData" })
common.Step("SubscribeVehicleData for windowStatus DISALLOWED", common.processRPCFailure, { "SubscribeVehicleData" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Restore PreloadedPT", common.restorePreloadedPT)
