
#include <SFML/Graphics.hpp>

#include "sol.hpp"

#include <unordered_map>

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
	lua.script("print('Test')");

	sf::RenderWindow window(sf::VideoMode(1200, 900), "Game", sf::Style::Titlebar | sf::Style::Close);

	std::unordered_map<sf::Keyboard::Key, int> keystates;

}
