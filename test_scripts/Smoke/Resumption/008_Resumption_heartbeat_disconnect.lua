--  Requirement summary:
--  [Data Resumption]: Data resumption on Unexpected Disconnect
--
--  Description:
--  Check that SDL perform resumption after heartbeat disconnect.

--  1. Used precondition
--  In smartDeviceLink.ini file HeartBeatTimeout parameter is:
--  HeartBeatTimeout = 7000.
--  App is registerer and activated on HMI.
--  App has added 1 sub menu, 1 command and 1 choice set.
--
--  2. Performed steps
--  Wait 20 seconds.
--  Register App with hashId.
--
--  Expected behavior:
--  1. SDL sends OnAppUnregistered to HMI.
--  2. App is registered and  SDL resumes all App data, sends BC.ActivateApp to HMI, app gets FULL HMI level.
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonStepsResumption = require('user_modules/shared_testcases/commonStepsResumption')
local mobile_session = require('mobile_session')
local events = require("events")
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams

-- [[Local functions]]
local function connectMobile(self)
  self.mobileConnection:Connect()
  return EXPECT_EVENT(events.connectedEvent, "Connected")
end

local function Start_Session_And_Register_App(self)
  config.defaultProtocolVersion = 3
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartRPC():Do(function()
    local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", default_app_params)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      { application = { appName = default_app_params.appName }}):Do(function(_,data)
      default_app_params.hmi_app_id = data.params.application.appID
    end)
    self.mobileSession:ExpectResponse(correlation_id, { success = true, resultCode = "SUCCESS" })
    self.mobileSession:ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    self.mobileSession:ExpectNotification("OnPermissionsChange", {})
  end)
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", 5000)

function Test:StartSDL_With_One_Activated_App()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        connectMobile(self):Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          Start_Session_And_Register_App(self)
            commonFunctions:userPrint(35, "App is registered")
        end)
      end)
    end)
  end)
end

function Test:ActivateApp()
  commonSmoke.AppActivationForResumption(self,default_app_params.hmi_app_id)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL",audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  commonFunctions:userPrint(35, "App is activated")
end

function Test.HB()
  commonTestCases:DelayedExp(10000)
end

function Test.AddCommand()
  commonStepsResumption:AddCommand()
end

function Test.AddSubMenu()
  commonStepsResumption:AddSubMenu()
end

function Test.AddChoiceSet()
  commonStepsResumption:AddChoiceSet()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Check that SDL perform resumption after heartbeat disconnect")

function Test:Wait_20_sec()
  self.mobileSession:StopHeartbeat()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[default_app_params], unexpectedDisconnect = true })
  :Timeout(20000)
  EXPECT_EVENT(events.disconnectedEvent, "Disconnected")
  :Times(0)
  commonTestCases:DelayedExp(20000)
  :Do(function()
      print("Disconnected!!!")
    end)
  :Times(0)
end

function Test:Register_And_Resume_App_And_Data()
  config.defaultProtocolVersion = 2
  local mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobileSession:StartRPC()
  on_rpc_service_started:Do(function()
    default_app_params.hashID = self.currentHashID
    commonStepsResumption:Expect_Resumption_Data(default_app_params,1) -- remove parameter value 1 after resolving issue with resumtion of AddCommand
    commonStepsResumption:RegisterApp(default_app_params, commonStepsResumption.ExpectResumeAppFULL, true)
  end)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
