
#include <unordered_map>
#include <cstdio>
#include <iostream>

#include <SFML/Graphics.hpp>
#include "imgui.h"
#include "imgui-SFML.h"
#include "sol.hpp"

#include "config.h"
#include "input.hpp"
#include "anim_sprite.hpp"
#include "ui_text.hpp"

struct Window_State
{
	bool fullscreen;
	bool use_max_resolution;
	bool borderless;
	sf::Vector2u screen_dimensions;
	sf::Vector2u max_screen_dimensions;
};

Window_State WINDOW_STATE;

typedef std::unordered_map<std::string, sf::Texture*> Resource_Map;

// These files are dropped in as source, no accompanying cpp files
#include "collision.hpp"
#include "registry.hpp"
#include "imgui_demo.cpp"

void read_config(sol::state &lua, sf::RenderWindow &window)
{
	sol::environment empty_env(lua, sol::create);

	lua.script_file(std::string(SOURCE_DIR)+"/config.lua", empty_env);

	WINDOW_STATE.screen_dimensions.x = (unsigned int)empty_env["RES_X"] > 640 ? empty_env["RES_X"] : 640;
	WINDOW_STATE.screen_dimensions.y = (unsigned int)empty_env["RES_Y"] > 480 ? empty_env["RES_Y"] : 480;
	WINDOW_STATE.use_max_resolution = empty_env["USE_MAX_RESOLUTION"];
	WINDOW_STATE.fullscreen = empty_env["FULLSCREEN"];
	WINDOW_STATE.borderless = empty_env["BORDERLESS"];

	if(WINDOW_STATE.fullscreen)
	{
		sf::VideoMode best_mode{0, 0};
		for(auto mode: sf::VideoMode::getFullscreenModes())
			if((mode.width > best_mode.width && mode.height > best_mode.height) || 
				(!WINDOW_STATE.use_max_resolution && 
				mode.width == WINDOW_STATE.screen_dimensions.x &&
				mode.height == WINDOW_STATE.screen_dimensions.y
			))
				best_mode = mode;

		WINDOW_STATE.screen_dimensions = {best_mode.width, best_mode.height};

		window.create(
			best_mode,
			"Game",
			sf::Style::Fullscreen
			);

	}
	else
		if(WINDOW_STATE.borderless)
			window.create(
				sf::VideoMode(WINDOW_STATE.screen_dimensions.x, WINDOW_STATE.screen_dimensions.y),
				"Game",
				sf::Style::None
				);
		else
			window.create(
				sf::VideoMode(WINDOW_STATE.screen_dimensions.x, WINDOW_STATE.screen_dimensions.y),
				"Game",
				sf::Style::Titlebar | sf::Style::Close
				);


	WINDOW_STATE.max_screen_dimensions = {
		sf::VideoMode::getDesktopMode().width,
		sf::VideoMode::getDesktopMode().height
	};

	window.setVerticalSyncEnabled(true);
}

int main()
{
	sol::state lua;
	lua.open_libraries(
			sol::lib::base,
			sol::lib::package,
			sol::lib::string,
			sol::lib::table,
			sol::lib::math,
			sol::lib::os,
			sol::lib::io
		);
	std::string path = lua["package"]["path"];


	sf::RenderWindow window;
	read_config(lua, window);
	ImGui::SFML::Init(window);

	Resource_Map resources;

	sf::Font font;
	if(!font.loadFromFile(std::string(SOURCE_DIR)+"/resources/basis33.ttf"))
		std::cout << "Couldn't load script" << std::endl;

	register_functions(lua, window);

	std::string new_path;
	new_path.append(SOURCE_DIR).append("/?.lua;").append(SOURCE_DIR).append("/?/init.lua;").append(path);
	lua["package"]["path"] = new_path;

	lua["WINDOW_STATE"] = WINDOW_STATE;
	lua["Window"] = &window;
	lua["Resources"] = resources;
	lua["Font"] = font;
	lua.script("require('src.lua.main')");
	sol::function update = lua["update"];


	bool running = true;
	sf::Clock clock;
	sf::Time dt;

	Input input;
	
	while (running)
	{
		ImGui::SFML::Update(window, dt);
		running &= input.update(window);

		window.clear({0, 0, 0, 255});
		running &= (bool)update(dt.asSeconds(), input);
		ImGui::SFML::Render(window);
		window.display();

		dt = clock.restart();
	}

	for(auto it: resources)
	{
		delete it.second;
	}

	ImGui::SFML::Shutdown();

	return 0;

}
