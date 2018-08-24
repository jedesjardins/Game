#ifndef TEXTUREATLAS_HPP_
#define TEXTUREATLAS_HPP_

#include <list>
#include <unordered_map>
#include <string>

#include <SFML/Graphics/RenderTexture.hpp>
#include <SFML/Graphics/Texture.hpp>
#include <SFML/Graphics/Rect.hpp>

#include "gh/Batchable.hpp"

namespace gh
{

class TextureAtlas
{
public:
	TextureAtlas();

	const sf::Texture& getTexture();
	const sf::IntRect& getTextureRect(std::string);

	void setTexturePath(std::string);

private:
	void insertTexture(std::string, const sf::Texture &);

	sf::RenderTexture target;
	std::list<sf::IntRect> open_rects;
	std::unordered_map<std::string, sf::IntRect> texture_rects;
	std::string path;
};

} //namespace gh

#endif