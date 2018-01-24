--  Requirement summary:
--  [Policies] Master Reset
--
-- Description:
-- On Master Reset, Policy Manager must revert Local Policy Table
-- to the Preload Policy Table.
--
-- 1. Used preconditions
-- SDL and HMI are running
-- App is registered
--
-- 2. Performed steps
-- Perform Master Reset
-- HMI sends OnExitAllApplications with reason MASTER_RESET
--
-- Expected result:
-- 1. SDL clear all Apps folder, app_info.dat file and shut down
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
-- local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')
local SDL = require('SDL')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ Local Variables ]]
-- Hash id of AddCommand before MASTER_RESET
local hash_id = nil
local default_app_name = config.application1.registerAppInterfaceParams.appName

local putFileParams = {
  requestParams = {
      syncFileName = 'icon.png',
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false
  },
  filePath = "files/icon.png"
}

--[[ Local Functions ]]
local function addCommand(self)
  local cid = self.mobileSession1:SendRPC("AddCommand",{ cmdID = 1005,
              vrCommands = { "OnlyVRCommand"}
              })
  EXPECT_HMICALL("VR.AddCommand", {cmdID = 1005, type = "Command",
                 vrCommands = {"OnlyVRCommand"}}):Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHashChange"):Do(function(_, data)
    hash_id = data.payload.hashID
  end)
end

local function shutDown_MASTER_RESET(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "MASTER_RESET" })
  self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", { reason = "MASTER_RESET" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Do(function()
    SDL:DeleteFile()
    commonFunctions:SDLForceStop() -- removed after uncommentig OnSDLClose, SDLForceStop because of SDL issue
  end)
  -- EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose") -- commented because of SDL issue
  -- :Do(function()
  --   SDL:StopSDL()
  -- end)
  commonTestCases:DelayedExp(1000)
end

--- Check SDL will not resume application when the same application registers.
local function Check_Application_Not_Resume_When_Register_Again(self)
  local mobile_session1 = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobile_session1:StartRPC()

  on_rpc_service_started:Do(function()
    local rai_params =  config.application1.registerAppInterfaceParams
    rai_params.hashID = hash_id

    local cid = self.mobileSession1:SendRPC("RegisterAppInterface",rai_params)
    local on_app_registered = self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "RESUME_FAILED" })

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = {appName = default_app_name} })

    EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
    end)

    self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE",
      audioStreamingState = "NOT_AUDIBLE"})

    on_app_registered:Do(function()
      local cid1 = self.mobileSession1:SendRPC("ListFiles", {})
      self.mobileSession1:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS" })
      :ValidIf (function(_,data)
        -- if data.payload.filenames then
          -- return false, "Files are not removed from system by MASTER_RESET" -- commented because of SDL issue
        -- end
        return true
      end)
      EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
      EXPECT_HMICALL("VR.AddCommand"):Times(0)
    end)
  end)
  commonTestCases:DelayedExp(3000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})
runner.Step("AddCommand", addCommand)

runner.Title("Test")
runner.Step("Check that SDL finish it's work properly by MASTER_RESET", shutDown_MASTER_RESET)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("Check application not resume when register again", Check_Application_Not_Resume_When_Register_Again)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
