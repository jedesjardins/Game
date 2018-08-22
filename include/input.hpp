#ifndef INPUT_HPP_
#define INPUT_HPP_

#include <unordered_map>
#include <vector>

#include <SFML/Graphics.hpp>
#include "imgui.h"
#include "imgui-SFML.h"
#include "sol.hpp"

enum KEYSTATE {
	NONE,
	RELEASED,
	PRESSED,
	HELD
};

class Input
{
public:
	sf::Vector2<KEYSTATE> mouse_state{NONE, NONE};
	sf::Vector2i mouse_pos;

	std::unordered_map<int, KEYSTATE> keystates;

	bool update(sf::Window &window);
	KEYSTATE getKeyState(sf::Keyboard::Key);
	sf::Vector2i getMousePosition();
	KEYSTATE getMouseRight();
	KEYSTATE getMouseLeft();
};


#endif