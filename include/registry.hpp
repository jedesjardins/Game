#include "random_generator.hpp"

using KEYS = sf::Keyboard::Key;

void register_functions(sol::state &lua, sf::RenderWindow &window)
{
	lua.new_usertype<sf::RenderWindow>("RenderWindow",
		"", sol::no_constructor,
		/*
		"setView", [](){},
		"getView", [](){},
		"clear", [](){},
		*/
		"draw", [](sf::RenderWindow &window, const sf::Drawable &drawable)
			{
				window.draw(drawable);
			}
	);

	lua.new_usertype<Window_State>("Window_State",
		"", sol::no_constructor,
		"fullscreen", &Window_State::fullscreen,
		"borderless", &Window_State::borderless,
		"screen_dimensions", &Window_State::screen_dimensions,
		"max_screen_dimensions", &Window_State::max_screen_dimensions
	);

	lua.new_usertype<Resource_Map>("Resource_Map",
		"getTexture", [](Resource_Map &resources, std::string id) -> sf::Texture const&
		{
			sf::Texture *texture{nullptr};
			if(!resources[id])
			{
				texture = new sf::Texture();
				texture->loadFromFile((std::string(SOURCE_DIR)+"/resources/sprites/"+id).c_str());

				resources[id] = texture;
			}
			else
				texture = resources[id];

			return *texture;
		}
	);

	lua.new_usertype<Input>("Input",
		"state", &Input::getKeyState,
		"mousePos", &Input::getMousePosition,
		"mouseRight", &Input::getMouseRight,
		"mouseLeft", &Input::getMouseLeft,
		"mouseLocalPosition", &Input::getMousePosition,
		"mouseGlobalPosition", &Input::getMouseViewPosition
	);

	lua.new_usertype<RandomGenerator>("Random",
		"seed", &RandomGenerator::seed,
		"random", sol::overload(
				[](RandomGenerator &engine, int min, int max) -> int
				{
					++max;
					return static_cast<int>(engine.random()*(max-min) + min);
				},
				[](RandomGenerator &engine, int max) -> int
				{
					++max;
					return static_cast<int>(engine.random()*max);
				},
				[](RandomGenerator &engine) -> double
				{
					return engine.random();
				}
			)
	);

	lua.new_usertype<sf::Vector2f>("Vec2f",
		"new", sol::constructors<sf::Vector2f(), sf::Vector2f(double, double)>(),
		"x", &sf::Vector2f::x,
		"y", &sf::Vector2f::y
	);

	lua.new_usertype<sf::Vector2i>("Vec2i",
		"new", sol::constructors<sf::Vector2i(), sf::Vector2f(int, int)>(),
		"x", &sf::Vector2i::x,
		"y", &sf::Vector2i::y
	);

	lua.new_usertype<sf::Vector2u>("Vec2u",
		"new", sol::constructors<sf::Vector2u(), sf::Vector2u(unsigned int, unsigned int)>(),
		"x", &sf::Vector2u::x,
		"y", &sf::Vector2u::y
	);

	lua.new_usertype<sf::Anim_Sprite>("Anim_Sprite",
		sol::base_classes, sol::bases<sf::Drawable>(),
		"setPosition", sol::overload(
				static_cast<void (sf::Anim_Sprite::*)(float, float)>(&sf::Anim_Sprite::setPosition),
				static_cast<void (sf::Anim_Sprite::*)(const sf::Vector2f&)>(&sf::Anim_Sprite::setPosition)
			),
		"setRotation", &sf::Anim_Sprite::setRotation,
		"setTexture", &sf::Anim_Sprite::setTexture,
		"setFrames", &sf::Anim_Sprite::setFrames,
		"setFrame", &sf::Anim_Sprite::setFrame
	);

	lua.new_usertype<sf::View>("View",
		"setCenter", sol::overload(
				static_cast<void (sf::View::*)(float, float)>(&sf::View::setCenter),
				static_cast<void (sf::View::*)(const sf::Vector2f&)>(&sf::View::setCenter)
			),
		"getCenter", &sf::View::getCenter,
		"setSize", sol::overload(
				static_cast<void (sf::View::*)(float, float)>(&sf::View::setSize),
				static_cast<void (sf::View::*)(const sf::Vector2f&)>(&sf::View::setSize)
			),
		"getSize", &sf::View::getSize,
		"makeTarget", [&window](sf::View &view)
			{
				window.setView(view);
			}
	);

	lua.new_usertype<sf::UI_Text>("UI_Text",
		sol::base_classes, sol::bases<sf::Drawable>(),
		"new", sol::constructors<
				sf::UI_Text(),
				sf::UI_Text(const std::string &, const sf::Font &, unsigned int)
			>(),
		"setPosition", sol::overload(
				static_cast<void (sf::UI_Text::*)(float, float)>(&sf::UI_Text::setPosition),
				static_cast<void (sf::UI_Text::*)(const sf::Vector2f&)>(&sf::UI_Text::setPosition)
			),
		"setScale", sol::overload(
				static_cast<void (sf::UI_Text::*)(float, float)>(&sf::UI_Text::setScale),
				static_cast<void (sf::UI_Text::*)(const sf::Vector2f&)>(&sf::UI_Text::scale)
			)
	);

	/*
	lua.new_usertype<sf::RenderTexture>("RenderTexture",
		"create",
		"setView",
		"getView",
		"display",
	);
	*/

	lua.new_usertype<sf::RenderTexture>("RenderTexture",
		"", sol::no_constructor,
		"new", [](unsigned int w, unsigned int h) -> sf::RenderTexture*
			{
				sf::RenderTexture* renderTexture = new sf::RenderTexture();
				renderTexture->create(w, h);
				return renderTexture;
			},
		"init", [](sf::RenderTexture *renderTexture, sf::Uint8 alpha)
			{
				renderTexture->clear({0, 0, 0, alpha});
				renderTexture->display();
			},
		"delete", [](sf::RenderTexture *renderTexture)
			{
				delete renderTexture;
			},
		"draw", [](sf::RenderTexture *renderTexture, sf::Sprite &sprite)
			{
				renderTexture->draw(sprite);
			},
		"__gc", sol::destructor([](sf::RenderTexture *renderTexture)
			{
				if(renderTexture) delete renderTexture;
			})
	);

	lua.new_usertype<sf::Texture>("Texture",
		"", sol::no_constructor,
		"delete", [](sf::Texture *texture)
			{
				delete texture;
			},
		"__gc", sol::destructor([](sf::Texture *texture)
			{
				if(texture) delete texture;
			})
	);

	/*
	lua.new_usertype<sf::Sprite>("Sprite",
		"setPosition", static_cast<void (sf::Sprite::*)(float, float)>(&sf::Sprite::setPosition),
		"setRotation", static_cast<void (sf::Sprite::*)(float)>(&sf::Sprite::setRotation),
		"setOrigin", static_cast<void (sf::Sprite::*)(float, float)>(&sf::Sprite::setOrigin),
		"init", [&resources](sf::Sprite &sprite, std::string id, unsigned int wtiles, unsigned int htiles, bool setOrigin)
			{
				sf::Texture *texture;

				if(!resources[id])
				{
					texture = new sf::Texture();
					texture->loadFromFile((std::string(SOURCE_DIR)+"/resources/sprites/"+id).c_str());

					resources[id] = texture;
				}
				else
					texture = resources[id];

				sprite.setTexture(*texture, true);

				auto rect = sprite.getTextureRect();

				float framew = (float)(rect.width)/wtiles;
				float frameh = (float)(rect.height)/htiles;

				sprite.setTextureRect({0, 0, (int)framew, (int)frameh});

				if(setOrigin)
					sprite.setOrigin(framew/2, frameh/2);
			},
		"initFromTarget", [](sf::Sprite &sprite, sf::RenderTexture &target)
			{
				sprite.setTexture(target.getTexture());

				auto rect = sprite.getTextureRect();
				sprite.setOrigin(rect.width/2, rect.height/2);
			},
		"setTextureRect", [](sf::Sprite &sprite, int x, int y, int w, int h)
			{
				sprite.setTextureRect({x, y, w, h});
			},
		"setFrame", [](sf::Sprite &sprite, int framex, int framey)
			{
				auto rect = sprite.getTextureRect();

				sprite.setTextureRect({framex*rect.width, framey*rect.height, rect.width, rect.height});
			},
		"setColor", [](sf::Sprite &sprite, sf::Uint8 r, sf::Uint8 g, sf::Uint8 b, sf::Uint8 a)
			{
				sprite.setColor({r, g, b, a});
			}
	);
	*/

	lua.set_function("draw", [&window](sf::Sprite &sprite)
		{
			window.draw(sprite);
		});

	lua.set_function("draw_a", [&window](sf::Drawable &sprite)
		{
			window.draw(sprite);
		});

	/*
	lua.set_function("draw_box", [&window, &resources](std::string texture_name, float ox, float oy, float ow, float oh)
		{
			//TODO
			sf::Texture *texture;

			if(!resources[texture_name])
			{
				texture = new sf::Texture();
				texture->loadFromFile((std::string(SOURCE_DIR)+"/resources/sprites/"+texture_name).c_str());

				resources[texture_name] = texture;
			}
			else
				texture = resources[texture_name];

			auto old_view = window.getView();
			auto default_view = window.getDefaultView();

			auto size = default_view.getSize();

			window.setView(default_view);

			sf::Sprite sprite;
			sprite.setTexture(*texture);

			auto old_rect = sprite.getTextureRect();
			int tw = old_rect.width/3;
			int th = old_rect.height/3;

			sf::IntRect new_rect;
			new_rect.width = tw;
			new_rect.height = th;

			auto box_width = ow*size.x;
			auto box_height = oh*size.y;

			//top left
			sprite.setTextureRect(new_rect);
			//sprite.setPosition(ox*size.x, oy*size.y);
			window.draw(sprite);

			//top middle
			new_rect.left = tw;
			new_rect.top = th;
			sprite.setTextureRect(new_rect);
			//sprite.setPosition();
			window.draw(sprite);




			window.setView(old_view);

		});
	*/

	/*
	lua.set_function("draw_Mytext", [&font, &window](const std::string &str, float x, float y, float h)
		{
			// save old view
			auto view = window.getView();
			// set view to screen size
			auto newview = window.getDefaultView();
			window.setView(newview);
			// set size of the font
			auto size = newview.getSize();
			sf::UI_Text text{str, font, (unsigned int)(size.y*h)};
			// fix the weird starting offset
			auto lb = text.getLocalBounds();
			auto gb = text.getLocalBounds();

			std::cout << text._baseLineOffset << std::endl;
			//text.setOrigin(lb.left, text._baseLineOffset);
			//text.setScale((size.y*h)/lb.height, (size.y*h)/lb.height);
			text.setPosition(size.x*x, size.y*(1-y));
			
			window.draw(text);
			// return view to normal
			window.setView(view);
		});
	*/

	/*
	lua.set_function("draw_text", [&font, &window](const std::string &str, float x, float y, float h)
		{
			auto view = window.getView();
			auto newview = window.getDefaultView();
			window.setView(newview);

			auto size = newview.getSize();
			int location = size.x*x;

			int totalAdvance = 0;
			int totalWidth = 0;
			int maxHeight = 0;

			//std::cout << str << std::endl;

			for(char c : str)
			{
				auto glyph = font.getGlyph(c, 100, false);

				totalAdvance += glyph.advance;

				//std::cout << " " << glyph.bounds.width;
				totalWidth += glyph.bounds.width;
				maxHeight = maxHeight < glyph.bounds.height ? glyph.bounds.height : maxHeight;
			}

			//std::cout << "\n";

			for(char c : str)
			{
				auto glyph = font.getGlyph(c, 100, false);

				totalAdvance += glyph.advance;

				//std::cout << " " << glyph.advance;
				totalWidth += glyph.bounds.width;
				maxHeight = maxHeight < glyph.bounds.height ? glyph.bounds.height : maxHeight;
			}

			//std::cout << "\n" << totalAdvance << " " << totalWidth << " " << maxHeight << std::endl;

			for(char c : str)
			{
				auto glyph = font.getGlyph(c, 100, false);

				auto advance = glyph.advance;
				auto bounds = glyph.bounds;
				auto rect = glyph.textureRect;

				sf::Sprite sprite;
				sprite.setTexture(font.getTexture(100));
				sprite.setTextureRect(rect);
				sprite.setOrigin(-bounds.left, -bounds.top);
				sprite.setPosition(location, size.y*(1-y));//size.y*(1-h));//(size.y*h)/lb.height);

				window.draw(sprite);
				location += advance;
			}
		});
	*/

	lua["collision_check"] = &collide;

	lua.new_enum<KEYSTATE>("KEYSTATE",
		{
			{"NONE", NONE},
			{"RELEASED", RELEASED},
			{"PRESSED", PRESSED},
			{"HELD", HELD}
		}
	);



	lua["Imgui"] = sol::new_table();
	lua["Imgui"]["ShowDemoWindow"] = [](){ImGui::ShowDemoWindow();};


	lua["Imgui"]["Begin"] = [](const char* name) -> bool
		{
			//ImGui::SetNextWindowSize(ImVec2(550,680), ImGuiCond_FirstUseEver);
			//return ImGui::Begin(name, nullptr);
			
			return ImGui::Begin(name, nullptr, 
				ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_AlwaysAutoResize);			
		};
	lua["Imgui"]["End"] = &ImGui::End;


	lua["Imgui"]["BeginMainMenuBar"] = &ImGui::BeginMainMenuBar;
	lua["Imgui"]["EndMainMenuBar"] = &ImGui::EndMainMenuBar;
	lua["Imgui"]["BeginMenuBar"] = &ImGui::BeginMenuBar;		//requires window to have menubar flag set
	lua["Imgui"]["EndMenuBar"] = &ImGui::EndMenuBar;
	lua["Imgui"]["BeginMenu"] = &ImGui::BeginMenu;				//string, boolean
	lua["Imgui"]["EndMenu"] = &ImGui::EndMenu;
	lua["Imgui"]["BeginChild"] = [](const char* label, float w, float h, bool border) -> bool
		{
			return ImGui::BeginChild(label, {w, h}, border);
		};
	lua["Imgui"]["EndChild"] = &ImGui::EndChild;
	lua["Imgui"]["MenuItem"] = [](const char* label, const char* shortcut, bool selected, bool enabled)
		{
			return ImGui::MenuItem(label, shortcut, selected, enabled);
		};

	lua["Imgui"]["Text"] = [](const char *text)
		{
			ImGui::TextUnformatted(text);
		};
	lua["Imgui"]["InputText"] = [](sol::table output) -> bool
		{
			char buf[128];
			std::string in = output[1];
			strcpy(buf, in.c_str());
			bool ret = ImGui::InputText("Input", buf, 127, ImGuiInputTextFlags_EnterReturnsTrue);
			std::string out = buf;
			output[1] = out;
			return ret;
		};

	lua["Imgui"]["ImageButton"] = [](const sf::Sprite &sprite) -> bool
		{
			return ImGui::ImageButton(sprite);
		};
	lua["Imgui"]["Button"] = [](const char *label) -> bool
		{
			return ImGui::Button(label);
		};

	lua["Imgui"]["ListBoxHeader"] = [](const char* label, int items_count, int height) -> bool
		{
			return ImGui::ListBoxHeader(label, items_count, height);
		};
	lua["Imgui"]["ListBoxFooter"] = &ImGui::ListBoxFooter;
	lua["Imgui"]["Selectable"] = [](const char* label, bool selected) -> bool
		{
			return ImGui::Selectable(label, selected);
		};


	lua["Imgui"]["SliderInt"] = [](const char* label, int curr, int min, int max) -> int
		{
			int val = curr;
			ImGui::SliderInt(label, &val, min, max);
			return val;
		};
	lua["Imgui"]["Checkbox"] = [](const char* label, bool flag) -> bool
		{
			bool check = flag;
			ImGui::Checkbox(label, &check);
			return check;
		};

	lua["Imgui"]["Tooltip"] = [](const char* str)
		{
			ImGui::SetTooltip("%s", str);
		};

	lua["Imgui"]["PushID"] = [](std::string id)
		{
			ImGui::PushID(id.c_str());
		};
	lua["Imgui"]["PopID"] = &ImGui::PopID;

	lua["Imgui"]["SetKeyboardFocusHere"] = &ImGui::SetKeyboardFocusHere;
	lua["Imgui"]["IsItemActive"] = &ImGui::IsItemActive;
	lua["Imgui"]["IsItemHovered"] = []() -> bool
		{
			return ImGui::IsItemHovered();
		};

	lua["Imgui"]["IsKeyPressed"] = &ImGui::IsKeyPressed;


	lua["Imgui"]["GetScrollMaxY"] = &ImGui::GetScrollMaxY;
	lua["Imgui"]["SetScrollY"] = &ImGui::SetScrollY;

	lua["Imgui"]["SameLine"] = &ImGui::SameLine;
	lua["Imgui"]["NewLine"] = &ImGui::NewLine;



	lua.new_enum<KEYS>("KEYS", 
		{
			{"A", sf::Keyboard::A},
			{"B", sf::Keyboard::B},
			{"C", sf::Keyboard::C},
			{"D", sf::Keyboard::D},
			{"E", sf::Keyboard::E},
			{"F", sf::Keyboard::F},
			{"G", sf::Keyboard::G},
			{"H", sf::Keyboard::H},
			{"I", sf::Keyboard::I},
			{"J", sf::Keyboard::J},
			{"K", sf::Keyboard::K},
			{"L", sf::Keyboard::L},
			{"M", sf::Keyboard::M},
			{"N", sf::Keyboard::N},
			{"O", sf::Keyboard::O},
			{"P", sf::Keyboard::P},
			{"Q", sf::Keyboard::Q},
			{"R", sf::Keyboard::R},
			{"S", sf::Keyboard::S},
			{"T", sf::Keyboard::T},
			{"U", sf::Keyboard::U},
			{"V", sf::Keyboard::V},
			{"W", sf::Keyboard::W},
			{"X", sf::Keyboard::X},
			{"Y", sf::Keyboard::Y},
			{"Z", sf::Keyboard::Z},
			{"Num0", sf::Keyboard::Num0},
			{"Num1", sf::Keyboard::Num1},
			{"Num2", sf::Keyboard::Num2},
			{"Num3", sf::Keyboard::Num3},
			{"Num4", sf::Keyboard::Num4},
			{"Num5", sf::Keyboard::Num5},
			{"Num6", sf::Keyboard::Num6},
			{"Num7", sf::Keyboard::Num7},
			{"Num8", sf::Keyboard::Num8},
			{"Num9", sf::Keyboard::Num9},
			{"Escape", sf::Keyboard::Escape},
			{"LControl", sf::Keyboard::LControl},
			{"LShift", sf::Keyboard::LShift},
			{"LAlt", sf::Keyboard::LAlt},
			{"LSystem", sf::Keyboard::LSystem},
			{"RControl", sf::Keyboard::RControl},
			{"RShift", sf::Keyboard::RShift},
			{"RAlt", sf::Keyboard::RAlt},
			{"RSystem", sf::Keyboard::RSystem},
			{"Menu", sf::Keyboard::Menu},
			{"LBracket", sf::Keyboard::LBracket},
			{"RBracket", sf::Keyboard::RBracket},
			{"SemiColon", sf::Keyboard::SemiColon},
			{"Comma", sf::Keyboard::Comma},
			{"Period", sf::Keyboard::Period},
			{"Quote", sf::Keyboard::Quote},
			{"Slash", sf::Keyboard::Slash},
			{"BackSlash", sf::Keyboard::BackSlash},
			{"Tilde", sf::Keyboard::Tilde},
			{"Equal", sf::Keyboard::Equal},
			{"Dash", sf::Keyboard::Dash},
			{"Space", sf::Keyboard::Space},
			{"Return", sf::Keyboard::Return},
			{"BackSpace", sf::Keyboard::BackSpace},
			{"Tab", sf::Keyboard::Tab},
			{"PageUp", sf::Keyboard::PageUp},
			{"PageDown", sf::Keyboard::PageDown},
			{"End", sf::Keyboard::End},
			{"Home", sf::Keyboard::Home},
			{"Insert", sf::Keyboard::Insert},
			{"Delete", sf::Keyboard::Delete},
			{"Add", sf::Keyboard::Add},
			{"Subtract", sf::Keyboard::Subtract},
			{"Multiply", sf::Keyboard::Multiply},
			{"Divide", sf::Keyboard::Divide},
			{"Left", sf::Keyboard::Left},
			{"Right", sf::Keyboard::Right},
			{"Up", sf::Keyboard::Up},
			{"Down", sf::Keyboard::Down},
			{"Numpad0", sf::Keyboard::Numpad0},
			{"Numpad1", sf::Keyboard::Numpad1},
			{"Numpad2", sf::Keyboard::Numpad2},
			{"Numpad3", sf::Keyboard::Numpad3},
			{"Numpad4", sf::Keyboard::Numpad4},
			{"Numpad5", sf::Keyboard::Numpad5},
			{"Numpad6", sf::Keyboard::Numpad6},
			{"Numpad7", sf::Keyboard::Numpad7},
			{"Numpad8", sf::Keyboard::Numpad8},
			{"Numpad9", sf::Keyboard::Numpad9},
			{"F1", sf::Keyboard::F1},
			{"F2", sf::Keyboard::F2},
			{"F3", sf::Keyboard::F3},
			{"F4", sf::Keyboard::F4},
			{"F5", sf::Keyboard::F5},
			{"F6", sf::Keyboard::F6},
			{"F7", sf::Keyboard::F7},
			{"F8", sf::Keyboard::F8},
			{"F9", sf::Keyboard::F9},
			{"F10", sf::Keyboard::F10},
			{"F11", sf::Keyboard::F11},
			{"F12", sf::Keyboard::F12},
			{"F13", sf::Keyboard::F13},
			{"F14", sf::Keyboard::F14},
			{"F15", sf::Keyboard::F15},
			{"Pause", sf::Keyboard::Pause},
			{"KeyCount", sf::Keyboard::KeyCount}
		});
}