
#include <SFML/Graphics/Sprite.hpp>

#include "gh/Batchable.hpp"
#include "gh/AtlasSprite.hpp"
#include "gh/SpriteBatch.hpp"
#include "gh/TextureAtlas.hpp"

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






AtlasSprite::AtlasSprite()
:m_frame(), m_frames(1, 1), m_rect(), m_texture()
{
}


void AtlasSprite::setTexture(const sf::Texture &texture)
{
	if(!m_texture && (m_rect == sf::IntRect()))
		setTextureRect(sf::IntRect(0, 0, texture.getSize().x, texture.getSize().y));

	m_texture = &texture;
}
const sf::Texture* AtlasSprite::getTexture() const
{
	return m_texture;
}

void AtlasSprite::setTextureRect(const sf::IntRect &rect)
{
	if(m_rect != rect)
	{
		m_rect = rect;
		updatePositions();
		updateTexCoords();
	}
	
}
const sf::IntRect& AtlasSprite::getTextureRect() const
{
	return m_rect;
}

void AtlasSprite::setFrames(const sf::Vector2u &frames)
{
	if(m_frames != frames)
	{
		m_frames = frames;
		updatePositions();
		updateTexCoords();
	}
}
const sf::Vector2u& AtlasSprite::getFrames() const
{
	return m_frames;
}

void AtlasSprite::setFrame(const sf::Vector2u &frame)
{
	if(m_frame != frame)
	{
		m_frame = frame;
		updateTexCoords();
	}
}
const sf::Vector2u& AtlasSprite::getFrame() const
{
	return m_frame;
}

sf::FloatRect AtlasSprite::getLocalBounds() const
{
	float width = static_cast<float>(std::abs(m_rect.width));
	float height = static_cast<float>(std::abs(m_rect.height));

	return sf::FloatRect(0.f, 0.f, width/m_frames.x, height/m_frames.y);
}
sf::FloatRect AtlasSprite::getGlobalBounds() const
{
	return getTransform().transformRect(getLocalBounds());
}

void AtlasSprite::draw(sf::RenderTarget& target, sf::RenderStates states) const
{
	if (m_texture)
	{
		states.transform *= getTransform();
		states.texture = m_texture;
		target.draw(m_vertices, 4, sf::TriangleStrip, states);
	}
}

void AtlasSprite::batch(SpriteBatch &spritebatch)
{
	//TODO: manipulate them with transform

	updateTransformPositions();
	spritebatch.batch(m_translated, 4);
}

void AtlasSprite::updatePositions()
{
	sf::FloatRect bounds = getLocalBounds();

	m_vertices[0].position = sf::Vector2f(0, 0);
	m_vertices[1].position = sf::Vector2f(0, bounds.height);
	m_vertices[2].position = sf::Vector2f(bounds.width, 0);
	m_vertices[3].position = sf::Vector2f(bounds.width, bounds.height);
}
void AtlasSprite::updateTexCoords()
{
	sf::FloatRect bounds = getLocalBounds();

	float left = bounds.width * m_frame.x + m_rect.left;
	float right = left + bounds.width;
	float top = bounds.height * m_frame.y + m_rect.top;
	float bottom = top + bounds.height;

	m_vertices[0].texCoords = sf::Vector2f(left, top);
	m_vertices[1].texCoords = sf::Vector2f(left, bottom);
	m_vertices[2].texCoords = sf::Vector2f(right, top);
	m_vertices[3].texCoords = sf::Vector2f(right, bottom);


	updateTranslatedTexturePoints = true;
}

void AtlasSprite::updateTransformPositions()
{
	auto transform = getTransform();

	if(cached != transform)
	{
		m_translated[0].position = transform.transformPoint(m_vertices[0].position);
		m_translated[1].position = transform.transformPoint(m_vertices[1].position);
		m_translated[2].position = transform.transformPoint(m_vertices[2].position);
		m_translated[3].position = transform.transformPoint(m_vertices[3].position);
		cached = transform;
	}

	if(updateTranslatedTexturePoints)
	{
		m_translated[0].texCoords = m_vertices[0].texCoords;
		m_translated[1].texCoords = m_vertices[1].texCoords;
		m_translated[2].texCoords = m_vertices[2].texCoords;
		m_translated[3].texCoords = m_vertices[3].texCoords;
		updateTranslatedTexturePoints = false;
	}
}



SpriteBatch::SpriteBatch()
{
	m_vertices.setPrimitiveType(sf::Quads);
}

void SpriteBatch::resize(std::size_t vertexCount)
{
	m_vertices.resize(vertexCount);
}

void SpriteBatch::batch(Batchable &sprite)
{
	sprite.batch(*this);
}
void SpriteBatch::batch(const sf::Vertex* vertices, std::size_t vertexCount)
{
	/*
	for (std::size_t i = 0; i < vertexCount; ++i)
	{
		m_vertices.append(vertices[i]);
	}
	*/

	m_vertices.append(vertices[0]);
	m_vertices.append(vertices[1]);
	m_vertices.append(vertices[3]);
	m_vertices.append(vertices[2]);
}

void SpriteBatch::draw(sf::RenderTarget& target, sf::RenderStates states) const
{
	states.texture = &m_atlas->getTexture();
	target.draw(m_vertices, states);
}

void SpriteBatch::addAtlas(TextureAtlas &atlas)
{
	m_atlas = &atlas;
}

}


