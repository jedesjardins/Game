#include "input.hpp"

bool Input::update(sf::Window &window)
{
	sf::Event event;
	bool running = true;

	std::vector<int> deletekeys;

	bool ignoreMouseInput = ImGui::GetIO().WantCaptureMouse;
	bool ignoreKeyboardInput = ImGui::GetIO().WantTextInput || ImGui::GetIO().WantTextInput;

	//transitions
	for(auto it: this->keystates)
	{
		if(ignoreKeyboardInput || it.second == RELEASED)
			deletekeys.push_back(it.first);
		else if(it.second == PRESSED)
			this->keystates[it.first] = HELD;
	}

	if(this->mouse_state.x == PRESSED)
		this->mouse_state.x = HELD;
	else if(this->mouse_state.x == RELEASED)
		this->mouse_state.x = NONE;

	if(this->mouse_state.y == PRESSED)
		this->mouse_state.y = HELD;
	else if(this->mouse_state.y == RELEASED)
		this->mouse_state.y = NONE;

	for(auto it: deletekeys)
	{
		this->keystates.erase(it);
	}
	
	while (window.pollEvent(event))
	{	
		ImGui::SFML::ProcessEvent(event);
		switch (event.type)
		{
			case sf::Event::Closed:
				running &= false;
				break;
			case sf::Event::MouseMoved:
				if(ignoreMouseInput) break;

				this->mouse_pos.x = event.mouseMove.x;
				this->mouse_pos.y = event.mouseMove.y;

			case sf::Event::MouseButtonPressed:
				if(ignoreMouseInput) break;

				if(event.mouseButton.button == sf::Mouse::Left)
				{
					this->mouse_state.x = PRESSED;
				}
				else if (event.mouseButton.button == sf::Mouse::Right)
				{
					this->mouse_state.y = PRESSED;
				}

				break;

			case sf::Event::MouseButtonReleased:
				if(ignoreMouseInput) break;

				if(event.mouseButton.button == sf::Mouse::Left)
				{
					this->mouse_state.x = RELEASED;
				}
				else if (event.mouseButton.button == sf::Mouse::Right)
				{
					this->mouse_state.y = RELEASED;
				}

				break;
			case sf::Event::KeyPressed:
				if(ignoreKeyboardInput) break;
				if(this->keystates[event.key.code] != HELD)
					this->keystates[event.key.code] = PRESSED;
				break;
			case sf::Event::KeyReleased:
				if(ignoreKeyboardInput) break;
				this->keystates[event.key.code] = RELEASED;
				break;
			default:
				break;
		}
	}

	return running;
}

KEYSTATE Input::getKeyState(sf::Keyboard::Key key)
{
	return this->keystates[key];
}

sf::Vector2i Input::getMousePosition()
{
	return this->mouse_pos;
}

sf::Vector2f Input::getMouseViewPosition(const sf::RenderWindow &window, const sf::View &view)
{
	return window.mapPixelToCoords(this->mouse_pos, view);
}

KEYSTATE Input::getMouseLeft()
{
	return this->mouse_state.x;
}

KEYSTATE Input::getMouseRight()
{
	return this->mouse_state.y;
}

