---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.fullAppID = "SPT"
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local common = require("test_scripts/Security/SSLHandshakeFlow/common")
local events = require("events")
local constants = require("protocol_handler/ford_protocol_constants")

--[[ Variables ]]
local m = actions
m.wait = utils.wait

--[[ Common Functions ]]
function m.ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = utils.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
end

local preconditionsOrig = common.preconditions
function m.preconditions(pForceProtectedServices, pForceUnprotectedServices)
  preconditionsOrig()
  if not pForceProtectedServices then pForceProtectedServices = "Non" end
  if not pForceUnprotectedServices then pForceUnprotectedServices = "Non" end
  m.setSDLIniParameter("ForceProtectedService", pForceProtectedServices)
  m.setSDLIniParameter("ForceUnprotectedService", pForceUnprotectedServices)
end

local postconditionsOrig = common.postconditions
function m.postconditions()
  postconditionsOrig()
  m.restoreSDLIniParameters()
end

local policyTableUpdate_orig = m.policyTableUpdate
function m.policyTableUpdate(pPTUpdateFunc)
  local function expNotificationFunc()
    m.getHMIConnection():ExpectRequest("BasicCommunication.DecryptCertificate")
    :Do(function(_, d)
        m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { })
      end)
    :Times(AnyNumber())
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  end
  policyTableUpdate_orig(pPTUpdateFunc, expNotificationFunc)
end

function m.policyTableUpdateUnsuccess()
  local requestId = m.getHMIConnection():SendRequest("SDL.GetURLS", { service = 7 })
  m.getHMIConnection():ExpectResponse(requestId)
  :Do(function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "/fs/mp/somefile" })

      local event = events.Event()
      event.matches = function(e1, e2) return e1 == e2 end
      m.getHMIConnection():ExpectEvent(event, "PTU event")
      for id = 1, m.getAppsCount() do
        m.getMobileSession(id):ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function()
            local corIdSystemRequest = m.getMobileSession(id):SendRPC("SystemRequest", {
              requestType = "PROPRIETARY" })
            m.getHMIConnection():ExpectRequest("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                m.getHMIConnection():SendError(d3.id, "BasicCommunication.SystemRequest", "REJECTED", { })
              end)
            m.getMobileSession(id):ExpectResponse(corIdSystemRequest, { success = false, resultCode = "REJECTED" })
            utils.cprint(35, "App ".. id .. " was used for PTU")
            m.getHMIConnection():RaiseEvent(event, "PTU event")
          end)
        :Times(AtMost(1))
      end
    end)
end

function m.startStream()
  m.getHMIConnection():ExpectRequest("Navigation.StartStream")
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

function m.startAudioStream()
  m.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

function m.startVideoStreaming()
  m.getMobileSession():StartStreaming(11, "files/SampleVideo_5mb.mp4")
  m.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
  m.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

function m.startAudioStreaming()
  m.getMobileSession():StartStreaming(10, "files/tone_mp3.mp3")
  m.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = true })
  m.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

function m.startServiceProtected(pServiceId, pAppId)

  m.getMobileSession():StartSecureService(pServiceId)

  local serviceTypeValue
  local streamingFunc
  if pServiceId == 11 then
    m.startStream()
    serviceTypeValue = "VIDEO"
    streamingFunc = m.startVideoStreaming
  elseif pServiceId == 10 then
    m.startAudioStream()
    serviceTypeValue = "AUDIO"
    streamingFunc = m.startAudioStreaming
  else
    serviceTypeValue = "RPC"
  end

  m.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = serviceTypeValue, appID = m.getHMIAppId(pAppId) },
    { serviceEvent = "REQUEST_ACCEPTED", serviceType = serviceTypeValue, appID = m.getHMIAppId(pAppId) })
  :Times(2)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
  { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
  :Times(3)

  m.getMobileSession():ExpectHandshakeMessage()
  :Times(1)

  m.policyTableUpdateSuccess(m.ptUpdate)

  m.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = m.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
  :Do(function(_, data)
    if data.frameInfo == m.frameInfo.START_SERVICE_ACK and
    (data.serviceType == 10 or data.serviceType == 11) then
      streamingFunc()
    end
  end)

end

function m.startServiceUnprotected(pServiceId, pAppId)

  local msg = {
    frameType = constants.FRAME_TYPE.CONTROL_FRAME,
    serviceType = pServiceId,
    frameInfo = constants.FRAME_INFO.START_SERVICE,
    encryption = false
  }
  m.getMobileSession():Send(msg)

  local serviceTypeValue
  local streamingFunc
  if pServiceId == 11 then
    m.startStream()
    serviceTypeValue = "VIDEO"
    streamingFunc = m.startVideoStreaming

  elseif pServiceId == 10 then
    m.startAudioStream()
    serviceTypeValue = "AUDIO"
    streamingFunc = m.startAudioStreaming
  end

  m.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = serviceTypeValue, appID = m.getHMIAppId(pAppId) },
    { serviceEvent = "REQUEST_ACCEPTED", serviceType = serviceTypeValue, appID = m.getHMIAppId(pAppId) })
  :Times(2)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)

  m.getMobileSession():ExpectHandshakeMessage()
  :Times(0)

  m.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = m.frameInfo.START_SERVICE_ACK,
    encryption = false
  })
  :Do(function(_, data)
    if data.frameInfo == m.frameInfo.START_SERVICE_ACK then
      streamingFunc()
    end
  end)

end

function m.startServiceProtectedGetSystemTimeUnsuccessNACK(pServiceId, pGetSystemTimeResFunc)

  common.getMobileSession():StartSecureService(pServiceId)

  local serviceTypeValue
  if pServiceId == 11 then
    common.startStream()
    serviceTypeValue = "VIDEO"
  elseif pServiceId == 10 then
    common.startAudioStream()
    serviceTypeValue = "AUDIO"
  else
    serviceTypeValue = "RPC"
  end

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = serviceTypeValue, appID = common.getHMIAppId() },
    { serviceEvent = "REQUEST_REJECTED", serviceType = serviceTypeValue, reason = "INVALID_TIME", appID = common.getHMIAppId() })
  :Times(2)

  local startserviceEvent = events.Event()
  startserviceEvent.level = 3
    startserviceEvent.matches = function(_, data)
      return
      data.method == "BasicCommunication.GetSystemTime"
    end

  common.getHMIConnection():ExpectEvent(startserviceEvent, "GetSystemTime")
  :Do(function(_, data)
      pGetSystemTimeResFunc(data)
    end)

  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)

  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })

end

function m.startServiceProtectedGetSystemTimeUnsuccessACK(pServiceId, pGetSystemTimeResFunc)

  common.getMobileSession():StartSecureService(pServiceId)

  local serviceTypeValue
  local streamingFunc
  if pServiceId == 11 then
    m.startStream()
    serviceTypeValue = "VIDEO"
    streamingFunc = m.startVideoStreaming
  elseif pServiceId == 10 then
    m.startAudioStream()
    serviceTypeValue = "AUDIO"
    streamingFunc = m.startAudioStreaming
  end

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = serviceTypeValue, appID = common.getHMIAppId() },
    { serviceEvent = "REQUEST_ACCEPTED", serviceType = serviceTypeValue, appID = common.getHMIAppId() })
  :Times(2)
  :ValidIf(function(_, data)
    if data.params.reason then
      return false, "SDL sends unexpected parameter 'reason' in OnServiceUpdate notification"
    end
    return true
  end)

  local startserviceEvent = events.Event()
  startserviceEvent.level = 3
    startserviceEvent.matches = function(_, data)
      return
      data.method == "BasicCommunication.GetSystemTime"
    end

  common.getHMIConnection():ExpectEvent(startserviceEvent, "GetSystemTime")
  :Do(function(_, data)
      pGetSystemTimeResFunc(data)
    end)

  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)

  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = false
  })
  :Do(function(_, data)
    if data.frameInfo == m.frameInfo.START_SERVICE_ACK then
      streamingFunc()
    end
  end)

end


function m.startServiceProtectedUnsuccessPTU(pServiceId, pAppId)

  m.getMobileSession():StartSecureService(pServiceId)

  local serviceTypeValue
  local streamingFunc
  if pServiceId == 11 then
    m.startStream()
    serviceTypeValue = "VIDEO"
    streamingFunc = m.startVideoStreaming
  elseif pServiceId == 10 then
    m.startAudioStream()
    serviceTypeValue = "AUDIO"
    streamingFunc = m.startAudioStreaming
  else
    serviceTypeValue = "RPC"
  end

  m.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = serviceTypeValue, appID = m.getHMIAppId(pAppId) },
    { serviceEvent = "REQUEST_REJECTED",reason = "PTU_FAILED", serviceType = serviceTypeValue, appID = m.getHMIAppId(pAppId) })
  :Times(2)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
  { status = "UPDATE_NEEDED" }, { status = "UPDATING" },
  { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(4)

  m.getMobileSession():ExpectHandshakeMessage()
  :Times(0)

  m.policyTableUpdateUnsuccess()

  m.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = m.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
  :Do(function(_, data)
    if data.frameInfo == m.frameInfo.START_SERVICE_ACK and
    (data.serviceType == 10 or data.serviceType == 11) then
      streamingFunc()
    end
  end)

end

return m
