---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local vehicleTypeInfoParams = {
  make = common.vehicleTypeInfoParams.custom.make,
  model = common.vehicleTypeInfoParams.custom.model,
  modelYear = common.vehicleTypeInfoParams.custom.modelYear,
  trim = common.vehicleTypeInfoParams.custom.trim,
  ccpu_version = common.vehicleTypeInfoParams.default.ccpu_version,
  systemHardwareVersion = common.vehicleTypeInfoParams.default.systemHardwareVersion
}

local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function getRpcServiceAckParams(pVehicleTypeInfoParams)
  local ackParams = {
    make = common.setStringBsonValue(pVehicleTypeInfoParams.make),
    model = common.setStringBsonValue(pVehicleTypeInfoParams.model),
    modelYear = common.setStringBsonValue(pVehicleTypeInfoParams.modelYear),
    trim = common.setStringBsonValue(pVehicleTypeInfoParams.trim),
    systemSoftwareVersion = common.setStringBsonValue(pVehicleTypeInfoParams.ccpu_version),
    systemHardwareVersion = common.setStringBsonValue(pVehicleTypeInfoParams.systemHardwareVersion)
  }
  for key, KeyValue in pairs(ackParams) do
    if not KeyValue.value then
      ackParams[key] = nil
    end
  end
  return ackParams
end

local function startErrorResponseGetSystemInfo()
  local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)
  hmiCap.BasicCommunication.GetSystemInfo = nil
  common.startWithCustomCap(hmiCap)
  common.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemInfo")
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.startWithCustomCap, { defaultHmiCap })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI sends GetSystemInfo(GENERIC_ERROR) response", startErrorResponseGetSystemInfo )
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { getRpcServiceAckParams(vehicleTypeInfoParams) })
common.Step("Vehicle type data in RAI", common.registerAppEx, { vehicleTypeInfoParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

