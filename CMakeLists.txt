cmake_minimum_required(VERSION 3.12.0)
project(Game)
set (Tutorial_VERSION_MAJOR 0)
set (Tutorial_VERSION_MINOR 1)

# MESSAGE(STATUS ${CMAKE_CURRENT_SOURCE_DIR})
# MESSAGE(STATUS ${CMAKE_BINARY_DIR})
# add_compile_definitions(BASE_DIR="C:/Users/James/Source/Game")
set(SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")

# header files
configure_file(
	"${PROJECT_SOURCE_DIR}/config.h.in"
	"${PROJECT_BINARY_DIR}/config.h"
)
include_directories(include include/lua include/imgui ${OPENGL_INCLUDE_DIRS} ${PROJECT_BINARY_DIR})

# Lua Library
file(GLOB LUA_SOURCES include/lua/*.c)
ADD_LIBRARY(LUALIB STATIC ${LUA_SOURCES})

# SFML Library
# set(SFML_STATIC_LIBRARIES TRUE) #gotta add config to link statically by including source
find_package(SFML 2.5 COMPONENTS graphics audio REQUIRED)
find_package(OpenGL REQUIRED)

# source files
file(GLOB SOURCES "src/cpp/*.cpp" "src/cpp/imgui/*.cpp")

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(game ${SOURCES})

TARGET_LINK_LIBRARIES(game LUALIB sfml-graphics sfml-audio ${OPENGL_LIBRARIES})

# file(COPY "src" DESTINATION ${CMAKE_BINARY_DIR})
# file(COPY "resources" DESTINATION ${CMAKE_BINARY_DIR})
