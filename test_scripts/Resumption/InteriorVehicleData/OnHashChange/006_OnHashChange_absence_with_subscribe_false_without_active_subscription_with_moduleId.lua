---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL does not send the notification to mobile app in case processing
--  of GetInteriorVehicleData(subscribe=false) without active subscription with custom moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is not subscribed to modules
--
-- Sequence:
-- 1. GetInteriorVD(subscribe=false, module_1, moduleId) is requested
-- SDL does:
-- - a. process successful responses from HMI
-- - b. not send OnHashChange notification to mobile app by receiving GetInteriorVD(subscribe=false, module_1, moduleId)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local moduleIdNumber = 2
local notExpectNotif = 0
local isNotSubscribed = false
local isNotCached = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for _, moduleName in pairs(common.modules)do
  common.Step("Absence OnHashChange after GetInteriorVD(subscribe=false) to " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, common.getModuleId(moduleName, moduleIdNumber), isNotSubscribed, isNotCached, notExpectNotif })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
