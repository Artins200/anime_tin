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
	local DECK = Color3.fromRGB(83, 94, 99)
	local DARK = Color3.fromRGB(104, 115, 117)
	local WARM = Color3.fromRGB(255, 214, 150)

	local TOWER_HEIGHT = 324
	local LANDING_STEP = 48
	local LANDING_HALF = 12
	local HOLE_HALF = 4
	local LADDER_TOP = 328

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
		return 54 - 44 * (y / TOWER_HEIGHT)
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
		local y1 = math.min(y0 + 24, TOWER_HEIGHT)
		local color = (level < 2 or level == 7 or level >= 12) and RED or IVORY

		for index, signs in ipairs(corners) do
			local nextSigns = corners[index % #corners + 1]
			local isDoorFace = level == 0 and index == 1
			makeBeam("TaperedTowerLeg", corner(signs[1], signs[2], y0), corner(signs[1], signs[2], y1), 2.1, color)
			makeBeam("TowerHorizontalTie", corner(signs[1], signs[2], y1), corner(nextSigns[1], nextSigns[2], y1), 1.0, color)
			if not isDoorFace then
				makeBeam("TowerXBrace", corner(signs[1], signs[2], y0), corner(nextSigns[1], nextSigns[2], y1), 0.85, color)
				makeBeam("TowerXBrace", corner(nextSigns[1], nextSigns[2], y0), corner(signs[1], signs[2], y1), 0.85, color)
			end
		end
	end

	-- Ground anchors and the small service deck near the antenna head.
	for _, signX in ipairs({-1, 1}) do
		for _, signZ in ipairs({-1, 1}) do
			makePart("TowerAnchorShoe", Vector3.new(4, 12, 4), at(signX * 53.5, -2, signZ * 53.5), METAL)
		end
	end

	-- Access route: approach from the south face and climb a central truss.
	makePart("TowerEntryPath", Vector3.new(14, 1, 72), at(0, 0.25, -24), Color3.fromRGB(120, 120, 115), Enum.Material.Concrete)
	local ladder = Instance.new("TrussPart")
	ladder.Name = "TowerCoreLadder"
	ladder.Size = Vector3.new(2, LADDER_TOP, 2)
	ladder.Position = at(0, LADDER_TOP / 2, 0)
	ladder.Color = RAIL
	ladder.Material = Enum.Material.Metal
	ladder.Anchored = true
	ladder.Parent = tower

	local function floorWithHole(name, y, half, thickness, color)
		local strip = half - HOLE_HALF
		local center = HOLE_HALF + strip / 2
		for _, sign in ipairs({-1, 1}) do
			makePart(name, Vector3.new(half * 2, thickness, strip), at(0, y, sign * center), color)
			makePart(name, Vector3.new(strip, thickness, HOLE_HALF * 2), at(sign * center, y, 0), color)
		end
	end

	local function railing(name, floorY, half)
		local height = 3.5
		for _, sx in ipairs({-1, 0, 1}) do
			for _, sz in ipairs({-1, 0, 1}) do
				if sx ~= 0 or sz ~= 0 then
					makePart(name .. "Post", Vector3.new(0.45, height, 0.45), at(sx * half, floorY + height / 2, sz * half), RAIL)
				end
			end
		end
		for _, railY in ipairs({height - 0.2, 1.7}) do
			for _, side in ipairs({-1, 1}) do
				makePart(name, Vector3.new(half * 2, 0.3, 0.3), at(0, floorY + railY, side * half), RAIL)
				makePart(name, Vector3.new(0.3, 0.3, half * 2), at(side * half, floorY + railY, 0), RAIL)
			end
		end
	end

	for y = LANDING_STEP, 288, LANDING_STEP do
		floorWithHole("LandingDeck", y, LANDING_HALF, 0.6, DECK)
		railling("LandingRail", y + 0.3, LANDING_HALF)
		local radius = radiusAt(y)
		for _, side in ipairs({-1, 1}) do
			makeBeam("LandingStrut", at(side * LANDING_HALF, y - 0.3, 0), at(side * radius, y - 0.3, 0), 1.2, METAL)
			makeBeam("LandingStrut", at(0, y - 0.3, side * LANDING_HALF), at(0, y - 0.3, side * radius), 1.2, METAL)
		end
		for _, signs in ipairs(corners) do
			makeBeam("LandingStrut", at(signs[1] * LANDING_HALF, y - 0.3, signs[2] * LANDING_HALF), corner(signs[1], signs[2], y) - Vector3.new(0, 0.3, 0), 0.8, METAL)
		end
		for _, side in ipairs({-1, 1}) do
			local lamp = makePart("LandingLamp", Vector3.new(1.2, 0.6, 1.2), at(side * (LANDING_HALF - 1.5), y - 0.6, 0), WARM, Enum.Material.SmoothPlastic)
			local pointLight = Instance.new("PointLight")
			pointLight.Color = WARM; pointLight.Range = 24; pointLight.Brightness = 0.8; pointLight.Parent = lamp
		end
	end

	floorWithHole("AntennaServiceDeck", 300, 13, 0.8, DECK)
	railling("AntennaDeckRail", 300.4, 12)
	floorWithHole("TowerTopPlate", 324.5, radiusAt(TOWER_HEIGHT), 1, RED)
	railling("TopRail", 325, radiusAt(TOWER_HEIGHT) - 0.5)

	makePart("TopWhipAntenna", Vector3.new(0.8, 27, 0.8), at(0, 338.5, 7), RAIL)
	makePart("AntennaTopCrossbar", Vector3.new(12, 0.6, 0.6), at(0, 341, 7), RAIL)
	for _, side in ipairs({-1, 1}) do
		makePart("TopPanelAntenna", Vector3.new(1.2, 10, 2), at(side * 6, 330, 0), IVORY)
	end

	-- Directional panels and two microwave dishes per side.
	for _, y in ipairs({157, 205, 253, 277}) do
		local radius = radiusAt(y)
		for _, side in ipairs({-1, 1}) do
			local panel = makePart("CellularPanelAntenna", Vector3.new(2, 14, 5.5), at(side * (radius + 4), y, 0), IVORY)
			panel.CanCollide = false
			makeBeam("AntennaMount", at(side * radius, y, 0), panel.Position, 0.8, DARK)
			for _, z in ipairs({-12, 12}) do
				local dish = makePart("MicrowaveDish", Vector3.new(1.2, 7, 7), at(side * (radius + 6), y, z), Color3.fromRGB(171, 180, 182))
				dish.Shape = Enum.PartType.Cylinder
				dish.CanCollide = false
				makeBeam("DishFeed", dish.Position, at(side * radius, y, z), 0.55, Color3.fromRGB(94, 106, 111))
			end
		end
	end

	-- Red obstruction lights on all four faces at four elevations.
	for _, y in ipairs({24, 120, 216, 300}) do
		local offset = radiusAt(y) + 0.7
		for _, side in ipairs({-1, 1}) do
			for _, position in ipairs({at(side * offset, y, 0), at(0, y, side * offset)}) do
				local marker = makePart("TowerObstructionLamp", Vector3.new(0.8, 1.1, 0.8), position, Color3.fromRGB(174, 54, 48), Enum.Material.SmoothPlastic)
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(220, 66, 57)
				light.Range = 18
				light.Brightness = 0.28
				light.Parent = marker
			end
		end
	end

	tower.WorldPivot = CFrame.new(origin)
	tower.Parent = parent
	return tower
end

return createRadioTower
