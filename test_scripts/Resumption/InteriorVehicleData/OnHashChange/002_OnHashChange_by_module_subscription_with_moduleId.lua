---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL sends the notification after successful subscription to interior vehicle data with custom moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is not subscribed to modules
--
-- Sequence:
-- 1. GetInteriorVD(subscribe=true, module_1, moduleId) is requested
-- SDL does:
-- - a. process successful responses from HMI
-- - b. send OnHashChange notification to mobile app by receiving GetInteriorVD(subscribe=true, module_1, moduleId)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local moduleIdNumber = 2
local expectNotif = 1
local isSubscribed = true
local isNotCached = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for _, moduleName in pairs(common.modules)do
  common.Step("OnHashChange after adding subscription to " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, moduleIdNumber, isSubscribed, isNotCached, expectNotif })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
