#ifndef ATLASSPRITE_HPP_
#define ATLASSPRITE_HPP_

#include <SFML/Graphics/Transformable.hpp>
#include <SFML/Graphics/Drawable.hpp>
#include <SFML/Graphics/RenderTarget.hpp>
#include <SFML/Graphics/RenderStates.hpp>
#include <SFML/Graphics/Rect.hpp>
#include <SFML/Graphics/Vertex.hpp>
#include <SFML/Graphics/Transform.hpp>
#include <SFML/Graphics/Texture.hpp>
#include <SFML/System/Vector2.hpp>

#include <gh/Batchable.hpp>
#include <gh/SpriteBatch.hpp>


namespace gh
{

class AtlasSprite: public sf::Transformable, public sf::Drawable, public Batchable
{
public:
	AtlasSprite();

	void setTexture(const sf::Texture &texture);
	const sf::Texture* getTexture() const;

	void setTextureRect(const sf::IntRect &rect);
	const sf::IntRect& getTextureRect() const;

	void setFrame(const sf::Vector2u &frame);
	const sf::Vector2u& getFrame() const;

	void setFrames(const sf::Vector2u &frames);
	const sf::Vector2u& getFrames() const;

	sf::FloatRect getLocalBounds() const;
	sf::FloatRect getGlobalBounds() const;

	friend class SpriteBatch;
private:
	virtual void draw(sf::RenderTarget& target, sf::RenderStates states) const;
	virtual void batch(SpriteBatch &);

	void updatePositions();
	void updateTexCoords();
	void updateTransformPositions();

	sf::Vector2u m_frame;
	sf::Vector2u m_frames;
	sf::IntRect m_rect;

	const sf::Texture* m_texture;
	sf::Vertex m_vertices[4];

	//cached vertex transformations
	bool updateTranslatedTexturePoints;
	sf::Vertex m_translated[4];
	sf::Transform cached;
};

} //namespace gh

#endif