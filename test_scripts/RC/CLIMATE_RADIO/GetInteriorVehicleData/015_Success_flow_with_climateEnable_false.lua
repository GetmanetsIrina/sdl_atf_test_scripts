---------------------------------------------------------------------------------------------------
-- User story:
-- Use case:
-- Item: Use Case 1: Main Flow -- не актуально для текущего скрипта
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData with "climateEnable" = false  -- нужно расширить описание
--
-- Description:
-- Preconditions:
-- Mobile app is registered with SyncMsgVersion = 5.1 -- для айтемов прекондишена нужно добавить нумерацию, и так как пока еще выясняется ситуация с версионингом,
-- то "with SyncMsgVersion = 5.1" лучше удалить
-- SDL got RC.GetCapabilities for CLIMATE module  with new ("climateEnableAvailable" = true) parameter from HMI -  не нужно акцентировать внимание на new, это сейчас он нью,
-- а потом будет не нью, поэтому лучше ЭSDL got RC.GetCapabilities("climateEnableAvailable" = true) for CLIMATE module parameter from HMI
-- In case:
-- 1) Mobile app sends GetInteriorVehicleData (CLIMATE) to SDL.
-- 2) HMI sends response RC.GetInteriorVehicleData ("climateEnable" = false) to SDL
-- SDL must:
-- 1) send RC.GetInteriorVehicleData (CLIMATE) to HMI
-- 2) send GetInteriorVehicleData  with ("climateEnable" = false) parameter to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

function commonRC.getModuleControlData(module_type)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.climateControlData = {
      climateEnable = false
    }
  end
  return out
end
-- можно сразу обновить commonRC.actualInteriorDataStateOnHMI
commonRC.actualInteriorDataStateOnHMI = {CLIMATE = commonRC.cloneTable(commonRC.getModuleControlData("CLIMATE"))} --добавь пробелы после { и перед } , такой синтаксис используется во всех скритах

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("GetInteriorVehicleData CLIMATE with climateEnable:false",
  commonRC.rpcAllowed, {"CLIMATE", 1, "GetInteriorVehicleData" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
