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

--[[ Common Variables ]]

local c = {}

c.buttonsName = { climate = "FAN_UP", radio = "VOLUME_UP" }
c.getHMIConnection = actions.getHMIConnection
c.getMobileSession = actions.getMobileSession
c.registerApp = actions.registerApp
c.registerAppWOPTU = actions.registerAppWOPTU
c.getHMIAppId = actions.getHMIAppId
c.jsonFileToTable = utils.jsonFileToTable
c.tableToJsonFile = utils.tableToJsonFile
c.cloneTable = utils.cloneTable


c.allModules = { "RADIO", "CLIMATE", "SEAT", "AUDIO", "LIGHT", "HMI_SETTINGS" }
c.modules = { "RADIO", "CLIMATE" }

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

c.buttons = {
  "OK",
  "PLAY_PAUSE",
  "SEEKLEFT",
  "SEEKRIGHT",
  "TUNEUP",
  "TUNEDOWN",
  "PRESET_0",
  "PRESET_1",
  "PRESET_2",
  "PRESET_3",
  "PRESET_4",
  "PRESET_5",
  "PRESET_6",
  "PRESET_7",
  "PRESET_8",
  "PRESET_9",
  "SEARCH"
}

--[[ Common Functions ]]
function c.getRCAppConfig(tbl)
  if tbl then
    local out = c.cloneTable(tbl.policy_table.app_policies.default)
    out.moduleType = c.allModules
    out.groups = { "Base-4", "RemoteControl", "SendLocation", "DialNumber", "PropriataryData-1" }
    out.AppHMIType = { "REMOTE_CONTROL" }
    return out
  else
    return {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = c.allModules,
      groups = { "Base-4", "RemoteControl", "SendLocation", "DialNumber", "PropriataryData-1" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
  end
end

function actions.getAppDataForPTU(pAppId)
if not pAppId then pAppId = 1 end
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "RemoteControl", "SendLocation", "DialNumber", "PropriataryData-1" },
    AppHMIType = actions.getConfigAppParams(pAppId).appHMIType
  }
end

local function allowSDL()
  c.getHMIConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
end

function c.start(pHMIParams)
  test:runSDL()
  commonFunctions:waitForSDLStart(test)
  :Do(function()
      test:initHMI(test)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          test:initHMI_onReady(pHMIParams)
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              test:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                  allowSDL()
                end)
            end)
        end)
    end)
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
  preloadedTable.policy_table.functional_groupings["RemoteControl"].rpcs.SetInteriorVehicleData = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  preloadedTable.policy_table.functional_groupings["SendLocation"].rpcs.SendLocation = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  preloadedTable.policy_table.functional_groupings["DialNumber"].rpcs.DialNumber = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  preloadedTable.policy_table.functional_groupings["PropriataryData-1"].rpcs.DiagnosticMessage = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  for i = 1, pCountOfRCApps do
    local appId = config["application" .. i].registerAppInterfaceParams.fullAppID
    preloadedTable.policy_table.app_policies[appId] = c.getRCAppConfig(preloadedTable)
    preloadedTable.policy_table.app_policies[appId].AppHMIType = nil
  end
  c.tableToJsonFile(preloadedTable, preloadedFile)
end

function c.preconditions(isPreloadedUpdate, pCountOfRCApps)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  actions.preconditions()
  if isPreloadedUpdate == true then
    backupPreloadedPT()
    updatePreloadedPT(pCountOfRCApps)
  end
end

local function restorePreloadedPT()
  local preloadedFile = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  commonPreconditions:RestoreFile(preloadedFile)
end

function c.postconditions()
  actions.postconditions()
  restorePreloadedPT()
end

function c.getModuleControlData(module_type)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.climateControlData = {
      fanSpeed = 50,
      currentTemperature = {
        unit = "FAHRENHEIT",
        value = 20.1
      },
      desiredTemperature = {
        unit = "CELSIUS",
        value = 10.5
      },
      acEnable = true,
      circulateAirEnable = true,
      autoModeEnable = true,
      defrostZone = "FRONT",
      dualModeEnable = true,
      acMaxEnable = true,
      ventilationMode = "BOTH",
      heatedSteeringWheelEnable = true,
      heatedWindshieldEnable = true,
      heatedRearWindowEnable = true,
      heatedMirrorsEnable = true
    }
  elseif module_type == "RADIO" then
    out.radioControlData = {
      frequencyInteger = 1,
      frequencyFraction = 2,
      band = "AM",
      rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 1,
        TP = false,
        TA = true,
        REG = "US"
      },
      availableHDs = 1,
      hdChannel = 1,
      signalStrength = 5,
      signalChangeThreshold = 10,
      radioEnable = true,
      state = "ACQUIRING",
      hdRadioEnable = true,
      sisData = {
        stationShortName = "Name1",
        stationIDNumber = {
          countryCode = 100,
          fccFacilityId = 100
        },
        stationLongName = "RadioStationLongName",
        stationLocation = {
          longitudeDegrees = 0.1,
          latitudeDegrees = 0.1,
          altitude = 0.1
        },
        stationMessage = "station message"
      }
    }
  elseif module_type == "SEAT" then
    out.seatControlData = {
      id = "DRIVER",
      heatingEnabled = true,
      coolingEnabled = true,
      heatingLevel = 50,
      coolingLevel = 50,
      horizontalPosition = 50,
      verticalPosition = 50,
      frontVerticalPosition = 50,
      backVerticalPosition = 50,
      backTiltAngle = 50,
      headSupportHorizontalPosition = 50,
      headSupportVerticalPosition = 50,
      massageEnabled = true,
      massageMode = {
        {
          massageZone = "LUMBAR",
          massageMode = "HIGH"
        },
        {
          massageZone = "SEAT_CUSHION",
          massageMode = "LOW"
        }
      },
      massageCushionFirmness = {
        {
          cushion = "TOP_LUMBAR",
          firmness = 30
        },
        {
          cushion = "BACK_BOLSTERS",
          firmness = 60
        }
      },
      memory = {
        id = 1,
        label = "Label value",
        action = "SAVE"
      }
    }
  elseif module_type == "AUDIO" then
    out.audioControlData = {
      source = "AM",
      keepContext = false,
      volume = 50,
      equalizerSettings = {
        {
          channelId = 10,
          channelName = "Channel 1",
          channelSetting = 50
        }
      }
    }
  elseif module_type == "LIGHT" then
    out.lightControlData = {
      lightState = {
        {
          id = "FRONT_LEFT_HIGH_BEAM",
          status = "ON",
          density = 0.2,
          color = {
            red = 50,
            green = 150,
            blue = 200
          }
        }
      }
    }
  elseif module_type == "HMI_SETTINGS" then
    out.hmiSettingsControlData = {
      displayMode = "DAY",
      temperatureUnit = "CELSIUS",
      distanceUnit = "KILOMETERS"
    }
  end
  return out
end

function c.getButtonNameByModule(pModuleType)
  return c.buttonsName[string.lower(pModuleType)]
end

function c.getModuleParams(pModuleData)
  if pModuleData.moduleType == "CLIMATE" then
    if not pModuleData.climateControlData then
      pModuleData.climateControlData = { }
    end
    return pModuleData.climateControlData
  elseif pModuleData.moduleType == "RADIO" then
    if not pModuleData.radioControlData then
      pModuleData.radioControlData = { }
    end
    return pModuleData.radioControlData
  elseif pModuleData.moduleType == "AUDIO" then
    if not pModuleData.audioControlData then
      pModuleData.audioControlData = { }
    end
    return pModuleData.audioControlData
  elseif pModuleData.moduleType == "SEAT" then
    if not pModuleData.seatControlData then
      pModuleData.seatControlData = { }
    end
    return pModuleData.seatControlData
  end
end

function c.getReadOnlyParamsByModule(pModuleType)
  local out = { moduleType = pModuleType }
  if pModuleType == "CLIMATE" then
    out.climateControlData = {
      currentTemperature = {
        unit = "FAHRENHEIT",
        value = 32.6
      }
    }
  elseif pModuleType == "RADIO" then
    out.radioControlData = {
      rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 2,
        TP = false,
        TA = true,
        REG = "US"
      },
      availableHDs = 2,
      signalStrength = 4,
      signalChangeThreshold = 22,
      state = "MULTICAST",
      sisData = {
        stationShortName = "Name2",
        stationIDNumber = {
          countryCode = 200,
          fccFacilityId = 200
        },
        stationLongName = "RadioStationLongName2",
        stationLocation = {
          longitudeDegrees = 20.1,
          latitudeDegrees = 20.1,
          altitude = 20.1
        },
        stationMessage = "station message 2"
      }
    }
  elseif pModuleType == "AUDIO" then
    out.audioControlData = {
      equalizerSettings = { { channelName = "Channel 1" } }
    }
  end
  return out
end

function c.getSettableModuleControlData(pModuleType)
  local out = c.getModuleControlData(pModuleType)
  local params_read_only = c.getModuleParams(c.getReadOnlyParamsByModule(pModuleType))
  if params_read_only then
    for p_read_only, p_read_only_value in pairs(params_read_only) do
      if pModuleType == "AUDIO" then
        for sub_read_only_key, sub_read_only_value in pairs(p_read_only_value) do
          for sub_read_only_name in pairs(sub_read_only_value) do
            c.getModuleParams(out)[p_read_only][sub_read_only_key][sub_read_only_name] = nil
          end
        end
      else
        c.getModuleParams(out)[p_read_only] = nil
      end
    end
  end
  return out
end

-- RC RPCs structure
local rcRPCs = {
  SetInteriorVehicleData = {
    appEventName = "SetInteriorVehicleData",
    hmiEventName = "RC.SetInteriorVehicleData",
    requestParams = function(pModuleType)
      return {
        moduleData = c.getSettableModuleControlData(pModuleType)
      }
    end,
    hmiRequestParams = function(pModuleType, pAppId)
      return {
        appID = c.getHMIAppId(pAppId),
        moduleData = c.getSettableModuleControlData(pModuleType)
      }
    end,
    hmiResponseParams = function(pModuleType)
      return {
        moduleData = c.getSettableModuleControlData(pModuleType)
      }
    end,
    responseParams = function(success, resultCode, pModuleType)
      return {
        success = success,
        resultCode = resultCode,
        moduleData = c.getSettableModuleControlData(pModuleType)
      }
    end
  },
  ButtonPress = {
    appEventName = "ButtonPress",
    hmiEventName = "Buttons.ButtonPress",
    requestParams = function(pModuleType)
      return {
        moduleType = pModuleType,
        buttonName = c.getButtonNameByModule(pModuleType),
        buttonPressMode = "SHORT"
      }
    end,
    hmiRequestParams = function(pModuleType, pAppId)
      return {
        appID = c.getHMIAppId(pAppId),
        moduleType = pModuleType,
        buttonName = c.getButtonNameByModule(pModuleType),
        buttonPressMode = "SHORT"
      }
    end,
    hmiResponseParams = function()
      return {}
    end,
    responseParams = function(success, resultCode)
      return {
        success = success,
        resultCode = resultCode
      }
    end
  },
  GetInteriorVehicleDataConsent = {
    hmiEventName = "RC.GetInteriorVehicleDataConsent",
    hmiRequestParams = function(pModuleType, pAppId)
      return {
        appID = c.getHMIAppId(pAppId),
        moduleType = pModuleType
      }
    end,
    hmiResponseParams = function(pAllowed)
      return {
        allowed = pAllowed
      }
    end,
  },
  OnRemoteControlSettings = {
    hmiEventName = "RC.OnRemoteControlSettings",
    hmiResponseParams = function(pAllowed, pAccessMode)
      return {
        allowed = pAllowed,
        accessMode = pAccessMode
      }
    end
  }
}

function c.getAppEventName(pRPC)
  return rcRPCs[pRPC].appEventName
end

function c.getHMIEventName(pRPC)
  return rcRPCs[pRPC].hmiEventName
end

function c.getAppRequestParams(pRPC, ...)
  return rcRPCs[pRPC].requestParams(...)
end

function c.getAppResponseParams(pRPC, ...)
  return rcRPCs[pRPC].responseParams(...)
end

function c.getHMIRequestParams(pRPC, ...)
  return rcRPCs[pRPC].hmiRequestParams(...)
end

function c.getHMIResponseParams(pRPC, ...)
  return rcRPCs[pRPC].hmiResponseParams(...)
end

function c.askDriver(pAllowed, pAccessMode)
  local rpc = "OnRemoteControlSettings"
  c.getHMIConnection():SendNotification(c.getHMIEventName(rpc), c.getHMIResponseParams(rpc, pAllowed, pAccessMode))
end

function c.rpcAllowedWithConsent(pModuleType, pAppId, pRPC, pRequestID, pMethodName, pResetPeriod, pWait)
  if not pAppId then pAppId = 1 end
  local cid = c.getMobileSession(pAppId):SendRPC(c.getAppEventName(pRPC), c.getAppRequestParams(pRPC, pModuleType))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(c.getHMIEventName(consentRPC), c.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", c.getHMIResponseParams(consentRPC, true))
      EXPECT_HMICALL(c.getHMIEventName(pRPC), c.getHMIRequestParams(pRPC, pModuleType, pAppId))
      :Do(function(_, data2)
          c.getHMIConnection():SendResponse(data2.id, data2.method, "SUCCESS", c.getHMIResponseParams(pRPC, pModuleType))
        end)
    end)
  c.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.rpcAllowedWithConsentError(pModuleType, pAppId, pRPC, pRequestID, pMethodName, pResetPeriod, pWait)
  if not pAppId then pAppId = 1 end
  local cid = c.getMobileSession(pAppId):SendRPC(c.getAppEventName(pRPC), c.getAppRequestParams(pRPC, pModuleType))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(c.getHMIEventName(consentRPC), c.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
    end)
  c.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.backupHMICapabilities()
  local hmiCapabilitiesFile = commonFunctions:read_parameter_from_smart_device_link_ini("HMICapabilities")
  commonPreconditions:BackupFile(hmiCapabilitiesFile)
end

local function audibleState(pAppId)
  if not pAppId then pAppId = 1 end
  local appParams = config["application" .. pAppId].registerAppInterfaceParams
  local audibleStateValue
  if appParams.isMediaApplication == true then
    audibleStateValue = "AUDIBLE"
  else
    audibleStateValue = "NOT_AUDIBLE"
  end
  return audibleStateValue
end

function c.activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = c.getHMIAppId(pAppId)
  local mobSession = c.getMobileSession(pAppId)
  local requestId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = audibleState(pAppId),
      systemContext = "MAIN" })
  utils.wait()
end

function c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
  if not pRequestID then pRequestID = c.getHMIAppId() end
  if not pResetPeriod then pResetPeriod = 3000 end
  c.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout",
    { requestID = pRequestID,
    methodName = pMethodName,
    resetPeriod = pResetPeriod
  })
end

function c.sendLocation( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("SendLocation", sendLocationRequestParams)
  EXPECT_HMICALL("Navigation.SendLocation", { appID = c.getHMIAppId() })
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.sendLocationError( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("SendLocation", sendLocationRequestParams)
  EXPECT_HMICALL("Navigation.SendLocation", { appID = c.getHMIAppId() })
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.alert( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
    c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function c.alertError( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
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

function c.performInteraction( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  c.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    initialPrompt = params.initialPrompt
  })
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  c.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

function c.performInteractionError( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
    c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  c.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    initialPrompt = params.initialPrompt
  })
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.dialNumber( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("DialNumber", { number = "#3804567654*" })

  EXPECT_HMICALL("BasicCommunication.DialNumber", { appID = c.getHMIAppId() })
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.dialNumberError( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("DialNumber", { number = "#3804567654*" })
  EXPECT_HMICALL("BasicCommunication.DialNumber", { appID = c.getHMIAppId() })
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)

  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.slider( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("Slider",
    {
      numTicks = 7,
      position = 1,
      sliderHeader ="sliderHeader",
      timeout = 1000,
      sliderFooter = { "sliderFooter" }
    })
  EXPECT_HMICALL("UI.Slider", { appID = c.getHMIAppId() })
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_,data)
      c.getHMIConnection():SendNotification("UI.OnSystemContext",
        { appID = c.getHMIAppId(), systemContext = "HMI_OBSCURED" })
      local function sendReponse()
        c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})
        c.getHMIConnection():SendNotification("UI.OnSystemContext",
          { appID = c.getHMIAppId(), systemContext = "MAIN" })
      end
      RUN_AFTER(sendReponse, 1000)
    end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })
end

function c.sliderError( pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC("Slider",
    {
      numTicks = 7,
      position = 1,
      sliderHeader ="sliderHeader",
      timeout = 1000,
      sliderFooter = { "sliderFooter" }
    })
  EXPECT_HMICALL("UI.Slider", { appID = c.getHMIAppId() })
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.speak( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
      c.getHMIConnection():SendNotification("TTS.Started")
      local function sendSpeakResponse()
        c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        c.getHMIConnection():SendNotification("TTS.Stopped")
      end
      local function sendOnResetTimeout()
        c.getHMIConnection():SendNotification("TTS.OnResetTimeout",
          { appID = c.getHMIAppId(), methodName = "TTS.Speak" })
      end
      RUN_AFTER(sendOnResetTimeout, 9000)
      RUN_AFTER(sendSpeakResponse, 18000)
    end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(20000)
end

function c.speakError( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.diagnosticMessage( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_,data)
    c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {messageDataResult = {12}})
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.diagnosticMessageError( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.subscribeButton( pButtonName, pRequestID, pMethodName, pResetPeriod, pWait)
  local cid = c.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButtonName })
  EXPECT_HMICALL("Buttons.SubscribeButton", { appID = c.getHMIAppId(), buttonName = pButtonName })
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
    c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.subscribeButtonError( pButtonName, pRequestID, pMethodName, pResetPeriod, pWait)
  local cid = c.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButtonName })
  EXPECT_HMICALL("Buttons.SubscribeButton", { appID = c.getHMIAppId(), buttonName = pButtonName })
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.scrollableMessage( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_,data)
    c.getHMIConnection():SendNotification("UI.OnSystemContext",
    { appID = c.getHMIAppId(), systemContext = "HMI_OBSCURED" })
    local function uiResponse()
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})

      c.getHMIConnection():SendNotification("UI.OnSystemContext",
      { appID = c.getHMIAppId(), systemContext = "MAIN" })
    end
    RUN_AFTER(uiResponse, 1000)
  end)
  c.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.scrollableMessageError( pRequestID, pMethodName, pResetPeriod, pWait )
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
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function c.rpcAllowed( pModuleType, pAppId, pRPC, pRequestID, pMethodName, pResetPeriod, pWait )
  if not pAppId then pAppId = 1 end
  local mobSession = c.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(c.getAppEventName(pRPC), c.getAppRequestParams(pRPC, pModuleType ))
  EXPECT_HMICALL(c.getHMIEventName(pRPC), c.getHMIRequestParams(pRPC, pModuleType, pAppId))
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, data)
      c.getHMIConnection(pAppId):SendResponse(data.id, data.method, "SUCCESS", c.getHMIResponseParams(pRPC, pModuleType))
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.setVehicleData( pModuleType, pRPC, pRequestID, pMethodName, pResetPeriod, pWait )
  local cid = c.getMobileSession():SendRPC(c.getAppEventName(pRPC), c.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(c.getHMIEventName(pRPC), c.getHMIRequestParams(pRPC, pModuleType))
  :Do(function()
    c.hmiNotification(pRequestID, pMethodName, pResetPeriod)
    RUN_AFTER(c.hmiNotification, pWait)
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  c.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

return c
