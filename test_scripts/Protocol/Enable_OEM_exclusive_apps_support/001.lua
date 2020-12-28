---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmicap = common.getCapWithMandatoryExpVehicleTypeAndInfo()
local getVehicleTypeParams = hmicap.VehicleInfo.GetVehicleType.params.vehicleType
getVehicleTypeParams.make = "Ford"
getVehicleTypeParams.model = "Focus"
getVehicleTypeParams.modelYear = 2015
getVehicleTypeParams.trim = "SEL"

local getSystemInfoParams = hmicap.BasicCommunication.GetSystemInfo.params
getSystemInfoParams.ccpu_version = "12345_TV"
getSystemInfoParams.systemHardwareVersion = "V4567_GJK"

local rpcServiceParams = {
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "5.3.0" }
  },
  ackParams = {
    make = { type = common.bsonType.STRING, value = getVehicleTypeParams.make },
    model = { type = common.bsonType.STRING, value = getVehicleTypeParams.model },
    ["model year"] = { type = common.bsonType.STRING, value = getVehicleTypeParams.modelYear },
    trim = { type = common.bsonType.STRING, value = getVehicleTypeParams.trim },
    systemSoftwareVersion = { type = common.bsonType.STRING, value = getSystemInfoParams.systemSoftwareVersion },
    systemHardwareVersion = { type = common.bsonType.STRING, value = getSystemInfoParams.systemHardwareVersion }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustCap, { hmicap })

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startServiceUnprotectedACK,
  { 1, common.serviceType.RPC, rpcServiceParams.reqParams, rpcServiceParams.ackParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
