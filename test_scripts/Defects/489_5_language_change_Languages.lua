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
local Languages = {
  "ES-MX",
  "FR-CA",
  "DE-DE",
  "ES-ES",
  "EN-GB",
  "RU-RU",
  "TR-TR",
  "PL-PL",
  "FR-FR",
  "IT-IT",
  "SV-SE",
  "PT-PT",
  "NL-NL",
  "EN-AU",
  "ZH-CN",
  "ZH-TW",
  "JA-JP",
  "AR-SA",
  "KO-KR",
  "PT-BR",
  "CS-CZ",
  "DA-DK",
  "NO-NO",
  "NL-BE",
  "EL-GR",
  "HU-HU",
  "FI-FI",
  "SK-SK"
}

local initialLanguage = "EN-US"

--[[ Local Functions ]]
local function changeLanguage(pLanguageKey, pUnregisteMessageNumber)
  local previousLanguage
  if Languages[pLanguageKey] ~= 1 then
    previousLanguage = Languages[pLanguageKey - 1]
  else
    previousLanguage = initialLanguage
  end
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemInfoChanged",
    { language = Languages[pLanguageKey] })
  common.getHMIConnection():SendNotification("VR.OnLanguageChange", { language = Languages[pLanguageKey] })
  common.getHMIConnection():SendNotification("TTS.OnLanguageChange", { language = Languages[pLanguageKey] })
  common.getHMIConnection():SendNotification("UI.OnLanguageChange", { language = Languages[pLanguageKey] })

  common.getMobileSession():ExpectNotification("OnLanguageChange",
    { language = Languages[pLanguageKey], hmiDisplayLanguage = previousLanguage },
    { language = Languages[pLanguageKey], hmiDisplayLanguage = previousLanguage },
    { language = Languages[pLanguageKey], hmiDisplayLanguage = Languages[pLanguageKey] })
  :Times(3)

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
for key, language in pairs(Languages) do
  runner.Step("Change Language with unregistration " .. language, changeLanguage, { key, 1 })
  runner.Step("App registration with WRONG_LANGUAGE " ..language, registerAppWrongLanguage)
  runner.Step("Activate App after language change " .. language, common.activateApp)
  runner.Step("Deactivation app " .. language, deactivateApp)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
