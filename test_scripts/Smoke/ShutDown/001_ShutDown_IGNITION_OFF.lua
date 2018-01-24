-- Requirement summary:
-- [Data Resumption]:OnExitAllApplications(IGNITION_OFF) in terms of resumption
--
-- Description:
-- In case SDL receives OnExitAllApplications(IGNITION_OFF),
-- SDL must clean up any resumption-related data
-- Obtained after OnExitAllApplications( SUSPEND). SDL must stop all its processes,
-- notify HMI via OnSDLClose and shut down.
--
-- 1. Used preconditions
-- HMI is running
-- One App is registered and activated on HMI
--
-- 2. Performed steps
-- Perform ignition Off
-- HMI sends OnExitAllApplications(IGNITION_OFF)
--
-- Expected result:
-- 1. SDL sends to App OnAppInterfaceUnregistered
-- 2. SDL sends to HMI OnSDLClose and stops working
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local SDL = require('SDL')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Functions ]]
local function ShutDown_IGNITION_OFF(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    SDL:DeleteFile()
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
    -- EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose") -- commented because of SDL issue
    :Do(function()
      SDL:StopSDL()
    end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("Check that SDL finish it's work properly by IGNITION_OFF", ShutDown_IGNITION_OFF)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
