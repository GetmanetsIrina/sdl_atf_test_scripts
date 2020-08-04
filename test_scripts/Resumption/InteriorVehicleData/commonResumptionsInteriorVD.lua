---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local json = require("modules/json")
local runner = require('user_modules/script_runner')
local rc = require('user_modules/sequences/remote_control')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.isMediaApplication = false

--[[ Variables ]]
local m = {}
m.modules = { "RADIO", "CLIMATE", "SEAT", "AUDIO", "LIGHT", "HMI_SETTINGS" }
m.hashId = {}

-- [[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.postconditions = actions.postconditions
m.preconditions = rc.preconditions
m.start = rc.rc.start
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.cloneTable = utils.cloneTable
m.wait = utils.wait
m.tableToString = utils.tableToString
m.postconditions = actions.postconditions
m.getHMIConnection = actions.hmi.getConnection
m.getMobileSession = actions.mobile.getSession
m.getHMIAppId = actions.app.getHMIId

-- [[ Common Functions ]]
local function boolToTimes(isTrue)
  if isTrue then
    return 1
  end
  return 0
end

function  m.GetInteriorVehicleData(pModuleType, pModuleIdNumber, isSubscribe, pIsIVDataCached, hashChangeExpectTimes, pAppId)
  local rpc = "GetInteriorVehicleData"

  local moduleId = m.getModuleId(pModuleType, pModuleIdNumber or 1)
  local mobileRequestParams = m.cloneTable(rc.rpc.getAppRequestParams(rpc, pModuleType, moduleId, isSubscribe))
  if pModuleIdNumber == nil then
    mobileRequestParams.moduleId = nil
  end
  local hmiRequestParams = rc.rpc.getHMIRequestParams(rpc, pModuleType, moduleId, pAppId, isSubscribe)
  if hashChangeExpectTimes == 0 then hmiRequestParams.subscribe = nil end

  local cid = m.getMobileSession(pAppId):SendRPC(rc.rpc.getAppEventName(rpc), mobileRequestParams)
  m.getHMIConnection():ExpectRequest(rc.rpc.getHMIEventName(rpc), hmiRequestParams)
  :Times(boolToTimes(not pIsIVDataCached))
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        rc.rpc.getHMIResponseParams(rpc, pModuleType, moduleId, isSubscribe))
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid,
    rc.rpc.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, moduleId, isSubscribe))

  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_,data)
      m.hashId[pAppId] = data.payload.hashID
    end)
  :Times(hashChangeExpectTimes)
end

function m.getModuleId(pModuleType, pModuleIdNumber)
  local out = m.cloneTable(rc.predefined.getModuleControlData(pModuleType, pModuleIdNumber))
  return out.moduleId
end

function m.onInteriorVD(pModuleType, pModuleId, pHasSubscription, pAppId)
  rc.isSubscribed(pModuleType, pModuleId or m.getModuleId(pModuleType, 1), pAppId, true or pHasSubscription)
end

local function getRCAppConfig(pPt)
  if pPt then
    local out = utils.cloneTable(pPt.policy_table.app_policies.default)
    out.moduleType = rc.data.getRcModuleTypes()
    out.groups = { "Base-4", "RemoteControl" }
    out.AppHMIType = { "REMOTE_CONTROL" }
    return out
  else
    return {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = rc.data.getRcModuleTypes(),
      groups = { "Base-4", "RemoteControl" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
  end
end

local function updatePreloadedPT(pCountOfRCApps)
  if not pCountOfRCApps then pCountOfRCApps = 2 end
  local preloadedTable = actions.sdl.getPreloadedPT()
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  preloadedTable.policy_table.functional_groupings["RemoteControl"].rpcs.OnRCStatus = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  for i = 1, pCountOfRCApps do
    local appId = config["application" .. i].registerAppInterfaceParams.fullAppID
    preloadedTable.policy_table.app_policies[appId] = getRCAppConfig(preloadedTable)
    preloadedTable.policy_table.app_policies[appId].AppHMIType = nil
  end
  actions.sdl.setPreloadedPT(preloadedTable)
end

function m.preconditions(isPreloadedUpdate, pCountOfRCApps)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  actions.preconditions()
  if isPreloadedUpdate == true then
    updatePreloadedPT(pCountOfRCApps)
  end
end

return m
