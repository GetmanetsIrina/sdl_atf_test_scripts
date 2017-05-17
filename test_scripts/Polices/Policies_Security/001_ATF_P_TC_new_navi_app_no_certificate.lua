---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-27426]: [PTU] [F-S] SDL must start PTU for navi app right after app successfully registration
-- [APPLINK-18966]: [PolicyTableUpdate] PoliciesManager must initiate PTU in case getting 'device consent' from the user
--
-- Description:
-- In case navigation app connects and sucessfully registers on SDL (opens RPC 7 service)
-- and PolicyTable has NO "certificate" at "module_config" section of LocalPolicyTable
-- SDL must start PolicyTableUpdate process on sending SDL.OnStatusUpdate(UPDATE_NEEDED) to HMI to get "certificate"
--
-- 1. Used preconditions:
-- Navi app doesn't exist in LP, device is not consented, no certificate in module_config
--
-- 2. Performed steps
-- Register navi application.
--
-- Expected result:
-- Application is registered successfully
-- Clarification APPLINK-34459.................................
-- SDL should trigger PTU: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases_genivi/commonFunctions')
local commonSteps = require('user_modules/shared_testcases_genivi/commonSteps')
local commonTestCases = require('user_modules/shared_testcases_genivi/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases_genivi/commonPreconditions')
local testCasesForPolicyTable = require('user_modules/shared_testcases_genivi/testCasesForPolicyTable')
local mobile_session = require('mobile_session')

--[[ General Precondition before ATF start ]]
commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("ForceProtectedService", "Non")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

--[[ General Settings for configuration ]]
Test = require('user_modules/shared_testcases_genivi/connecttest_resumption')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_RAI()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
  EXPECT_RESPONSE(CorIdRegister, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}):Times(0)
  commonTestCases:DelayedExp(10000)
end

function Test:trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_files()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function Test:Postcondition_Stop()
  StopSDL(self)
end

return Test
