---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local json = require("modules/json")
local utils = require("user_modules/utils")
local runner = require('user_modules/script_runner')
local SDL = require("SDL")

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2
config.defaultProtocolVersion = 2
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local m = {}
local hashId = {}
local handsOffSteeringResponseData = {
  dataType = "VEHICLEDATA_HANDSOFFSTEERING",
  resultCode = "SUCCESS"
}

--[[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.registerApp = actions.registerApp
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.getParams = actions.app.getParams
m.cloneTable = utils.cloneTable
m.start = actions.start
m.postconditions = actions.postconditions
m.policyTableUpdate = actions.policyTableUpdate
m.getAppsCount = actions.getAppsCount
m.EMPTY_ARRAY = json.EMPTY_ARRAY
m.deleteSession = actions.mobile.deleteSession
m.connectMobile = actions.mobile.connect
m.wait = utils.wait
m.spairs = utils.spairs

--[[ Common Functions ]]
--[[ @updatedPreloadedPTFile: Update preloaded file with additional permissions for handsOffSteering
--! @parameters:
--! pGroup: table with additional updates (optional)
--! @return: none
--]]
function m.updatedPreloadedPTFile(pGroup)
  local pt = m.getPreloadedPT()
  if not pGroup then
    pGroup = {
      rpcs = {
        GetVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        OnVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        SubscribeVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        UnsubscribeVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        }
      }
    }
  end
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroup
  pt.policy_table.app_policies["default"].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  m.setPreloadedPT(pt)
end

--[[ @preconditions: Clean environment, backup and update of sdl_preloaded_pt.json file
 --! @parameters:
 --! pGroup: data for updating sdl_preloaded_pt.json file
 --! @return: none
 --]]
function m.preconditions(pGroup)
  actions.preconditions()
  m.updatedPreloadedPTFile(pGroup)
end

--[[ @setHashId: Set hashId value which is required during resumption
--! @parameters:
--! pHashId: hashId value to store
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.setHashId(pHashId, pAppId)
  hashId[pAppId] = pHashId
end

--[[ @getHashId: Get hashId value of an app which is required during resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: app's hashId
--]]
function m.getHashId(pAppId)
  return hashId[pAppId]
end

--[[ @getVehicleData: Processing of GetVehicleData RPC
--! @parameters:
--! pHandsOffSteering: handsOffSteering parameter value
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.getVehicleData(pHandsOffSteering, pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("GetVehicleData", { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { handsOffSteering = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { handsOffSteering = pHandsOffSteering })
  end)
  m.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = pHandsOffSteering })
end

--[[ @processSubscriptionRPCsSuccess: Successful processing of Subscribe/UnsubscribeVehicleData RPC
--! for handsOffSteering data
--! @parameters:
--! pRpcName: RPC name
--! pAppId: application number (1, 2, etc.)
--! isRequestOnHMIExpected: true - in case VehicleInfo.Sub/UnsubscribeVehicleData request on HMI is expected,
--! otherwise - false
--! @return: none
--]]
function m.processSubscriptionRPCsSuccess(pRpcName, pAppId, isRequestOnHMIExpected)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC(pRpcName, { handsOffSteering = true })
  if isRequestOnHMIExpected == true or isRequestOnHMIExpected == nil then
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName, { handsOffSteering = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { handsOffSteering = handsOffSteeringResponseData })
    end)
  else
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName):Times(0)
  end
  m.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = handsOffSteeringResponseData })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @processRPCHMIInvalidResponse: Processing of Subscribe/UnsubscribeVehicleData RPC with invalid HMI response
--! @parameters:
--! @pRpcName: RPC name
--! @pData: handsOffSteering data for HMI response
--! @return: none
--]]
function m.processRPCHMIInvalidResponse(pRpcName, pData)
  local cid = m.getMobileSession():SendRPC(pRpcName, { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName, { handsOffSteering = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, { handsOffSteering = pData })
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  m.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

--[[ @processRPCUnsuccessRequest: function for processing of invalid vehicle data request
--! @parameters:
--! @pRpcName: RPC name
--! @pHandsData: handsOffSteering value for the request
--! @pResult: resultCode value for expectation on App
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.processRPCUnsuccessRequest(pRpcName, pHandsData, pResult, pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC(pRpcName, { handsOffSteering = pHandsData })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName) :Times(0)
  m.getMobileSession(pAppId):ExpectResponse(cid, pResult)
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange") :Times(0)
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

--[[ @registerAppSuccessWithResumption: Successful application registration with custom expectations for resumption
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! isHMISubscription: if true VD.SubscribeVehicleData request is expected on HMI, otherwise - not expected
--! @return: none
--]]
function m.registerAppSuccessWithResumption(pAppId, isHMISubscription)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
    local params = m.cloneTable(m.getParams(pAppId))
    params.hashID = m.getHashId(pAppId)
    local corId = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", params)
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getParams(pAppId).appName }
    })
    if isHMISubscription == true then
      m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { handsOffSteering = true })
      :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { handsOffSteering = handsOffSteeringResponseData })
      end)
    else
      m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData"):Times(0)
    end
    m.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
  end)
end

--[[ @onVehicleData: Processing of OnVehicleData notification
--! @parameters:
--! pHandsOffSteering: handsOffSteering parameter value
--! pExpTimes:  expected number of notifications
--! @return: none
--]]
function m.onVehicleData(pHandsOffSteering, pExpTimes)
  if not pExpTimes then pExpTimes = 1 end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = pHandsOffSteering })
  m.getMobileSession():ExpectNotification("OnVehicleData", { handsOffSteering = pHandsOffSteering })
  :Times(pExpTimes)
end

--[[ @onVehicleDataForTwoApps: Processing of OnVehicleData notification for two apps
--! @parameters:
--! pHandsOffSteering: handsOffSteering parameter value
--! pExpTimes:  expected number of notifications
--! @return: none
--]]
function m.onVehicleDataForTwoApps(pHandsOffSteering, pExpTimes)
  if pExpTimes == nil then pExpTimes = 1 end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = pHandsOffSteering })
  m.getMobileSession(1):ExpectNotification("OnVehicleData", { handsOffSteering = pHandsOffSteering })
  :Times(pExpTimes)
  m.getMobileSession(2):ExpectNotification("OnVehicleData", { handsOffSteering = pHandsOffSteering })
  :Times(pExpTimes)
end

--[[ @unexpectedDisconnect: closing connection
--! @parameters: none
--! @return: none
--]]
function m.unexpectedDisconnect()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  m.wait(1000)
end

return m
