
#include "gh/AtlasSprite.hpp"

namespace gh
{

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

} //namespace gh