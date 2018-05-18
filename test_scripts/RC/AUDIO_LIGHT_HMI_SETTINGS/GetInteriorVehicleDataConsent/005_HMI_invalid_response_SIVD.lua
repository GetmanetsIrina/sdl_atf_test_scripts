---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Exception 2.1
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #5; TRS: GetInteriorVehicleDataConsent, #3
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with "ASK_DRIVER" access mode
-- 2) and RC application (in HMILevel FULL) requested access to remote control module
-- that is already allocated to another RC application
-- 3) and SDL requested user consent from HMI via GetInteriorVehicleDataConsent
-- 4) and HMI did not respond during default timeout or response is invalid or erroneous
-- SDL must:
-- 1) respond on control request to RC application with result code GENERIC_ERROR, success:false
-- 2) not allocate access for remote control module to the requested application
-- (meaning SDL must leave control of remote control module without changes)
-- Note: SDL must initiate user prompt in case of consequent control request for the same module from this application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
--modules array does not contain "RADIO" because "RADIO" module has read only parameters
local modules = { "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS" }

--[[ Local Functions ]]
local function PTUfunc(tbl)
  common.AddOnRCStatusToPT(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = common.getRCAppConfig()
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = common.getRCAppConfig()
end

local function rpcInvalidHMIResponse(pModuleType, pAppId, pRPC)
  local consentRPC = "GetInteriorVehicleDataConsent"
  local mobSession = common.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(common.getAppEventName(pRPC), common.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(common.getHMIEventName(consentRPC), common.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      common.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
          allowed = "aaa" -- invalid type of parameter
        })
      EXPECT_HMICALL(common.getHMIEventName(pRPC)):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI1, PTU", common.raiPTUn, { PTUfunc })
runner.Step("Activate App1", common.activateApp)
runner.Step("RAI2", common.raiN, { 2 })
runner.Step("Activate App2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  -- set control for App1
  runner.Step("App1 SetInteriorVehicleData", common.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  -- set control for App2 --> Ask driver --> HMI: response with invalid data
  runner.Step("App2 SetInteriorVehicleData 1st GENERIC_ERROR", rpcInvalidHMIResponse,
    { mod, 2, "SetInteriorVehicleData" })
  runner.Step("App2 SetInteriorVehicleData 2nd SUCCESS", common.rpcAllowedWithConsent,
    { mod, 2, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
