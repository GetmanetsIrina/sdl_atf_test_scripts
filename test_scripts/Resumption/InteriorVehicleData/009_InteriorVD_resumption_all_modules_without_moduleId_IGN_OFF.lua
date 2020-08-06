---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data after IGN_OFF in case GetInteriorVehicleData was requested
--  for all modules and without moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to all modules via GetInteriorVehicleData(moduleType)
--
-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. App starts registration with actual hashId after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVD(subscribe=true, moduleType, default moduleId) to HMI during resumption data for each module
-- - b. respond RAI(SUCCESS) to mobile app
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribed = true
local withoutModuleId = nil
local appId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local defaultModuleId = 1
  local actualModules = { }
  local expectedModules = { }

  for key, moduleType in pairs(common.modules) do
    expectedModules[key] = {
      moduleType = moduleType,
      moduleId = common.getModuleId(moduleType, defaultModuleId)
    }
  end

  common.getHMIConnection()("RC.GetInteriorVehicleData")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = common.getActualModuleIVData(data.params.moduleType, data.params.moduleId), isSubscribed = true })
    end)
  :ValidIf(function(exp, data)
    actualModules[exp.occurences] = {
      moduleType = data.params.moduleType,
      moduleId = data.params.moduleId
    }
    if exp.occurences == #common.modules then
      if common.isTableEqual(actualModules, expectedModules) == false then
        local errorMessage = "Not all modules are resumed.\n" ..
          "Actual result:" .. common.tableToString(actualModules) .. "\n" ..
          "Expected result:" .. common.tableToString(expectedModules) .."\n"
        return false, errorMessage
      end
    end
    return true
  end)
  :Times(#common.modules)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
for _, moduleType in pairs(common.modules) do
  common.Step("Add interiorVD subscription for " .. moduleType, common.GetInteriorVehicleData,
    { moduleType, withoutModuleId, isSubscribed })
end

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appId, checkResumptionData, common.resumptionFullHMILevel })
for _, moduleType in pairs(common.modules) do
  common.Step("Check subscription with OnInteriorVD " .. moduleType, common.onInteriorVD, { moduleType })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
