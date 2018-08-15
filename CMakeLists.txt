cmake_minimum_required(VERSION 3.12.0)
project(Game)
set (Tutorial_VERSION_MAJOR 0)
set (Tutorial_VERSION_MINOR 1)

# header files
include_directories(include include/lua include/imgui ${OPENGL_INCLUDE_DIRS})
file(GLOB LUA_SOURCES include/lua/*.c)

ADD_LIBRARY(LUALIB STATIC ${LUA_SOURCES})

#set(SFML_STATIC_LIBRARIES TRUE) #gotta add config to link statically by including source
find_package(SFML 2.5 COMPONENTS graphics audio REQUIRED)
find_package(OpenGL REQUIRED)

# source files
file(GLOB SOURCES "src/cpp/*.cpp")

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(game ${SOURCES})

TARGET_LINK_LIBRARIES(game LUALIB sfml-graphics sfml-audio ${OPENGL_LIBRARIES})
