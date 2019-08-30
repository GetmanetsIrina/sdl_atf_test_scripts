---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [GetVehicleData] As a mobile app wants to send a request to get the details of the vehicle data
--
-- Description:
-- In case:
-- mobile application sends valid GetVehicleData to SDL and this request is allowed by Policies
-- SDL must:
-- 1) Transfer this request to HMI
-- 2) After successful response from hmi
--    respond SUCCESS, success:true and parameter value received from HMI to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc = {
  name = "GetVehicleData",
  params = {
    engineOilLife = true,
    fuelRange = true,
    tirePressure = true,
    electronicParkBrakeStatus = true,
    turnSignal = true
  }
}

local vehicleDataValues = {
  engineOilLife = 50.30,
  fuelRange = {
    {
      type = "GASOLINE",
      range = 400.00
    }
  },
  tirePressure = {
    leftFront = {
      status = "NORMAL",
      tpms = "SYSTEM_ACTIVE",
      pressure = 35.00
    },
    rightFront = {
      status = "NORMAL",
      tpms = "SYSTEM_ACTIVE",
      pressure = 35.00
    }
  },
  electronicParkBrakeStatus = "CLOSED",
  turnSignal = "LEFT"
}

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", vehicleDataValues )
    end)
  local responseParams = vehicleDataValues
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name, processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
