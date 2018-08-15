
local t = {"Use listAllFunctions() to view possible commands\nUse help to see this again"}
local out_str = {""}
local setfocus = false

local help_str = [[
Use listAllFunctions() to view possible commands
]]

local safe_environment = {
	pack = table.pack,
	unpack = table.unpack,
	error = error,
	ipairs = ipairs,
	pairs = pairs,
	next = next,
	select = select,
	tonumber = tonumber,
	tostring = tostring,
	type = type
}
safe_environment.__index = safe_environment

function createSafeEnvironment(ecs, map)
	local env = {}

	env.listAll = function()
			local str = ""
			local func_names = {}

			for k, v in pairs(env) do
				if type(k) == "string" then
					func_names[#func_names+1] = k
				end
			end

			table.sort(func_names)

			return table.concat(func_names, "\n")
		end
	env[env.listAll] = "()"

	return setmetatable(env, safe_environment)
end

local lastscroll = 0

function Console(env)
	if Imgui.Begin("Console") then
		local scrolly = 0
		if Imgui.BeginChild("Log", 400, 200, true) then
			for _, str in ipairs(t) do
				Imgui.Text(str)
			end
			if lastscroll < Imgui.GetScrollMaxY() then 
				Imgui.SetScrollY(Imgui.GetScrollMaxY())
				lastscroll = Imgui.GetScrollMaxY()
			end
		end
		Imgui.EndChild()

		if setfocus then Imgui.SetKeyboardFocusHere(0) end
		local pressed = Imgui.InputText(out_str)
		if Imgui.IsItemActive() then setfocus = false end

		if pressed then --and out_str[1] ~= "" then
			setfocus = true
			setscroll = true
			if string.find(out_str[1], "help") == 1 then
				t[#t+1] = "> "..out_str[1]

				if out_str[1] == "help" then
					t[#t+1] = help_str
				else
					local space_i = string.find(out_str[1], " ")
					if space_i then
						local func_name = string.sub(out_str[1], space_i+1)

						if func_name ~= "" and env[func_name] then
							t[#t+1] = func_name..env[env[func_name]]
						else
							t[#t+1] = "error: "..func_name.." doesn't exist"
						end
					end
				end
			else
				t[#t+1] = "> "..out_str[1]

				if out_str[1] ~= "" then
					local status, ret = pcall(load("return "..out_str[1], nil, "t", env))

					if status then
						if not ret then ret = "nil" end
						if type(ret) == "table" then
							t[#t+1] = "{"
							for k, v in pairs(ret) do
								t[#t+1] = "\t"..tostring(k)..": "..tostring(v)
							end
							t[#t+1] = "}"
						else	
							t[#t+1] = tostring(ret)
						end
					else
						status, ret = pcall(load(out_str[1], nil, "t", env))
						if not status then
							t[#t+1] = ret
						end
					end
				end
			end
			out_str[1] = ""
		else if Imgui.IsKeyPressed(60, false) and out_str[1] ~= "" then
			local str = out_str[1]
			local matches = {}
			t[#t+1] = "> "..str

			for k, v in pairs(env) do
				if type(k) == "string" and string.find(k, str) == 1 then
					t[#t+1] = k
					table.insert(matches, v)
				end
			end
		end end

	end
	Imgui.End()
end

