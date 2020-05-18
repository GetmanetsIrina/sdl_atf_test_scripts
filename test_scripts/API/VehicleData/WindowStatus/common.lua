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
local SDL = require("SDL")

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
m.deleteSession = actions.mobile.deleteSession
m.connectMobile = actions.mobile.connect
m.getAppsCount = actions.getAppsCount
m.getConfigAppParams = actions.getConfigAppParams
m.EMPTY_ARRAY = json.EMPTY_ARRAY
m.postconditions = actions.postconditions
m.wait = utils.wait
m.getMobileConnection = actions.mobile.getConnection
m.isSdlRunning = actions.sdl.isRunning

local windowStatusData = {
  {
    location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
    state = {
      approximatePosition = 50,
      deviation = 50
    }
  }
}

m.subUnsubParams = {
  dataType = "VEHICLEDATA_WINDOWSTATUS",
  resultCode = "SUCCESS"
}

--[[ Functions ]]

--[[ @updatePreloadedPT: Update preloaded file with additional permissions for WindowStatus
--! @parameters: none
--! @return: none
--]]
function m.updatePreloadedPT()
  local pt = m.getPreloadedPT()
  local WindowStatusGroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
        parameters = { "windowStatus" }
      },
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
        parameters = { "windowStatus" }
      },
      OnVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
        parameters = { "windowStatus" }
      },
      UnsubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
        parameters = { "windowStatus" }
      }
    }
  }
  pt.policy_table.app_policies["default"].groups = { "Base-4", "WindowStatus" }
  pt.policy_table.functional_groupings["WindowStatus"] = WindowStatusGroup
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  m.setPreloadedPT(pt)
end

--[[ @preconditions: Clean environment, optional backup and update of sdl_preloaded_pt.json file
--! @parameters:
--! isPreloadedUpdate: if omitted or true then sdl_preloaded_pt.json file will be updated, otherwise - false
--! @return: none
--]]
function m.preconditions(isPreloadedUpdate)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  actions.preconditions()
  if isPreloadedUpdate == true then
    m.updatePreloadedPT()
  end
end

--! @pTUpdateFunc: Policy Table Update with allowed "Base-4" and custom groups for application
--! @parameters:
--! tbl: policy table
--! @return: none
function m.pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      UnsubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      OnVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      }
    }
  }
  tbl.policy_table.functional_groupings.NewVehicleDataGroup = VDgroup
  tbl.policy_table.app_policies[m.getParams().fullAppID].groups = { "Base-4", "NewVehicleDataGroup" }
end

--[[ @setHashId: Set hashId value which is required during resumption
--! @parameters:
--! pHashValue: application hashId
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.setHashId(pHashValue, pAppId)
  hashId[pAppId] = pHashValue
end

--[[ @getHashId: Get hashId value of an app which is required during resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: app's hashId
--]]
function m.getHashId(pAppId)
  return hashId[pAppId]
end

--[[ @getWindowStatusParams: Clone table with windowStatus data for use to GetVD and OnVD RPCs
--! @parameters:none
--! @return: table for GetVD and OnVD
--]]
function m.getWindowStatusParams()
  return utils.cloneTable(windowStatusData)
end

--[[ @getCustomData: Preparation of custom `windowStatus` structure
--! @parameters:
--! pSubParam: subparameter from `windowStatus` structure
--! pParam: parameter from `windowStatus` structure
--! pValue: value for parameters from the `windowStatus` structure
--! @return: custom `windowStatus` structure
--]]
function m.getCustomData(pSubParam, pParam, pValue)
  local params = m.getWindowStatusParams()
  params[1][pParam][pSubParam] = pValue
  return params
end

--[[ @getVehicleData: Processing GetVehicleData RPC
--! @parameters:
--! pData: data for mobile response
--! pResult: expected result code for mobile response
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

--[[ @processRPCFailure: Processing VD RPC with ERROR resultCode
--! @parameters:
--! pRPC: RPC for mobile request
--! pResult: Result code for mobile response
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
--! isRequestOnHMIExpected: true or omitted - in case VehicleInfo.Sub/UnsubscribeVehicleData_request on HMI is expected, otherwise - false
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.subUnScribeVD(pRPC, isRequestOnHMIExpected, pAppId)
  if not pAppId then pAppId = 1 end
  if isRequestOnHMIExpected == nil then isRequestOnHMIExpected = true end
  local cid = m.getMobileSession(pAppId):SendRPC(pRPC, { windowStatus = true })
  if isRequestOnHMIExpected then
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { windowStatus = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { windowStatus = m.subUnsubParams })
    end)
  else
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  end
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS", windowStatus = m.subUnsubParams })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @sendOnVehicleData: Processing OnVehicleData RPC
--! @parameters:
--! pData: data for the notification
--! pExpTime: number of notifications
--! pAppID: application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnVehicleData(pData, pExpTime)
  if not pExpTime then pExpTime = 1 end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { windowStatus = pData })
  m.getMobileSession():ExpectNotification("OnVehicleData", { windowStatus = pData })
  :Times(pExpTime)
end

--[[ @ignitionOff: IGNITION_OFF sequence
--! @parameters: none
--! @return: none
--]]
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
    :Times(AtMost(1))
  end)
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then m.cprint(35, "BC.OnSDLClose was not sent") end
    if SDL:CheckStatusSDL() == SDL.RUNNING then SDL:StopSDL() end
    for i = 1, m.getAppsCount() do
      m.deleteSession(i)
    end
  end)
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

--[[ @registerAppWithResumption: Successful app registration with resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! isHMIsubscription: if true VD.SubscribeVehicleData request is expected on HMI, otherwise - not expected
--! @return: none
--]]
function m.registerAppWithResumption(pAppId, isHMIsubscription)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
    m.getConfigAppParams(pAppId).hashID = m.getHashId(pAppId)
    local corId = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getConfigAppParams(pAppId).appName }
    })
    :Do(function()
      if true == isHMIsubscription then
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { windowStatus = true })
        :Do(function(_, data)
          m.getHMIConnection():SendResponse( data.id, data.method, "SUCCESS", { windowStatus = m.subUnsubParams })
        end)
      else
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData"):Times(0)
      end
    end)
    m.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
  end)
end

return m
