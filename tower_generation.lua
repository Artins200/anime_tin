-- Standalone extract: generates only the red-and-white radio mast.
-- This file is not embedded into Place1.rbxl or called by the game scripts.
-- Roblox Luau ModuleScript usage: local createRadioTower = require(module); createRadioTower(workspace)

local function createRadioTower(parent, origin)
	parent = parent or workspace
	origin = origin or Vector3.zero

	local tower = Instance.new("Model")
	tower.Name = "RadioTower"

	local RED = Color3.fromRGB(177, 57, 48)
	local IVORY = Color3.fromRGB(192, 199, 198)
	local METAL = Color3.fromRGB(157, 61, 51)
	local RAIL = Color3.fromRGB(181, 187, 185)

	local function at(x, y, z)
		return origin + Vector3.new(x, y, z)
	end

	local function makePart(name, size, position, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = position
		part.Color = color
		part.Material = material or Enum.Material.Metal
		part.Anchored = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = tower
		return part
	end

	local function makeBeam(name, a, b, width, color)
		local midpoint = (a + b) * 0.5
		local beam = makePart(name, Vector3.new(width, width, (b - a).Magnitude), midpoint, color)
		beam.CFrame = CFrame.lookAt(midpoint, b)
		return beam
	end

	local function radiusAt(y)
		return 54 - 44 * (y / 324)
	end

	local function corner(signX, signZ, y)
		local radius = radiusAt(y)
		return at(signX * radius, y, signZ * radius)
	end

	local corners = {
		{-1, -1},
		{ 1, -1},
		{ 1,  1},
		{-1,  1},
	}

	-- Four tapered legs, horizontal ties and crossed braces; red bands mark
	-- the lower sections and the upper warning section of the mast.
	for level = 0, 13 do
		local y0 = level * 24
		local y1 = math.min(y0 + 24, 324)
		local color = (level < 2 or level == 7 or level >= 12) and RED or IVORY

		for index, signs in ipairs(corners) do
			local nextSigns = corners[index % #corners + 1]
			makeBeam("TaperedTowerLeg", corner(signs[1], signs[2], y0), corner(signs[1], signs[2], y1), 2.1, color)
			makeBeam("TowerHorizontalTie", corner(signs[1], signs[2], y1), corner(nextSigns[1], nextSigns[2], y1), 1.0, color)
			makeBeam("TowerXBrace", corner(signs[1], signs[2], y0), corner(nextSigns[1], nextSigns[2], y1), 0.85, color)
			makeBeam("TowerXBrace", corner(nextSigns[1], nextSigns[2], y0), corner(signs[1], signs[2], y1), 0.85, color)
		end
	end

	-- Ground anchors and the small service deck near the antenna head.
	for _, signX in ipairs({-1, 1}) do
		for _, signZ in ipairs({-1, 1}) do
			makePart("TowerAnchorShoe", Vector3.new(4, 4, 4), at(signX * 53, 2, signZ * 53), METAL)
		end
	end

	makePart("AntennaServiceDeck", Vector3.new(25, 0.8, 25), at(0, 300, 0), Color3.fromRGB(83, 94, 99))
	for _, signX in ipairs({-1, 1}) do
		for _, signZ in ipairs({-1, 1}) do
			makePart("AntennaDeckRailPost", Vector3.new(0.45, 3.5, 0.45), at(signX * 11, 302, signZ * 11), RAIL)
		end
	end
	for _, side in ipairs({-1, 1}) do
		makePart("AntennaDeckRail", Vector3.new(22, 0.35, 0.35), at(0, 303.5, side * 11), RAIL)
		makePart("AntennaDeckRail", Vector3.new(0.35, 0.35, 22), at(side * 11, 303.5, 0), RAIL)
	end

	makePart("TopWhipAntenna", Vector3.new(0.8, 27, 0.8), at(0, 337.5, 0), RAIL)
	makePart("AntennaTopCrossbar", Vector3.new(12, 0.6, 0.6), at(0, 341, 0), RAIL)
	for _, side in ipairs({-1, 1}) do
		makePart("TopPanelAntenna", Vector3.new(1.2, 10, 2), at(side * 6, 335, 0), IVORY)
	end

	-- Directional cellular panels and microwave dishes mounted on the mast.
	for _, y in ipairs({157, 205, 253, 277}) do
		for _, side in ipairs({-1, 1}) do
			local radius = radiusAt(y)
			local panel = makePart("CellularPanelAntenna", Vector3.new(2, 14, 5.5), at(side * (radius - 5), y, 0), IVORY)
			panel.CanCollide = false
			makeBeam("AntennaMount", at(side * (radius - 11), y, 0), panel.Position, 0.8, Color3.fromRGB(104, 115, 117))

			local dish = makePart("MicrowaveDish", Vector3.new(1.2, 7, 7), at(side * (radius - 12), y, 12), Color3.fromRGB(171, 180, 182))
			dish.Shape = Enum.PartType.Cylinder
			dish.CanCollide = false
			makeBeam("DishFeed", dish.Position, at(side * (radius - 4), y, 12), 0.55, Color3.fromRGB(94, 106, 111))
		end
	end

	-- Red obstruction lights on the mast at four elevations.
	for _, y in ipairs({24, 120, 216, 300}) do
		for _, side in ipairs({-1, 1}) do
			local marker = makePart("TowerObstructionLamp", Vector3.new(0.8, 1.1, 0.8), at(side * (radiusAt(y) + 0.7), y, 0), Color3.fromRGB(174, 54, 48), Enum.Material.SmoothPlastic)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(220, 66, 57)
			light.Range = 18
			light.Brightness = 0.28
			light.Parent = marker
		end
	end

	tower.Parent = parent
	return tower
end

return createRadioTower
