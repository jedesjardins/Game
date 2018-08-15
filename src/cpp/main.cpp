
#include <unordered_map>
#include <cstdio>

#include <SFML/Graphics.hpp>
#include "imgui.h"
#include "imgui-SFML.h"
#include "sol.hpp"

#include "input.hpp"

#include "collision.hpp"
#include "registry.hpp"
#include "imgui_demo.cpp"

#define stringize(x) #x

int main()
{
	sf::RenderWindow window(sf::VideoMode(1200, 900), "EverDeeper", sf::Style::Titlebar | sf::Style::Close);
	window.setVerticalSyncEnabled(true);

	std::unordered_map<std::string, sf::Texture*> resources;
	sf::Font font;

	if(!font.loadFromFile(std::string(BASE_DIR)+"/resources/basis33.ttf"))
		printf("Couldn't load script");

	ImGui::SFML::Init(window);

	sol::state lua;

	register_functions(lua, window, resources, font);
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
