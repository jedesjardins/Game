LUA_FOLDER = (...):match("(.-)[^%.]+$")

TILESIZE = 16

require(LUA_FOLDER .. 'engine.generics')

ECS = require(LUA_FOLDER .. 'engine.ecs')
State = require(LUA_FOLDER .. 'engine.state')
SM = require(LUA_FOLDER .. 'engine.statemanager')
QuadTree = require(LUA_FOLDER ..'engine.quadtree')

function update(dt, input)
	return SM:update(dt, input)
end
