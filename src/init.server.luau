local ChangeHistoryService = game:GetService("ChangeHistoryService")

local ores = require(script.ores)

local toolbar = plugin:CreateToolbar("Cave")

local toolbarButton = toolbar:CreateButton(
	"Cave",
	"Click to create a cave where your camera is currently located at",
	""
)

local RESOLUTION = 250
local THRESHOLD = 0.6
local SPACING = 6

local function edges(position: Vector3, spacing: number): { Vector3 }
	return {
		position + Vector3.fromNormalId(Enum.NormalId.Top) * spacing,
		position + Vector3.fromNormalId(Enum.NormalId.Bottom) * spacing,
		position + Vector3.fromNormalId(Enum.NormalId.Left) * spacing,
		position + Vector3.fromNormalId(Enum.NormalId.Right) * spacing,
		position + Vector3.fromNormalId(Enum.NormalId.Back) * spacing,
		position + Vector3.fromNormalId(Enum.NormalId.Front) * spacing,
	}
end

local function roundPosition(position: Vector3): Vector3
	return Vector3.new(
		math.round(position.X),
		math.round(position.Y),
		math.round(position.Z)
	)
end

local function generatePerlin(position: Vector3)
	return math.noise(
		position.X / RESOLUTION,
		position.Y / RESOLUTION,
		position.Z / RESOLUTION
	)
end

toolbarButton.Click:Connect(function()
	local caveFolder = Instance.new("Folder")
	caveFolder.Name = "Cave"

	local airBlocks: { Vector3 } = {
		roundPosition(workspace.CurrentCamera.CFrame.Position),
	}
	local visited: { [Vector3]: boolean } = {}

	local offset = Vector3.new(
		math.random(-100_000, 100_000) / 100 + math.random(),
		math.random(-100_000, 100_000) / 100,
		math.random(-100_000, 100_000) / 100
	)

	print("Finding cave position...")

	-- helps ensure that we find a spot which can actually generate a more sensable cave
	-- instead of a one block hole cave lol
	repeat
		offset += Vector3.new(
			(math.random() - 0.5) * 1_000,
			(math.random() - 0.5) * 1_000,
			(math.random() - 0.5) * 1_000
		)
	-- print(generatePerlin(airBlocks[1] + offset))
	-- task.wait()
	until generatePerlin(airBlocks[1] + offset) > THRESHOLD

	print("Generating")

	while #airBlocks > 0 do
		for i, airBlock in airBlocks do
			table.remove(airBlocks, i)

			for _, edge in edges(airBlock, SPACING) do
				if visited[edge] then
					continue
				else
					visited[edge] = true
				end

				local value = generatePerlin(edge + offset)

				if value > THRESHOLD then
					table.insert(airBlocks, edge)
				else
					local block = Instance.new("Part")
					block.Size = Vector3.new(SPACING, SPACING, SPACING)
					block.Position = edge
					block.Material = Enum.Material.Rock
					block.BrickColor = BrickColor.new("Dark stone grey")
					block.Anchored = true
					block.Name = "Stone"

					for _, ore in ores do
						if math.random(1, ore.rarity) == 1 then
							for property, propertyValue in ore.properties do
								block[property] = propertyValue
							end
							block.Name = ore.name
							break
						end
					end

					block.Parent = caveFolder
				end
			end
		end
	end

	caveFolder.Parent = workspace
	ChangeHistoryService:SetWaypoint("Generated Cave")
end)
