---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local json = require("modules/json")
local runner = require('user_modules/script_runner')
local rc = require('user_modules/sequences/remote_control')
local SDL = require('SDL')
local color = require("user_modules/consts").color

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
m.mobileDisconnect = actions.mobile.disconnect
m.mobileConnect = actions.mobile.connect
m.getConfigAppParams =  actions.getConfigAppParams
m.setHMIAppId = actions.app.setHMIId
m.isTableEqual = utils.isTableEqual
m.fail = actions.run.fail

--[[ General configuration ]]
local state = rc.state.buildDefaultActualModuleState(rc.predefined.getRcCapabilities())
rc.state.initActualModuleStateOnHMI(state)

-- [[ Common Functions ]]
local function boolToTimes(isTrue)
  if isTrue then
    return 1
  end
  return 0
end

function  m.GetInteriorVehicleData(pModuleType, pModuleId, isSubscribe, pIsIVDataCached, hashChangeExpectTimes, pAppId)
  local rpc = "GetInteriorVehicleData"
  if pIsIVDataCached == nil then pIsIVDataCached = false end

  local moduleId = pModuleId or m.getModuleId(pModuleType,  1)
  local mobileRequestParams = m.cloneTable(rc.rpc.getAppRequestParams(rpc, pModuleType, moduleId, isSubscribe))

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
  :Times(hashChangeExpectTimes or 1)
end

function m.getModuleId(pModuleType, pModuleIdNumber)
  local out = m.cloneTable(m.getModuleControlData(pModuleType, pModuleIdNumber))
  return out.moduleId
end

function m.onInteriorVD(pModuleType, pModuleId, pHasSubscription, pAppId)
  if pHasSubscription == nil then pHasSubscription = true end
  rc.rc.isSubscribed(pModuleType, pModuleId or m.getModuleId(pModuleType, 1), pAppId, pHasSubscription)
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

function m.reRegisterApp(pAppId, pCheckResumptionData, pCheckResumptionHMILevel, pResultCode)
  if not pAppId then pAppId = 1 end
  if not pResultCode then pResultCode = "SUCCESS" end
  local mobSession = actions.mobile.createSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = m.getConfigAppParams(pAppId).appName }
        })
      :Do(function(_, data)
          m.setHMIAppId(data.params.application.appID, pAppId)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = pResultCode })
    end)
  pCheckResumptionData()
  pCheckResumptionHMILevel(pAppId)
end

function m.resumptionFullHMILevel(pAppId)
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
  :Times(2)
end

function m.checkModuleResumptionData(pModuleType, pModuleId)
  local requestParams = {
    moduleType = pModuleType,
    subscribe = true,
    moduleId = pModuleId
  }
  EXPECT_HMICALL("RC.GetInteriorVehicleData", requestParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { moduleData = m.state.getActualModuleIVData(pModuleType, pModuleId)})
    end)
end

function m.getModuleIdNumber(pModuleType, pModuleId)
  local moduleNumbers = 2
  for i = 1, moduleNumbers do
    local out = m.getModuleControlData(pModuleType, i)
    if out.moduleId == pModuleId then
      return i
    end
  end
  m.fail(pModuleId .. " is not found for " .. pModuleType .. " in predefinedInteriorVehicleData")
end

function m.getModuleControlData(pModuleType, pModuleId)
  local out = rc.predefined.getModuleControlData(pModuleType, 1)
  if pModuleId == 1 or nil then
    return out
  else
    local actualData = rc.state.getActualModuleStateOnHMI()
    for key, value in pairs(actualData[pModuleType]) do
      if key ~= out.moduleId then
        return value.data
      end
    end
  end
    utils.cprint(color.magenta, "There is only one moduleId for module " .. pModuleType ..
      ".\nChecked default moduleId." )
  return out
end

function m.ignitionOff()
  local isOnSDLCloseSent = false
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then m.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

return m
