#ifndef UI_TEXT
#define UI_TEXT

#include <SFML/Graphics.hpp>

namespace sf
{

enum TEXT_ALIGNMENT {A_LEFT, A_CENTER, A_RIGHT, A_MAX};

class UI_Text: public Transformable, public Drawable
{
public:
	UI_Text();
	UI_Text(const String &string, const Font &font, unsigned int characterSize=30);

	void setString(const String& string);
	const String& getString();

	void setFont(const Font& font);
	const Font& getFont();

	void setCharacterSize(unsigned int size);
	unsigned int getCharacterSize();

	void setAlignment(unsigned int alignment);
	unsigned int getAlignment();

	void setColor(const Color& color);
	const Color& getColor();


private:
	virtual void draw(RenderTarget& target, RenderStates states) const;
	void ensureGeometryUpdate() const;

	String _string;
	const Font* _font;
	unsigned int _characterSize;
	unsigned int _alignment;
	float _letterSpacingFactor;
	float _lineSpacingFactor;
	Color _fillColor;

	bool _geometryNeedUpdate;
	mutable VertexArray _vertices;


};

}


#endif