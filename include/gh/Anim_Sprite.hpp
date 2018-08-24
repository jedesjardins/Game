#ifndef ANIM_SPRITE_HPP_
#define ANIM_SPRITE_HPP_

#include <iostream>

#include <SFML/Graphics/Transformable.hpp>
#include <SFML/Graphics/Drawable.hpp>
#include <SFML/Graphics/Texture.hpp>
#include <SFML/Graphics/RenderTarget.hpp>
#include <SFML/Graphics/RenderStates.hpp>
#include <SFML/Graphics/Color.hpp>
#include <SFML/Graphics/Rect.hpp>
#include <SFML/Graphics/Vertex.hpp>
#include <SFML/System/Vector2.hpp>


namespace gh
{
class Anim_Sprite: public sf::Transformable, public sf::Drawable
{
public:
	Anim_Sprite();
	Anim_Sprite(const sf::Texture &texture, const sf::Vector2u &frames = {1, 1}, const sf::Vector2u &frame = {0, 0});
	~Anim_Sprite();

	void setTexture(const sf::Texture &texture);
	const sf::Texture* getTexture() const;

	const sf::IntRect& getTextureRect() const;

	void setFrame(const sf::Vector2u &frame);
	const sf::Vector2u& getFrame();

	void setFrames(const sf::Vector2u &frame);
	const sf::Vector2u& getFrames();

	void setColor(const sf::Color& color);
	const sf::Color& getColor() const;

	sf::FloatRect getLocalBounds() const;
	sf::FloatRect getGlobalBounds() const;

private:
	virtual void draw(sf::RenderTarget& target, sf::RenderStates states) const;
	void resetTextureRect();
	void updatePositions();
	void updateTexCoords();


	const sf::Texture* _texture;
	sf::IntRect _rect;
	sf::Vector2u _frames;
	sf::Vector2u _frame;
	sf::Vertex _vertices[4];
};

} //namespace gh

#endif