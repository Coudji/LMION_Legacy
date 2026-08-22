require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.3-dev"

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)
