---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/499
--
-- Description: App HMI status is not changing to none when exiting via VR
--
-- Steps:
-- 1) SyncProxyTester app running in HMI Full on the phone and SYNC
-- 2) Press the voice command and say Exit <SyncProxyTester)>
--
-- Expected result:
-- 1) OnHMIStatus notification for the SyncProxyTester app should be HMI Level=None and Not_Audible
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local ApplicationResumingTimeout

--[[ Local Functions ]]
local function sendOnExitApplication()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
    {reason = "USER_EXIT", appID = common.getHMIAppId() })

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  :Times(0)

  common.getHMIConnection():ExpectNotification("BasicCommunication.ActivateApp")
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
  end)

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })

  common.wait(5000)
end

local function updateIniFile()
  ApplicationResumingTimeout = commonFunctions:read_parameter_from_smart_device_link_ini("ApplicationResumingTimeout")
  commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout", 5000)
end

local function restoreValuestIniFile()
  commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout", ApplicationResumingTimeout)
end

local function updateDefaultHMILevelToBackground(tbl)
  tbl.policy_table.app_policies.default.default_hmi = "BACKGROUND"
end

function common.registerAppWOPTU(pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
          common.setHMIAppId(d1.params.application.appID, pAppId)
        end)
      common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
            { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          common.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { updateDefaultHMILevelToBackground })
runner.Step("Update ini file ApplicationResumingTimeout=5000", updateIniFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Close session", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App registration after disconnect", common.registerAppWOPTU)

runner.Title("Test")
runner.Step("USER_EXIT from HMI", sendOnExitApplication)
runner.Step("Activation after exit", common.activateApp)

runner.Title("Postconditions")
runner.Step("Restore values in ini file", restoreValuestIniFile)
runner.Step("Stop SDL", common.postconditions)
