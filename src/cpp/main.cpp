
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

#include "collision.hpp"
#include "registry.hpp"
#include "imgui_demo.cpp"

void read_config(sol::state &lua)
{
	lua.script_file(std::string(SOURCE_DIR)+"config.lua");

	
}

int main()
{
	sol::state lua;

	lua.script_file("");

	for(auto mode: sf::VideoMode::getFullscreenModes())
	{
		std::cout << mode.width << " " << mode.height << std::endl;
	}

	sf::RenderWindow window(sf::VideoMode(320, 240), "EverDeeper", sf::Style::Default);
	window.setVerticalSyncEnabled(true);

	std::unordered_map<std::string, sf::Texture*> resources;
	sf::Font font;

	if(!font.loadFromFile(std::string(SOURCE_DIR)+"/resources/basis33.ttf"))
		std::cout << "Couldn't load script" << std::endl;

	ImGui::SFML::Init(window);

	register_functions(lua, window, resources, font);
	lua["ROOT_DIR"] = SOURCE_DIR;
	lua.script("package.path = ROOT_DIR..'/?.lua;'..ROOT_DIR..'/?/init.lua;'..package.path");
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
