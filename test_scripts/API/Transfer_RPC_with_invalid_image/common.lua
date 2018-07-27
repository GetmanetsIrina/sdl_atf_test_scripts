---------------------------------------------------------------------------------------------------
-- common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local json = require("modules/json")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Local Variables ]]
local common = actions
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[Module functions]]
function common.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  commonPreconditions:BackupFile(preloadedPT)
  common.updatePreloadedPT()
end

function common.postconditions()
  StopSDL()
  commonPreconditions:RestoreFile(preloadedPT)
end

function common.updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SendLocation", "SubscribeVehicleData", "UnsubscribeVehicleData", "GetVehicleData", "UpdateTurnList",
    "AlertManeuver", "DialNumber", "ReadDID", "GetDTCs", "ShowConstantTBT", "GetWayPoints", "SubscribeWayPoints",
    "OnWayPointChange"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end
  pt.policy_table.app_policies["0000001"] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["0000001"].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.app_policies["0000001"].keep_context = true
  pt.policy_table.app_policies["0000001"].steal_focus = true
  utils.tableToJsonFile(pt, preloadedFile)
end

return common
