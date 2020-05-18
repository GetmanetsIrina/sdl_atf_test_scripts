---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL does not transfer OnVehicleData notification to subscribed app if HMI sends notification
-- with invalid values of `windowStatus` structure params:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
--
-- In case:
-- 1) App is subscribed to `windowStatus` data.
-- 2) HMI sends the invalid `windowStatus` structure in OnVehicleData notification:
--    - invalid parameter name
--    - invalid parameter type
--    - missing mandatory parameter
--    - params out of bounds
--    - empty value
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local invalidValue = {
  emptyValue = "",
  invalidType = true,
  beyondMax = 101
}

local invalidParam = {
  ["empty_location"] = {
    { location = {}, -- empty location parameter
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidType_location"] = {
    { location = "string", -- invalid type for location parameter
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["missing_location"] = { -- without location parameter
    { state = { approximatePosition = 50, deviation = 50 }}
  },
  ["invalidName_location"] ={ -- invalid name for location parameter
    { loCaTion = { col = 49, row = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidName_col"] = { -- invalid name for col parameter from Grid structure
    { location = { CoL = 49, row = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidName_row"] = { -- invalid name for row parameter from Grid structure
    { location = { col = 49, RoW = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["empty_state"] = { -- empty state parameter
    { location = { col = 49, row = 49 },
      state = {}
    }
  },
  ["invalidType_state"] = { -- invalid type for state parameter
    { location = { col = 49, row = 49 },
      state = "string"
    }
  },
  ["missing_state"] = { -- without state parameter
    { location = { col = 49, row = 49 } }
  },
  ["invalidName_state"] = { -- invalid name for state parameter
    { location = { col = 49, row = 49 },
      StaTe = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidName_approximatePosition"] = { -- invalid name for approximatePosition parameter from WindowState structure
    { location = { col = 49, row = 49 },
      state = { ApproximatePositioN = 50, deviation = 50 }
    }
  },
  ["invalidName_deviation"] = { -- invalid name for deviation parameter from WindowState structure
    { location = { col = 49, row = 49 },
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

local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
for param in pairs(common.getWindowStatusParams()[1].location) do
  common.Title("HMI sends with invalid `windowStatus` structure for " .. param)
  for k, v in pairs(invalidValue) do
    common.Step("OnVehicleData with invalid value for " .. param .. "=" .. tostring(k),
      common.sendOnVehicleData, { common.getCustomData(param, "location", v), notExpected })
  end
end

for param in pairs(common.getWindowStatusParams()[1].state) do
  common.Title("HMI sends with invalid `windowStatus` structure for " .. param)
  for k, v in pairs(invalidValue) do
    common.Step("OnVehicleData with invalid value for " .. param .. "=" .. tostring(k),
    common.sendOnVehicleData, { common.getCustomData(param, "state", v), notExpected })
  end
end

common.Title("Check for other parameters")
for k, v in pairs(invalidParam) do
  common.Step("OnVehicleData with " .. k, common.sendOnVehicleData, { v, notExpected })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
