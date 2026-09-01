require "BuildingObjects/ISBuildingObject"

local originalTryBuild = ISBuildingObject.tryBuild

ISBuildingObject.tryBuild = function(self, x, y, z)
    if self ~= nil
        and (self.Type == "LMIONSimpleDoorPlacementCursor"
            or self.Type == "LMIONGaragePlacementCursor"
            or self.Type == "LMIONLargeGatePlacementCursor")
    then
        -- LMION placement cursors own their real movement/equipment/action chain
        -- inside create(). Prevent ISBuildingObject from inserting its generic
        -- ISBuildAction and duplicate walk before that chain.
        self.skipBuildAction = true
        self.skipWalk2 = true
    end

    return originalTryBuild(self, x, y, z)
end
