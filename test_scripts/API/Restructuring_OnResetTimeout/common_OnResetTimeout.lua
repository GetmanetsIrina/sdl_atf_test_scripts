---------------------------------------------------------------------------------------------------
-- Сommon module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2
config.ValidateSchema = false
config.checkAllValidations = true
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5

--[[ Required Shared libraries ]]
local test = require("user_modules/dummy_connecttest")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local json = require("modules/json")
local utils = require('user_modules/utils')
local actions = require("user_modules/sequences/actions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Common Variables ]]
local c = actions

c.jsonFileToTable = utils.jsonFileToTable
c.tableToJsonFile = utils.tableToJsonFile
c.cloneTable = utils.cloneTable
c.modules = { "RADIO", "CLIMATE" }

c.rpcs = {
  "SendLocation",
  "Alert",
  "PerformInteraction",
  "DialNumber",
  "Slider",
  "Speak",
  "DiagnosticMessage",
  "ScrollableMessage",
  "SubscribeButton",
  "SetInteriorVehicleData"
}

c.rpcsError = {
  "sendLocationError",
  "alertError",
  "performInteractionError",
  "dialNumberError",
  "sliderError",
  "speakError",
  "diagnosticMessageError",
  "subscribeButtonError",
  "scrollableMessageError",
  "setInteriorVehicleDataError"
}

--[[ Common Functions ]]
function c.getAppConfig(tbl)
  if tbl then
    local out = c.cloneTable(tbl.policy_table.app_policies.default)
    out.moduleType = c.modules
    out.groups = { "Base-4", "RemoteControl" }
    out.AppHMIType = { "REMOTE_CONTROL" }
    return out
  else
    return {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = c.modules,
      groups = { "Base-4", "RemoteControl" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
  end
end

local function backupPreloadedPT()
  local preloadedFile = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  commonPreconditions:BackupFile(preloadedFile)
end

local function updatePreloadedPT(pCountOfRCApps)
  if not pCountOfRCApps then pCountOfRCApps = 2 end
  local preloadedFile = commonPreconditions:GetPathToSDL()
  .. commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local preloadedTable = c.jsonFileToTable(preloadedFile)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  preloadedTable.policy_table.functional_groupings["RemoteControl"].rpcs = {
    SetInteriorVehicleData = {
      hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
    },
    SendLocation = {
      hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
    },
    DialNumber = {
      hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
    },
    DiagnosticMessage = {
      hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
    },
    ButtonPress = {
      hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
    }
  }
  for i = 1, pCountOfRCApps do
    local appId = config["application" .. i].registerAppInterfaceParams.fullAppID
    preloadedTable.policy_table.app_policies[appId] = c.getAppConfig(preloadedTable)
    preloadedTable.policy_table.app_policies[appId].AppHMIType = nil
  end
  c.tableToJsonFile(preloadedTable, preloadedFile)
end

function c.preconditions(isPreloadedUpdate, pCountOfRCApps)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  if isPreloadedUpdate == true then
    backupPreloadedPT()
    updatePreloadedPT(pCountOfRCApps)
  end
end

local function restorePreloadedPT()
  local preloadedFile = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  commonPreconditions:RestoreFile(preloadedFile)
end

--[[ @sendLocation: Successful Processing of GetInteriorVehicleDataConsent RPC
--! @parameters:
--! pRequestID - Id between HMI and SDL which SDL used to send the request for method in question, for which timeout needs to be reset.
--! pMethodName - Name of the function for which timeout needs to be reset.
--! pResetPeriod - Timeout period in milliseconds, for the method for which timeout needs to be reset.
--! pWait - Time in seconds after which HMI respond to received the request.
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function c.rpcAllowedWithConsent(pAppId, pRPC, pRequestID, pMethodName, pResetPeriod, pWait)
  if not pAppId then pAppId = 1 end
  if not pRPC then pRPC = "SetInteriorVehicleData" end
  local cid = c.getMobileSession(pAppId):SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, "CLIMATE"))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, "CLIMATE", pAppId))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, true))
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), commonRC.getHMIRequestParams(pRPC, "CLIMATE", pAppId))
      :Do(function(_, data2)
        c.onResetTimeoutNotification(data2.id, pMethodName, pResetPeriod)
        local function sendResponse()
          commonRC.getHMIConnection():SendResponse(data2.id, data2.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC, "CLIMATE"))
        end
        RUN_AFTER(sendResponse, pWait)
        end)
    end)
  c.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.rpcAllowedWithConsentError( pAppId, pRPC, pRequestID, pResetPeriod, pWait, pMethodName)
  if not pMethodName then pMethodName = "SetInteriorVehicleData" end
  if not pAppId then pAppId = 1 end
  if not pRPC then pRPC = "SetInteriorVehicleData" end
  local cid = c.getMobileSession(pAppId):SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, "CLIMATE"))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, "CLIMATE", pAppId))
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Times(pWait)
end

--[[ @onResetTimeoutNotification: Notification from HMI  in case the results long processing on HMI
--! @parameters:
--! pRequestID - Id between HMI and SDL which SDL used to send the request for method in question, for which timeout needs to be reset.
--! pMethodName - Name of the function for which timeout needs to be reset.
--! pResetPeriod - Timeout period in milliseconds, for the method for which timeout needs to be reset.
--! @return: none
--]]
function c.onResetTimeoutNotification(pRequestID, pMethodName, pResetPeriod)
  c.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout",
    { requestID = pRequestID,
    methodName = pMethodName,
    resetPeriod = pResetPeriod
  })
end

function c.SendLocation( pRequestID, pMethodName, pResetPeriod, pWait )
  local sendLocationRequestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    locationName = "location Name",
    locationDescription = "location Description",
    addressLines = {
      "line1",
      "line2",
    },
    phoneNumber = "phone Number"
  }
  local cid = c.getMobileSession():SendRPC("SendLocation", sendLocationRequestParams)
  EXPECT_HMICALL("Navigation.SendLocation", { appID = c.getHMIAppId() })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendresponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end
    RUN_AFTER(sendresponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.sendLocationError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "SendLocation" end
  local sendLocationRequestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    locationName = "location Name",
    locationDescription = "location Description",
    addressLines = {
      "line1",
      "line2",
    },
    phoneNumber = "phone Number"
  }
  local cid = c.getMobileSession():SendRPC("SendLocation", sendLocationRequestParams)
  EXPECT_HMICALL("Navigation.SendLocation", { appID = c.getHMIAppId() })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.Alert( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("Alert",
    { ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    }
  })
  c.getHMIConnection():ExpectRequest("TTS.Speak",
    { ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    },
    appID = c.getHMIAppId()
  })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end
    RUN_AFTER(sendResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  :Timeout(pResetPeriod)
end

function c.alertError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "Alert" end
  local cid = c.getMobileSession():SendRPC("Alert",
    { ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    }
  })
  c.getHMIConnection():ExpectRequest("TTS.Speak",
    { ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    },
    appID = c.getHMIAppId()
  })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.createInteractionChoiceSet()
  local params = {
    interactionChoiceSetID = 100,
    choiceSet = {
      {
        choiceID = 111,
        menuName = "Choice111",
        vrCommands = { "Choice111" }
      }
    }
  }
  local corId = c.getMobileSession():SendRPC("CreateInteractionChoiceSet", params)
  c.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
     c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  c.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

function c.PerformInteraction( pRequestID, pMethodName, pResetPeriod, pWait )
  local params = {
    initialText = "StartPerformInteraction",
    interactionMode = "VR_ONLY",
    interactionChoiceSetIDList = { 100 },
    initialPrompt = {
      { type = "TEXT", text = "pathToFile1" }
    }
  }
  local corId = c.getMobileSession():SendRPC("PerformInteraction", params)
  c.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end
    RUN_AFTER(sendResponse, pWait)
  end)
  c.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    initialPrompt = params.initialPrompt
  })
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  c.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.performInteractionError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "PerformInteraction" end
  local params = {
    initialText = "StartPerformInteraction",
    interactionMode = "VR_ONLY",
    interactionChoiceSetIDList = { 100 },
    initialPrompt = {
      { type = "TEXT", text = "pathToFile1" }
    }
  }
  local corId = c.getMobileSession():SendRPC("PerformInteraction", params)
  c.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    initialPrompt = params.initialPrompt
  })
  :Do(function(_, data)
    c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  c.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.DialNumber( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("DialNumber", { number = "#3804567654*" })

  EXPECT_HMICALL("BasicCommunication.DialNumber", { appID = c.getHMIAppId() })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end
    RUN_AFTER(sendResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.dialNumberError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "DialNumber" end
  local cid = c.getMobileSession():SendRPC("DialNumber", { number = "#3804567654*" })
  EXPECT_HMICALL("BasicCommunication.DialNumber", { appID = c.getHMIAppId() })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.Slider( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("Slider",
    {
      numTicks = 7,
      position = 1,
      sliderHeader ="sliderHeader",
      timeout = 1000,
      sliderFooter = { "sliderFooter" }
    })
  EXPECT_HMICALL("UI.Slider", { appID = c.getHMIAppId() })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendReponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})
      c.getHMIConnection():SendNotification("UI.OnSystemContext",
        { appID = c.getHMIAppId(), systemContext = "MAIN" })
    end
    RUN_AFTER(sendReponse, pWait)
  end)
  :Do(function(_,data)
      c.getHMIConnection():SendNotification("UI.OnSystemContext",
        { appID = c.getHMIAppId(), systemContext = "HMI_OBSCURED" })
    end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })
  :Timeout(pResetPeriod)
end

function c.sliderError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "Slider" end
  local cid = c.getMobileSession():SendRPC("Slider",
    {
      numTicks = 7,
      position = 1,
      sliderHeader ="sliderHeader",
      timeout = 1000,
      sliderFooter = { "sliderFooter" }
    })
  EXPECT_HMICALL("UI.Slider", { appID = c.getHMIAppId() })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.Speak( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("Speak",
    {
    ttsChunks = {
      { text ="a",
        type ="TEXT"
      }
    }
  })
  EXPECT_HMICALL("TTS.Speak",
  {
    ttsChunks = {
      { text ="a",
        type ="TEXT"
      }
    }
  })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendSpeakResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      c.getHMIConnection():SendNotification("TTS.Stopped")
    end
    RUN_AFTER(sendSpeakResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.speakError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "Speak" end
  local cid = c.getMobileSession():SendRPC("Speak",
    {
    ttsChunks = {
      { text ="a",
        type ="TEXT"
      }
    }
  })
  EXPECT_HMICALL("TTS.Speak",
  {
    ttsChunks = {
      { text ="a",
        type ="TEXT"
      }
    }
  })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.DiagnosticMessage( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("DiagnosticMessage",
  { targetID = 1,
    messageLength = 1,
    messageData = { 1 }
  })
  EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
  { targetID = 1,
    messageLength = 1,
    messageData = { 1 }
  })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {messageDataResult = {12}})
    end
    RUN_AFTER(sendResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.diagnosticMessageError( pRequestID, pResetPeriod, pWait, pAppId, pMethodName )
  if not pMethodName then pMethodName = "DiagnosticMessage" end
  if not pAppId then pAppId = 1 end
  local cid = c.getMobileSession():SendRPC("DiagnosticMessage",
  { targetID = 1,
    messageLength = 1,
    messageData = { 1 }
  })
  EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
  { targetID = 1,
    messageLength = 1,
    messageData = { 1 }
  })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.SubscribeButton( pRequestID, pMethodName, pResetPeriod, pWait)
  local cid = c.getMobileSession():SendRPC("SubscribeButton", { buttonName = "OK" })
  EXPECT_HMICALL("Buttons.SubscribeButton", { appID = c.getHMIAppId(), buttonName = "OK" })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end
    RUN_AFTER(sendResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.subscribeButtonError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "SubscribeButton" end
  local cid = c.getMobileSession():SendRPC("SubscribeButton", { buttonName = "OK" })
  EXPECT_HMICALL("Buttons.SubscribeButton", { appID = c.getHMIAppId(), buttonName = "OK" })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.ScrollableMessage( pRequestID, pMethodName, pResetPeriod, pWait )
  local requestParams = {
    scrollableMessageBody = "abc",
    timeout = 5000
  }
  local cid = c.getMobileSession():SendRPC("ScrollableMessage", requestParams)
  EXPECT_HMICALL("UI.ScrollableMessage",
    { messageText = {
      fieldName = "scrollableMessageBody",
      fieldText = requestParams.scrollableMessageBody
    },
    appID = c.getHMIAppId()
  })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function uiResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})

      c.getHMIConnection():SendNotification("UI.OnSystemContext",
      { appID = c.getHMIAppId(), systemContext = "MAIN" })
    end
    RUN_AFTER(uiResponse, pWait)
  end)
  :Do(function(_,data)
    c.getHMIConnection():SendNotification("UI.OnSystemContext",
    { appID = c.getHMIAppId(), systemContext = "HMI_OBSCURED" })
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.scrollableMessageError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "ScrollableMessage" end
  local requestParams = {
    scrollableMessageBody = "abc",
    timeout = 5000
  }
  local cid = c.getMobileSession():SendRPC("ScrollableMessage", requestParams)
  EXPECT_HMICALL("UI.ScrollableMessage",
    { messageText = {
      fieldName = "scrollableMessageBody",
      fieldText = requestParams.scrollableMessageBody
    },
    appID = c.getHMIAppId()
  })
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

function c.SetInteriorVehicleData( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC(commonRC.getAppEventName("SetInteriorVehicleData"), commonRC.getAppRequestParams("SetInteriorVehicleData", "CLIMATE" ))
  EXPECT_HMICALL(commonRC.getHMIEventName("SetInteriorVehicleData"), commonRC.getHMIRequestParams("SetInteriorVehicleData", "CLIMATE"))
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function sendResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams("SetInteriorVehicleData", "CLIMATE"))
    end
    RUN_AFTER(sendResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pResetPeriod)
end

function c.setInteriorVehicleDataError( pRequestID, pResetPeriod, pWait, pMethodName )
  if not pMethodName then pMethodName = "SetInteriorVehicleData" end
  local cid = c.getMobileSession():SendRPC(commonRC.getAppEventName("SetInteriorVehicleData"), commonRC.getAppRequestParams("SetInteriorVehicleData", "CLIMATE"))
  EXPECT_HMICALL(commonRC.getHMIEventName("SetInteriorVehicleData"), commonRC.getHMIRequestParams("SetInteriorVehicleData", "CLIMATE"))
  :Do(function(_, data)
    c.onResetTimeoutNotification(data.id, pMethodName, pResetPeriod)
    local function withoutResponse(_, _)
      -- HMI does not respond
    end
    RUN_AFTER(withoutResponse, pWait)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(pWait)
end

return c
