---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL sends response `GENERIC_ERROR` to mobile app if HMI sends response with invalid `windowStatus` structure:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
--
-- In case:
-- 1) App sends GetVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- 2) SDL transfers this request to HMI.
-- 3) HMI sends the invalid `windowStatus` structure in GetVehicleData response:
--    - invalid parameter name
--    - invalid parameter type
--    - missing mandatory parameter
--    - params out of bounds
--    - empty value
-- SDL does:
--  a) respond GENERIC_ERROR to mobile when default timeout is expired.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local invalidValue = {
  emptyValue = "",
  invalidType = true,
  greaterMax = 101
}

local invalidParam = {
  ["empty_location"] = {
    { location = {}, -- empty location parameter
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["invalidType_location"] = {
    { location = "string", -- invalid type for location parameter
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["missing_location"] = { -- without location parameter
    { state = common.getWindowStatusParams()[1].state }
  },
  ["invalidName_location"] ={ -- invalid name for location parameter
    { loCaTion = { col = 49, row = 49 },
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["invalidName_col"] = { -- invalid name for col parameter from Grid structure
    { location = { CoL = 49, row = 49 },
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["invalidName_row"] = { -- invalid name for row parameter from Grid structure
    { location = { col = 49, RoW = 49 },
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["empty_state"] = { -- empty state parameter
    { location = common.getWindowStatusParams()[1].location,
      state = {}
    }
  },
  ["invalidType_state"] = { -- invalid type for state parameter
    { location = common.getWindowStatusParams()[1].location,
      state = "string"
    }
  },
  ["missing_state"] = { -- without state parameter
    { location = common.getWindowStatusParams()[1].location }
  },
  ["invalidName_state"] = { -- invalid name for state parameter
    { location = common.getWindowStatusParams()[1].location,
      StaTe = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidName_approximatePosition"] = { -- invalid name for approximatePosition parameter from WindowState structure
    { location = common.getWindowStatusParams()[1].location,
      state = { ApproximatePositioN = 50, deviation = 50 }
    }
  },
  ["invalidName_deviation"] = { -- invalid name for deviation parameter from WindowState structure
    { location = common.getWindowStatusParams()[1].location,
      state = { approximatePosition = 50, DeviatioN = 50 }
    }
  },
  ["missing_col"] = { -- without col parameter from Grid structure
    { location = { row = 49, level = 49, colspan = 49, rowspan = 49, levelspan = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["missing_row"] = { -- without row parameter from Grid structure
    { location = { col = 49, level = 49, colspan = 49, rowspan = 49, levelspan = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  }
}

local resultCode = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for p in pairs(common.getWindowStatusParams()[1].location) do
  common.Title("Check " .. p .. " parameter from Grid structure")
  for k, v in pairs(invalidValue) do
    common.Step("HMI sends GetVehicleData response with invalid " .. p .. "=" .. tostring(k),
      common.getVehicleData, { common.getCustomData(p, "location", v), resultCode })
  end
end

for p in pairs(common.getWindowStatusParams()[1].state) do
  common.Title("Check " .. p .. " parameter from WindowState structure")
  for k, v in pairs(invalidValue) do
    common.Step("HMI sends GetVehicleData response with invalid " .. p .. "=" .. tostring(k),
      common.getVehicleData, { common.getCustomData(p, "state", v), resultCode })
  end
end

common.Title("Check for other parameters")
for k, v in pairs(invalidParam) do
  common.Step("HMI sends GetVehicleData response with " .. k, common.getVehicleData, { v, resultCode })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
