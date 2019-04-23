---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/489
-- Precondition:
-- Phone is connected
-- SPT registered on SYNC (Language EN-US, HMI Language EN-US)
-- DataConsent and Permissions are accepted
--
-- Steps:
-- Select SyncProxyTester (HMI Full)
-- Settings -> General -> Change SYNC Language to Spanish
-- Apps -> Select SyncProxyTester
--
-- Problem:
-- Not able to start SyncProxyTester
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local LanguageChangeUnregisterTimeout

--[[ Local Functions ]]
local function changeLanguage(pLanguage, pUnregisteMessageNumber, onLanguageChangeExpect)
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemInfoChanged", { language = pLanguage })
  common.getHMIConnection():SendNotification("UI.OnLanguageChange", { language = pLanguage })

  local function vrOnLanguageChange()
    common.getHMIConnection():SendNotification("VR.OnLanguageChange", { language = pLanguage })
  end

  local function ttsOnLanguageChange()
    common.getHMIConnection():SendNotification("TTS.OnLanguageChange", { language = pLanguage })
  end

  RUN_AFTER(vrOnLanguageChange, 1000)
  RUN_AFTER(ttsOnLanguageChange, 3000)

  onLanguageChangeExpect()

  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "LANGUAGE_CHANGE" })
  :Times(pUnregisteMessageNumber)

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = false })
  :Times(pUnregisteMessageNumber)
end

local function registerAppWrongLanguage(pAppId)
  if not pAppId then pAppId = 1 end
  local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
    { application = { appName = common.getConfigAppParams(pAppId).appName } })
  :Do(function(_, d1)
      common.setHMIAppId(d1.params.application.appID, pAppId)
    end)
  common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "WRONG_LANGUAGE" })
  :Do(function()
      common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      common.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
end

local function deactivateApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId(), reason = "GENERAL" })

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function updateIniFile()
  LanguageChangeUnregisterTimeout = commonFunctions:read_parameter_from_smart_device_link_ini("LanguageChangeUnregisterTimeout")
  commonFunctions:write_parameter_to_smart_device_link_ini("LanguageChangeUnregisterTimeout", 3000)
end

local function restoreValuestIniFile()
  commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout",
    LanguageChangeUnregisterTimeout)
end

local function onLanguageChangeExpectation(pLanguage)
  common.getMobileSession():ExpectNotification("OnLanguageChange",
    { language = "EN-US", hmiDisplayLanguage = pLanguage },
    { language = pLanguage, hmiDisplayLanguage = pLanguage },
    { language = pLanguage, hmiDisplayLanguage = pLanguage })
  :Times(3)
end

local function onLanguageChangeExpectationRestore(pLanguage)
  common.getMobileSession():ExpectNotification("OnLanguageChange",
    { language = "DE-DE", hmiDisplayLanguage = pLanguage },
    { language = pLanguage, hmiDisplayLanguage = pLanguage },
    { language = pLanguage, hmiDisplayLanguage = pLanguage })
  :Times(3)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update ini file LanguageChangeUnregisterTimeout=3000", updateIniFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Deactivation app", deactivateApp)

runner.Title("Test")
runner.Step("Change Language with unregistration", changeLanguage, { "DE-DE", 1, onLanguageChangeExpectation })
runner.Step("App registration with WRONG_LANGUAGE", registerAppWrongLanguage)
runner.Step("Activate App after language change", common.activateApp)
runner.Step("Deactivation app", deactivateApp)
runner.Step("Restore language", changeLanguage, { "EN-US", 0, onLanguageChangeExpectationRestore })
runner.Step("Activate App after language restore", common.activateApp)

runner.Title("Postconditions")
runner.Step("Restore values in ini file", restoreValuestIniFile)
runner.Step("Stop SDL", common.postconditions)
