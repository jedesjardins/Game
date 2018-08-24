#ifndef UI_TEXT
#define UI_TEXT

#include <cmath>
#include <string>
#include <SFML/Graphics/Transformable.hpp>
#include <SFML/Graphics/Drawable.hpp>
#include <SFML/Graphics/RenderTarget.hpp>
#include <SFML/Graphics/RenderStates.hpp>
#include <SFML/Graphics/Rect.hpp>
#include <SFML/Graphics/Vertex.hpp>
#include <SFML/Graphics/VertexArray.hpp>
#include <SFML/Graphics/Transform.hpp>
#include <SFML/Graphics/Font.hpp>
#include <SFML/Graphics/Color.hpp>

#include <SFML/System/Vector2.hpp>
#include <SFML/System/String.hpp>


namespace gh
{

enum TEXT_ALIGNMENT {A_LEFT, A_CENTER, A_RIGHT, A_MAX};

class UI_Text: public sf::Transformable, public sf::Drawable
{
public:
	UI_Text();
	UI_Text(const std::string &string, const sf::Font &font, unsigned int characterSize=30);

	void setString(const sf::String& string);
	const sf::String& getString();

	void setFont(const sf::Font& font);
	const sf::Font& getFont();

	void setCharacterSize(unsigned int size);
	unsigned int getCharacterSize();

	void setAlignment(unsigned int alignment);
	unsigned int getAlignment();

	void setColor(const sf::Color& color);
	const sf::Color& getColor();

	sf::FloatRect getGlobalBounds() const;
	sf::FloatRect getLocalBounds() const;

	mutable float _baseLineOffset = 10;

private:
	virtual void draw(sf::RenderTarget& target, sf::RenderStates states) const;
	void ensureGeometryUpdate() const;

	sf::String _string;
	const sf::Font* _font;
	unsigned int _characterSize;
	unsigned int _alignment;
	float _letterSpacingFactor;
	float _lineSpacingFactor;
	sf::Color _fillColor;

	
	mutable sf::VertexArray _vertices;
	mutable sf::FloatRect _bounds;
	mutable bool _geometryNeedUpdate;

	//unused
	mutable sf::VertexArray _outlineVertices;
	float _outlineThickness = 0.f;
	sf::Color _outlineColor;

};

}


#endif