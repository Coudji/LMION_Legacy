local MoveableAdapter = require "LMION/Pickup/Simple/MoveableAdapter"
local LargeGatePickup = require "LMION/Pickup/LargeGate/LargeGatePickup"
local GaragePickup = require "LMION/Pickup/Garage/GaragePickup"
local GarageToolbarAdapter = require "LMION/Pickup/Garage/GarageToolbarAdapter"
local ParcelPresentation = require "LMION/Pickup/Common/ParcelPresentation"
local LargeGatePlacement = require "LMION/Pickup/LargeGate/LargeGatePlacement"
local LargeGatePlacementParity = require "LMION/Pickup/LargeGate/LargeGatePlacementParity"

MoveableAdapter.install()
LargeGatePickup.install()
GaragePickup.install()
GarageToolbarAdapter.install()
ParcelPresentation.install()
LargeGatePlacement.install()
LargeGatePlacementParity.install()