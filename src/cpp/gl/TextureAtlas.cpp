
#include "gh/TextureAtlas.hpp"

#include <SFML/Graphics/Sprite.hpp>

namespace gh
{

TextureAtlas::TextureAtlas()
:target(), open_rects(), texture_rects(), path()
{
	auto max_size = sf::Texture::getMaximumSize();
	target.create(max_size, max_size);
	target.clear(sf::Color::Transparent);
	open_rects.push_front({0, 0, static_cast<int>(max_size), static_cast<int>(max_size)});
}

const sf::Texture& TextureAtlas::getTexture()
{
	return target.getTexture();
}

const sf::IntRect& TextureAtlas::getTextureRect(std::string name)
{	
	auto res = texture_rects.find(name);
	if(res != texture_rects.end())
		return res->second;
	else
	{
		sf::Texture texture;
		texture.loadFromFile((path+name).c_str());
		insertTexture(name, texture);

		return texture_rects.find(name)->second;
	}
}

bool compare_rects(const sf::IntRect &r1, const sf::IntRect &r2)
{
	return r1.width * r1.height < r2.width * r2.height;
}

void TextureAtlas::insertTexture(const std::string key, const sf::Texture &texture)
{
	// get the size of the texture to insert
	sf::Vector2u size = texture.getSize();

	// find an open rect that it fits in
	auto it = open_rects.begin();
	for(; it != open_rects.end(); ++it)
		if(it->width > size.x+1 && it->height > size.y+1)
			break;

	// draw the rect into the rect
	sf::Sprite sprite;
	sprite.setTexture(texture);
	sprite.setPosition(it->left+1, it->top+1);
	target.draw(sprite);
	target.display();

	//record location of subtexture rect
	texture_rects[key] = {
		static_cast<int>(it->left+1),
		static_cast<int>(it->top+1),
		static_cast<int>(size.x),
		static_cast<int>(size.y)};

	// partition the open rect
	int rem_w = it->width - (size.x + 1);
	int rem_h = it->height - (size.y + 1);

	// niave split horizontally every time
	sf::IntRect n_rect1{it->left,
					static_cast<int>(it->top + size.y + 1),
					static_cast<int>(size.x + 1),
					rem_h};
	sf::IntRect n_rect2{static_cast<int>(it->left + size.x + 1),
					it->top,
					rem_w,
					it->height};

	//insert new partitioned rects
	open_rects.erase(it);
	open_rects.push_front(n_rect1);
	open_rects.push_front(n_rect2);
	open_rects.sort(compare_rects);

}

void TextureAtlas::setTexturePath(std::string str_path)
{
	path = str_path;
}

} //namespace gh