
#include <unordered_map>
#include <cstdio>
#include <iostream>
#include <sstream>

#include <SFML/Graphics.hpp>
#include "imgui.h"
#include "imgui-SFML.h"
#include "sol.hpp"

#include "config.h"
#include "input.hpp"
#include "anim_sprite.hpp"
#include "ui_text.hpp"

#include "textureatlas.hpp"

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

	//window.setVerticalSyncEnabled(true);
}

void draw_sprites(sf::RenderWindow &window, sf::AtlasSprite &sprite, sf::AtlasSprite &sprite2)
{
	for(int i = 0; i < 1000; ++i)
	{
		window.draw(sprite);
		window.draw(sprite2);
	}
}

void draw_batch(sf::RenderWindow &window, sf::TextureAtlas &atlas, sf::AtlasSprite &sprite, sf::AtlasSprite &sprite2)
{
	// don't resize VertexArray
	// cache transformations
	sf::SpriteBatch batch;
	batch.addAtlas(atlas);
	batch.resize(8000);
	for(int i = 0; i < 1000; ++i)
	{
		batch.batch(sprite);
		batch.batch(sprite2);
	}
	window.draw(batch);
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

	register_functions(lua);

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

	sf::Text fpsText("", font, 30);
	fpsText.setFillColor(sf::Color::White);

	Input input;

	sf::TextureAtlas atlas;
	atlas.setTexturePath(std::string(SOURCE_DIR)+"/resources/sprites/");

	sf::AtlasSprite sprite;
	sprite.setTexture(atlas.getTexture());
	sprite.setTextureRect(atlas.getTextureRect("man.png"));
	sprite.setFrames({8, 4});
	sprite.setFrame({1, 1});
	sprite.setPosition(100, 75);

	sf::AtlasSprite sprite2;
	sprite2.setTexture(atlas.getTexture());
	sprite2.setTextureRect(atlas.getTextureRect("full_tilesheet.png"));
	sprite2.setFrames({8, 4});
	sprite2.setFrame({1, 1});
	sprite2.setPosition(100, 75);

	sf::SpriteBatch spritebatch;
	spritebatch.batch(sprite2);
	spritebatch.batch(sprite);
	spritebatch.addAtlas(atlas);

	sf::Texture t1, t2;
	t1.loadFromFile((std::string(SOURCE_DIR)+"/resources/sprites/"+"man.png").c_str());
	t2.loadFromFile((std::string(SOURCE_DIR)+"/resources/sprites/"+"full_tilesheet.png").c_str());

	sf::AtlasSprite sprite3;
	sprite3.setTexture(t1);
	sprite3.setFrames({8, 4});
	sprite3.setFrame({1, 1});
	sprite3.setPosition(0, 75);

	sf::AtlasSprite sprite4;
	sprite4.setTexture(t2);
	sprite4.setFrames({8, 4});
	sprite4.setFrame({1, 1});
	sprite4.setPosition(50, 75);

	sf::View view;
	view.setCenter(WINDOW_STATE.screen_dimensions.x/2, WINDOW_STATE.screen_dimensions.y/2);
	view.setSize(WINDOW_STATE.screen_dimensions.x, WINDOW_STATE.screen_dimensions.y);

	window.setView(view);
	
	while (running)
	{
		dt = clock.restart();

		ImGui::SFML::Update(window, dt);
		running &= input.update(window);

		std::stringstream ss;
		ss << "dt: " << std::fixed << std::setprecision(2) << dt.asSeconds()*1000.0f;
		fpsText.setString(ss.str());

		window.clear({0, 0, 0, 255});
		//running &= (bool)update(dt.asSeconds(), input);
		draw_sprites(window, sprite3, sprite4);
		draw_batch(window, atlas, sprite2, sprite);
		
		ImGui::SFML::Render(window);

		window.setView(view);
		window.draw(fpsText);
		window.display();
	}

	for(auto it: resources)
	{
		delete it.second;
	}

	ImGui::SFML::Shutdown();

	return 0;
}