LUA_FOLDER = (...):match("(.-)[^%.]+$")
RESOURCE_FOLDER = "resources.data."

print(LUA_FOLDER)

require(LUA_FOLDER .. 'engine.generics')

ECS = require(LUA_FOLDER .. 'engine.ecs')
State = require(LUA_FOLDER .. 'engine.state')
SM = require(LUA_FOLDER .. 'engine.statemanager')
QuadTree = require(LUA_FOLDER ..'engine.quadtree')


--local r = Random.new()
--r:seed(os.time())
--println(r:random(1, 5))
--println(r:random(1))
--println(r:random())



function update(dt, input)
	return SM:update(dt, input)
end
