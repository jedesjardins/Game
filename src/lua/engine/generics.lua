
inf = math.huge

function math.sign(x)
	return (x < 0 and -1) or (x > 0 and 1) or 0
end

function math.clamp(val, min, max)
	return (val < min and min) or (val > max and max) or val
end

function math.round(value)
	return math.floor(value+0.5)
end

function math.pow(num, co)

	local res = co == 0 and 1 or num

	for i=2,co do
		res = res*num
	end

	return res
end

function math.lerp(a, b, t)
	return a + (b-a)*(t or .1)
end

function table.join(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function cos(angle)
	return math.cos(math.rad(angle))
end

function sin(angle)
	return math.sin(math.rad(angle))
end

function print(...)
	local n = select("#",...)
	for i = 1,n do
		local v = tostring(select(i,...))
		io.write(v)
		io.write(" ")
	end
	io.flush()
end

function println(...)
	local n = select("#",...)
	for i = 1,n do
		local v = tostring(select(i,...))
		io.write(v)
		io.write(" ")
	end
	io.write("\n")
end

function deepPrint(name, val, depth)
	if type(val) == "table" then
		for i = 1, depth do
			io.write("\t")
		end
		println(name)
		for k, v in pairs(val) do
			deepPrint(k, v, depth + 1)
		end
	else
		for i = 1, depth do
			io.write("\t")
		end
		println(name, val)
	end
end


List = {}
List.__index = List
function List.new()
	self = setmetatable({first = 0, last = -1}, List)
	return self
end

function List:pushleft(value)
	local first = self.first - 1
	self.first = first
	self[first] = value
end

function List:pushright(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
end

function List:popleft()
	local first = self.first
	if first > self.last then return nil end
	local value = self[first]
	self[first] = nil        -- to allow garbage collection
	self.first = first + 1
	return value
end

function List:peekleft()
	local first = self.first
	if first > self.last then return nil end
	return self[first]
end

function List:popright()
	local last = self.last
	if self.first > last then return nil end
	local value = self[last]
	self[last] = nil         -- to allow garbage collection
	self.last = last - 1
	return value
end

function List:peekright()
	local last = self.last
	if self.first > last then return nil end
	return self[last]
end

function List:size()
	return self.last - self.first + 1
end

function List:iter()

	local first = self.first
	local last = self.last
	local index = first - 1

	return function ()
		index = index + 1

		return self[index]
	end
end