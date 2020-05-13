---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local json = require("modules/json")
local events = require('events')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Variables ]]
local m = {}
local hashId = {}

m.Title = runner.Title
m.Step = runner.Step
m.start = actions.start
m.registerApp = actions.registerApp
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.policyTableUpdate = actions.policyTableUpdate
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.cloneTable = utils.cloneTable
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.getParams = actions.app.getParams
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.backupPreloadedPT = actions.sdl.backupPreloadedPT
m.restorePreloadedPT = actions.sdl.restorePreloadedPT
m.deleteSession = actions.mobile.deleteSession
m.connectMobile = actions.mobile.connect
m.getAppsCount = actions.getAppsCount
m.getConfigAppParams = actions.getConfigAppParams
m.EMPTY_ARRAY = json.EMPTY_ARRAY

m.subUnsubParams = {
  dataType = "VEHICLEDATA_WINDOWSTATUS",
  resultCode = "SUCCESS"
}

m.invalidParam = {
  ["empty_location"] = {
    { location = {}, -- empty location parameter
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidType_location"] = {
    { location = "string", -- invalid type for location parameter
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["missing_location"] = { -- without location parameter
    { state = { approximatePosition = 50, deviation = 50 }}
  },
  ["invalidName_location"] ={ -- invalid name for location parameter
    { loCaTion = { col = 49, row = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidName_col"] = { -- invalid name for col parameter from Grid structure
    { location = { CoL = 49, row = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidName_row"] = { -- invalid name for row parameter from Grid structure
    { location = { col = 49, RoW = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["empty_state"] = { -- empty state parameter
    { location = { col = 49, row = 49 },
      state = {}
    }
  },
  ["invalidType_state"] = { -- invalid type for state parameter
    { location = { col = 49, row = 49 },
      state = "string"
    }
  },
  ["missing_state"] = { -- without state parameter
    { location = { col = 49, row = 49 } }
  },
  ["invalidName_state"] = { -- invalid name for state parameter
    { location = { col = 49, row = 49 },
      StaTe = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidName_approximatePosition"] = { -- invalid name for approximatePosition parameter from WindowState structure
    { location = { col = 49, row = 49 },
      state = { ApproximatePositioN = 50, deviation = 50 }
    }
  },
  ["invalidName_deviation"] = { -- invalid name for deviation parameter from WindowState structure
    { location = { col = 49, row = 49 },
      state = { approximatePosition = 50, DeviatioN = 50 }
    }
  }
}

--[[ Functions ]]

--[[ @updatePreloadedPT: Update preloaded file with additional permissions for WindowStatus
--! @parameters: none
--! @return: none
--]]
function m.updatePreloadedPT()
  m.backupPreloadedPT()
  local pt = m.getPreloadedPT()
  local WindowStatusGroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"windowStatus"}
      },
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"windowStatus"}
      },
      OnVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"windowStatus"}
      },
      UnsubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"windowStatus"}
      }
    }
  }
  pt.policy_table.app_policies["default"].groups = { "Base-4", "WindowStatus" }
  pt.policy_table.functional_groupings["WindowStatus"] = WindowStatusGroup
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  m.setPreloadedPT(pt)
end

--[[ @preconditions: Clean environment and backup sdl_preloaded_pt.json file
--! @parameters:
--! isPreloadedUpdate: if true then sdl_preloaded_pt.json file will be updated, otherwise - false
--! @return: none
--]]
function m.preconditions(isPreloadedUpdate)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  actions.preconditions()
  if isPreloadedUpdate == true then
    m.backupPreloadedPT()
    m.updatePreloadedPT()
  end
end

--! @pTUpdateFunc: Policy Table Update with allowed "Base-4" group for application
--! @parameters:
--! tbl: policy table
--! @return: none
function m.pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps", }
      },
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps", }
      },
      UnsubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps", }
      },
      OnVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps"}
      }
    }
  }
  tbl.policy_table.functional_groupings.NewVehicleDataGroup = VDgroup
  tbl.policy_table.app_policies[m.getParams(1).fullAppID].groups = {"Base-4", "NewVehicleDataGroup"}
end

--[[ @setHashId: Set hashId which is required during resumption
--! @parameters:
--! pHashValue: application hashId
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.setHashId(pHashValue, pAppId)
  hashId[pAppId] = pHashValue
end

--[[ @getHashId: Get hashId of an app which is required during resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: app's hashId
--]]
function m.getHashId(pAppId)
  return hashId[pAppId]
end

--[[ @getVehicleData: Processing GetVehicleData RPC
--! @parameters:
--! pData: parameters for mobile response
--! pResult: expected result code
--! @return: none
--]]
function m.getVehicleData(pData, pResult)
  if not pResult then pResult = { success = true, resultCode = "SUCCESS", windowStatus = pData } end
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { windowStatus = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { windowStatus = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { windowStatus = pData })
    end)
  m.getMobileSession():ExpectResponse(cid, pResult)
end

--[[ @sendGetVehicleData: GetVehicleData RPC processing to check each param of the `windowStatus` structure
--! @parameters:
--! pParam: parameters from Grid/WindowState structure
--! pData: parameters from windowStatus structure(location, state)
--! pValue: value for parameters
--! pTb: table with windowStatus data
--! pResult: expected result code
--! @return: none
--]]
function m.sendGetVehicleData(pParam, pData, pValue, pTb, pResult)
  local params = pTb
  if not pResult then pResult = { success = true, resultCode = "SUCCESS" } end
  params[1][pData][pParam] = pValue
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { windowStatus = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { windowStatus = true })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { windowStatus = params })
    end)
  m.getMobileSession():ExpectResponse(cid, pResult, { windowStatus = params })
end

--[[ @processRPCFailure: Processing VD RPC with ERROR resultCode
--! @parameters:
--! pRPC: RPC for mobile request
--! pResult: result error
--! @return: none
--]]
function m.processRPCFailure(pRPC, pResult)
  local cid = m.getMobileSession():SendRPC(pRPC, { windowStatus = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResult })
end

--[[ @subUnScribeVD: Processing SubscribeVehicleData and UnsubscribeVehicleData RPCs
--! @parameters:
--! pRPC: RPC for mobile request
--! pAppID: application number (1, 2, etc.)
--! @return: none
--]]
function m.subUnScribeVD(pRPC, pAppID)
  if not pAppID then pAppID = 1 end
  local cid = m.getMobileSession(pAppID):SendRPC(pRPC, { windowStatus = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { windowStatus = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { windowStatus = m.subUnsubParams })
    end)
  m.getMobileSession(pAppID):ExpectResponse(cid, { success = true, resultCode = "SUCCESS", windowStatus = m.subUnsubParams })
  m.getMobileSession(pAppID):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppID)
  end)
end

--[[ @checkResumption: function that checks resume of subscription for two applications
--! @parameters:
--! pFirstApp: true - in case SDL sends VehicleInfo.SubscribeVehicleData_requset to HMI, otherwise - false
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.checkResumption(pFirstApp, pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeVehicleData", { windowStatus = true })
  if pFirstApp then
    m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { windowStatus = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { windowStatus = m.subUnsubParams })
    end)
  end
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS", windowStatus = m.subUnsubParams })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @sendOnVehicleData: Processing OnVehicleData RPC
--! @parameters:
--! pData: parameters for the notification
--! pExpTime: number of notifications
--! pAppID: application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnVehicleData(pData, pExpTime, pAppID)
  if not pExpTime then pExpTime = 1 end
  if not pAppID then pAppID = 1 end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { windowStatus = pData })
  m.getMobileSession(pAppID):ExpectNotification("OnVehicleData", { windowStatus = pData })
  :Times(pExpTime)
end

--[[ @checkNotificationIgnored:
--! @parameters:
--! pParam:
--! pData: parameters for the notification
--! pValue:
--! pTb: table with windowStatus data
--! @return: none
--]]
function m.checkNotificationIgnored(pParam, pData, pValue, pTb)
  local params = pTb
  params[1][pData][pParam] = pValue

  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { windowStatus = params })
  m.getMobileSession():ExpectNotification("OnVehicleData", { windowStatus = params })
  :Times(0)
end

--[[ @ignitionOff: IGNITION_OFF sequence
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
  config.ExitOnCrash = false
  local timeout = 5000
  local function removeSessions()
    for i = 1, m.getAppsCount() do
      m.deleteSession(i)
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      removeSessions()
      StopSDL()
      config.ExitOnCrash = true
    end)
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i = 1, m.getAppsCount() do
        m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(m.getAppsCount())
  local isSDLShutDownSuccessfully = false
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      RAISE_EVENT(event, event)
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

-- [[ @unexpectedDisconnect: closing connection
-- ! @parameters: none
-- ! @return: none
-- ]]
function m.unexpectedDisconnect()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  utils.wait(1000)
end

--[[ @checkResumption_FULL: function that checks HMIlevel to FULL recovery after resumption
--! @parameters: none
--! @return: none
--]]
function m.checkResumption_FULL()
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE" },
    { hmiLevel = "FULL" })
  :Times(2)
end

--[[ @checkResumption_NONE: function that checks HMIlevel to NONE recovery after resumption
--! @parameters: none
--! @return: none
--]]
function m.checkResumption_NONE()
  m.getMobileSession(1):ExpectNotification("OnHMIStatus",{ hmiLevel = "NONE" })
end


--[[ @registerWithResumption: re-register application with SUCCESS resultCode
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! pLevelCheckFunc: check function
--! isHMIsubscription: if false SDL resumes SubscribeVehicleData for app2 and does not send VehicleInfo.SubscribeVehicleData request to HMI
--! @return: none
--]]
function m.registerWithResumption(pAppId, pLevelCheckFunc, isHMIsubscription)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
    local params = m.cloneTable(m.getConfigAppParams(pAppId))
    params.hashID = m.getHashId(pAppId)
    local corId = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", params)
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getConfigAppParams(pAppId).appName }
    })
    :Do(function(_, data)
      if true == isHMIsubscription then
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { windowStatus = true })
        m.getHMIConnection():SendResponse( data.id, data.method, "SUCCESS", { windowStatus = m.subUnsubParams })
      else
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { windowStatus = true })
        :Times(0)
      end
    end)
    m.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
  end)
  pLevelCheckFunc(pAppId)
end

--[[ @postcondition: Stop SDL and restore sdl_preloaded_pt.json file
--! @parameters: none
--! @return: none
--]]
function m.postconditions()
  actions.postconditions()
  m.restorePreloadedPT()
end

return m
