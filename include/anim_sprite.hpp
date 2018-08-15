#ifndef ANIM_SPRITE
#define ANIM_SPRITE

#include <SFML/Graphics.hpp>
#include <iostream>


namespace sf
{
class Anim_Sprite: public Transformable, public Drawable
{
public:
	Anim_Sprite();
	Anim_Sprite(const Texture &texture, const Vector2u &frames = {1, 1}, const Vector2u &frame = {0, 0});
	~Anim_Sprite();

	void setTexture(const Texture &texture, bool resetRect=true);
	const Texture* getTexture() const;

	const IntRect& getTextureRect() const;

	void setFrame(const Vector2u &frame);
	const Vector2u& getFrame();

	void setFrames(const Vector2u &frame);
	const Vector2u& getFrames();

	void setColor(const Color& color);
	const Color& getColor() const;

	FloatRect getLocalBounds() const;
	FloatRect getGlobalBounds() const;

private:
	virtual void draw(RenderTarget& target, RenderStates states) const;
	void resetTextureRect();
	void updatePositions();
	void updateTexCoords();


	const Texture* _texture;
	IntRect _rect;
	Vector2u _frames;
	Vector2u _frame;
	Vertex _vertices[4];
};
}

#endif