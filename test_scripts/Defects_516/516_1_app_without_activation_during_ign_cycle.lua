---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/516
-- Precondition:
-- 1. HMI and SDL are started
-- 2. App is registered
-- 3. Perform ignition off
-- 4. Perform ignition on
-- 5. Register app again after ignition on
--
-- Steps:
-- 1. Perform ignition off
-- 2. Perform ignition on
--
-- Expected:
-- SDL saves app with ign_off_count=1 to app_info.data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive"
}

local responseUiParams = {
  menuID = requestParams.menuID,
  menuParams = {
    position = requestParams.position,
    menuName = requestParams.menuName
  }
}

--[[ Local Functions ]]
local function addSubMenu()
  local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParams)

  responseUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.AddSubMenu", responseUiParams)
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.getConfigAppParams().hashID = data.payload.hashID
    end)
end

local function checkAppInfoDat()
  local appInfoDat = commonPreconditions:GetPathToSDL() .. "app_info.dat"
  if utils.isFileExist(appInfoDat) then
    local tbl = utils.jsonFileToTable(appInfoDat)
    if tbl.resumption.resume_app_list[1].appID == common.getConfigAppParams(1).appID and
      tbl.resumption.resume_app_list[1].ign_off_count == 1 then
        utils.cprint(35, "Actual ign_off_count value is saved for app")
    else
      test:FailTestCase("Wrong resumption data is saved for app. AppID is " ..
        tbl.resumption.resume_app_list[1].appID .. ",\n expected ign_off_count value is 1, \n" ..
        "  actual ign_off_count value is " .. tbl.resumption.resume_app_list[1].ign_off_count )
    end
  else
    test:FailTestCase("app_info.dat file was not found")
  end
end

local function registerAppWithResumption()
  common.getMobileSession():StartService(7)
  :Do(function()
      local appParams = common.getConfigAppParams()
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", appParams)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams().appName } })
      :Do(function(_, d1)
          common.setHMIAppId(d1.params.application.appID, 1)
        end)
      common.getHMIConnection():ExpectRequest("UI.AddSubMenu", responseUiParams)
      :Do(function(_,data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
            { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
          :Times(2)
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
        end)

      common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
      :Do(function(_,data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration after ign off", common.registerApp)
runner.Step("Wait resumption timeout", common.wait, { 10000 })
runner.Step("Activate App", common.activateApp)
runner.Step("AddSubMenu", addSubMenu)

runner.Step("2nd Ignition Off", common.ignitionOff)
runner.Step("Check AppInfoDat", checkAppInfoDat)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Data resumption during registration", registerAppWithResumption)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
