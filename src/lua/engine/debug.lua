
local Debug = {}

Debug.modes = {}
Debug.default = nil

function print(...)
	local n = select("#",...)
	for i = 1,n do
		local v = tostring(select(i,...))
		io.write(v)
		io.write(" ")
	end
	io.write("\n")
end

function Debug:write(mode, ...)
	if Debug.modes[mode] or Debug.default then
		io.write(mode..": ")
		local n = select("#",...)
		for i = 1,n do
			local v = tostring(select(i,...))
			io.write(v)
			io.write(" ")
		end
		io.flush()
	end
end

function Debug:writeln(mode, ...)
	if Debug.modes[mode] or Debug.default then
		io.write(mode..": ")

		local n = select("#",...)
		for i = 1,n do
			local v = tostring(select(i,...))
			io.write(v)
			io.write(" ")
		end
		io.write("\n")
	end
end

function Debug:write2(mode, ...)
	if Debug.modes[mode] or Debug.default then
		for i = 1, select("#", ...) do
			--print(tostring(select(i, ...)))
			io.write(tostring(select(i, ...)))
		end
		io.flush()
	end
end

function Debug:setMode(mode, flag)
	if flag then
		Debug.modes[mode] = true
	else
		Debug.modes[mode] = nil
	end
end

function Debug:setDefault(flag)
	Debug.default = flag
end

return Debug