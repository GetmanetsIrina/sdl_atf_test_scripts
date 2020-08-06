---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle subscription for same moduleType with different moduleIds data
--  after IGN_OFF
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to module_1 with modueId_1
-- 4. App is subscribed to module_1 with modueId_2

-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. App starts registration with actual hashId after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVD(subscribe=true, module_1, moduleId_1) and
--     RC.GetInteriorVD(subscribe=true, module_1, moduleId_2) to HMI during resumption data
-- - b. respond RAI(SUCCESS) to mobile app
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribed = true
local moduleType = "SEAT"
local moduleId1 = common.getModuleId(moduleType, 1)
local moduleId2 = common.getModuleId(moduleType, 2)
local appId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local subscriptionsNumber  = 2
  local actualModules = { }
  local expectedModules = {
    { moduleType = moduleType, moduleId = moduleId1 }, { moduleType = moduleType, moduleId = moduleId2 } }

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
    if exp.occurences == subscriptionsNumber then
      if common.isTableEqual(actualModules, expectedModules) == false then
        local errorMessage = "Not all modules are resumed.\n" ..
          "Actual result:" .. common.tableToString(actualModules) .. "\n" ..
          "Expected result:" .. common.tableToString(expectedModules) .."\n"
        return false, errorMessage
      end
    end
    return true
  end)
  :Times(subscriptionsNumber)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Add interiorVD subscription", common.GetInteriorVehicleData, { moduleType, moduleId1, isSubscribed })
common.Step("Add interiorVD subscription", common.GetInteriorVehicleData, { moduleType, moduleId2, isSubscribed })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appId, checkResumptionData, common.resumptionFullHMILevel })
common.Step("Check subscription with OnInteriorVD for module " .. moduleId1, common.onInteriorVD,
  { moduleType, moduleId1 })
common.Step("Check subscription with OnInteriorVD for module " .. moduleId2, common.onInteriorVD,
  { moduleType, moduleId2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
