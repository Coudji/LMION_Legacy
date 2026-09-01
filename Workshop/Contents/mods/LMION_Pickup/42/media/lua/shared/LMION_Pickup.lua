local MoveableAdapter = require "LMION/Pickup/MoveableAdapter"
local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"
local GaragePickup = require "LMION/Pickup/GaragePickup"
local ParcelPresentation = require "LMION/Pickup/ParcelPresentation"
local LargeGatePlacement = require "LMION/Pickup/LargeGatePlacement"
local LargeGatePlacementParity = require "LMION/Pickup/LargeGatePlacementParity"

MoveableAdapter.install()
LargeGatePickup.install()
GaragePickup.install()
ParcelPresentation.install()
LargeGatePlacement.install()
LargeGatePlacementParity.install()
