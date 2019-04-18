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

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Interfaces = {
  "UI",
  "VR",
  "TTS"
}

--[[ Local Functions ]]
local function changeLanguage(pLanguage, pUnregisteMessageNumber, pInterface)
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemInfoChanged", { language = pLanguage })
  common.getHMIConnection():SendNotification(pInterface ..".OnLanguageChange", { language = pLanguage })

  if pInterface == "UI" then
  common.getMobileSession():ExpectNotification("OnLanguageChange",
    { language = "EN-US", hmiDisplayLanguage = pLanguage })
  else
    common.getMobileSession():ExpectNotification("OnLanguageChange",
    { language = pLanguage, hmiDisplayLanguage = "EN-US" })
  end

  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered",{ reason="LANGUAGE_CHANGE" })
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

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Deactivation app", deactivateApp)

runner.Title("Test")
for _, interface in pairs(Interfaces) do
  runner.Step("Change Language with unregistration " .. interface, changeLanguage, { "DE-DE", 1, interface })
  runner.Step("App registration with WRONG_LANGUAGE " .. interface, registerAppWrongLanguage)
  runner.Step("Activate App after language change " .. interface, common.activateApp)
  runner.Step("Deactivation app " .. interface, deactivateApp)
  runner.Step("Restore language " .. interface, changeLanguage, { "EN-US", 0, interface })
  runner.Step("Activate App after language restore " .. interface, common.activateApp)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
