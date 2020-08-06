---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data for two apps after transport disconnect
--  in case apps are subscribed to several moduleTypes
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app1 and app2 with REMOTE_CONTROL hmi type are registered and activated
-- 3. App1 is subscribed to module_1, module_2
-- 4. App2 is subscribed to module_2. module_3

-- Sequence:
-- 1. Transport disconnect and reconnect are performed
-- 2. Apps start registration with actual hashIds after unexpected disconnect
-- SDL does:
-- - a. send RC.GetInteriorVD(module_1), RC.GetInteriorVD(module_2), RC.GetInteriorVD(module_3)
--    to HMI during resumption data
-- - b. respond RAI(SUCCESS) to both mobile apps
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribe = true
local default = nil
local appIdFirstApp = 1
local appIdsecondApp = 2
local expected = 1
local notExpected = 0
local isNotCashed = false
local isCashed = true

--[[ Local Functions ]]
local function checkResumptionData()
  local defaultModuleId = 1
  local modulesNumber = 3
  local actualModules = { }
  local expectedModules = { }

  for i = 1, modulesNumber do
    expectedModules[i] = {
      moduleType = common.modules[i],
      moduleId = common.getModuleId(common.modules[i], defaultModuleId)
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
    if exp.occurences == modulesNumber then
      if common.isTableEqual(actualModules, expectedModules) == false then
        local errorMessage = "Not all modules are resumed.\n" ..
          "Actual result:" .. common.tableToString(actualModules) .. "\n" ..
          "Expected result:" .. common.tableToString(expectedModules) .."\n"
        return false, errorMessage
      end
    end
    return true
  end)
  :Times(modulesNumber)
  common.wait(1000)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App1 registration", common.registerAppWOPTU, { appIdFirstApp })
common.Step("App2 registration", common.registerAppWOPTU, { appIdsecondApp })
common.Step("App1 activation", common.activateApp, { appIdFirstApp })
common.Step("App2 activation", common.activateApp, { appIdsecondApp })
common.Step("App1 interiorVD subscription for " .. common.modules[1],
  common.GetInteriorVehicleData, { common.modules[1], default, isSubscribe, isNotCashed, default, appIdFirstApp })
common.Step("App1 interiorVD subscription for " .. common.modules[2],
  common.GetInteriorVehicleData, { common.modules[2], default, isSubscribe, isNotCashed, default, appIdFirstApp })
common.Step("App2 interiorVD subscription for " .. common.modules[2],
  common.GetInteriorVehicleData, { common.modules[2], default, isSubscribe, isCashed, default, appIdsecondApp  })
common.Step("App2 interiorVD subscription for " .. common.modules[3],
  common.GetInteriorVehicleData, { common.modules[3], default, isSubscribe, isNotCashed, default, appIdsecondApp  })

common.Title("Test")
common.Step("Unexpected disconnect", common.mobileDisconnect)
common.Step("Connect mobile", common.mobileConnect)
common.Step("Open service for app1", common.sessionCreationOpenRPCservice, { appIdFirstApp })
common.Step("Open service for app2", common.sessionCreationOpenRPCservice, { appIdsecondApp })
common.Step("Reregister Apps resumption data", common.reRegisterApps,
  { checkResumptionData })
common.Step("Check subscription with OnInteriorVD " .. common.modules[1], common.onInteriorVD2Apps,
  { common.modules[1], expected, notExpected })
common.Step("Check subscription with OnInteriorVD " .. common.modules[2], common.onInteriorVD2Apps,
  { common.modules[2], expected, expected })
common.Step("Check subscription with OnInteriorVD " .. common.modules[3], common.onInteriorVD2Apps,
  { common.modules[3], notExpected, expected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
