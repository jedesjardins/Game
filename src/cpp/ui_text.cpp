#include "ui_text.hpp"

#include <iostream>

namespace
{
    // Add an underline or strikethrough line to the vertex array
    void addLine(sf::VertexArray& vertices, float lineLength, float lineTop, const sf::Color& color, float offset, float thickness, float outlineThickness = 0)
    {
        float top = std::floor(lineTop + offset - (thickness / 2) + 0.5f);
        float bottom = top + std::floor(thickness + 0.5f);

        vertices.append(sf::Vertex(sf::Vector2f(-outlineThickness,             top    - outlineThickness), color, sf::Vector2f(1, 1)));
        vertices.append(sf::Vertex(sf::Vector2f(lineLength + outlineThickness, top    - outlineThickness), color, sf::Vector2f(1, 1)));
        vertices.append(sf::Vertex(sf::Vector2f(-outlineThickness,             bottom + outlineThickness), color, sf::Vector2f(1, 1)));
        vertices.append(sf::Vertex(sf::Vector2f(-outlineThickness,             bottom + outlineThickness), color, sf::Vector2f(1, 1)));
        vertices.append(sf::Vertex(sf::Vector2f(lineLength + outlineThickness, top    - outlineThickness), color, sf::Vector2f(1, 1)));
        vertices.append(sf::Vertex(sf::Vector2f(lineLength + outlineThickness, bottom + outlineThickness), color, sf::Vector2f(1, 1)));
    }

    // Add a glyph quad to the vertex array
    void addGlyphQuad(sf::VertexArray& vertices, sf::Vector2f position, const sf::Color& color, const sf::Glyph& glyph, float italicShear, float outlineThickness = 0)
    {
        float padding = 1.0;

        float left   = glyph.bounds.left - padding;
        float top    = glyph.bounds.top - padding;
        float right  = glyph.bounds.left + glyph.bounds.width + padding;
        float bottom = glyph.bounds.top  + glyph.bounds.height + padding;

        float u1 = static_cast<float>(glyph.textureRect.left) - padding;
        float v1 = static_cast<float>(glyph.textureRect.top) - padding;
        float u2 = static_cast<float>(glyph.textureRect.left + glyph.textureRect.width) + padding;
        float v2 = static_cast<float>(glyph.textureRect.top  + glyph.textureRect.height) + padding;

        vertices.append(sf::Vertex(sf::Vector2f(position.x + left  - italicShear * top    - outlineThickness, position.y + top    - outlineThickness), color, sf::Vector2f(u1, v1)));
        vertices.append(sf::Vertex(sf::Vector2f(position.x + right - italicShear * top    - outlineThickness, position.y + top    - outlineThickness), color, sf::Vector2f(u2, v1)));
        vertices.append(sf::Vertex(sf::Vector2f(position.x + left  - italicShear * bottom - outlineThickness, position.y + bottom - outlineThickness), color, sf::Vector2f(u1, v2)));
        vertices.append(sf::Vertex(sf::Vector2f(position.x + left  - italicShear * bottom - outlineThickness, position.y + bottom - outlineThickness), color, sf::Vector2f(u1, v2)));
        vertices.append(sf::Vertex(sf::Vector2f(position.x + right - italicShear * top    - outlineThickness, position.y + top    - outlineThickness), color, sf::Vector2f(u2, v1)));
        vertices.append(sf::Vertex(sf::Vector2f(position.x + right - italicShear * bottom - outlineThickness, position.y + bottom - outlineThickness), color, sf::Vector2f(u2, v2)));
    }
}

namespace sf
{

UI_Text::UI_Text():
	_string(),
	_font(),
	_characterSize(30),
	_alignment(0),
	_letterSpacingFactor(1.f),
	_lineSpacingFactor  (1.f),
	_fillColor          (255, 255, 255),
	_vertices           (Triangles),
	_bounds             (),
	_geometryNeedUpdate (true),
	_outlineVertices    (Triangles),
	_outlineThickness   (0),
	_outlineColor       (0, 0, 0)
{
	auto lb = getLocalBounds();
	setOrigin(lb.left, _baseLineOffset);
}

UI_Text::UI_Text(const std::string& string, const Font& font, unsigned int characterSize):
	_string(string),
	_font(&font),
	_characterSize(characterSize),
	_alignment(0),
	_letterSpacingFactor(1.f),
	_lineSpacingFactor  (1.f),
	_fillColor          (255, 255, 255),
	_vertices           (Triangles),
	_bounds             (),
	_geometryNeedUpdate (true),
	_outlineVertices    (Triangles),
	_outlineThickness   (0),
	_outlineColor       (0, 0, 0)
{
	auto lb = getLocalBounds();
	setOrigin(lb.left, _baseLineOffset);
}

void UI_Text::setString(const String& string)
{
	if(_string != string)
	{
		_string = string;
		_geometryNeedUpdate = true;
	}
}

const String& UI_Text::getString()
{
	return _string;
}

void UI_Text::setFont(const Font& font)
{
	if(_font != &font)
	{
		_font = &font;
		_geometryNeedUpdate = true;
	}
}

const Font& UI_Text::getFont()
{
	return *_font;
}

void UI_Text::setCharacterSize(unsigned int size)
{
	if(_characterSize != size)
	{
		_characterSize = size;
		_geometryNeedUpdate = true;
	}
}

unsigned int UI_Text::getCharacterSize()
{
	return _characterSize;
}

void UI_Text::setAlignment(unsigned int alignment)
{
	if(_alignment != alignment && alignment < A_MAX)
	{
		_alignment = alignment;
	}
}

unsigned int UI_Text::getAlignment()
{
	return _alignment;
}

void UI_Text::setColor(const Color& color)
{
	if (color != _fillColor)
	{
		_fillColor = color;

		// Change vertex colors directly, no need to update whole geometry
		// (if geometry is updated anyway, we can skip this step)
		if (!_geometryNeedUpdate)
		{
			for (std::size_t i = 0; i < _vertices.getVertexCount(); ++i)
				_vertices[i].color = _fillColor;
		}
	}
}

const Color& UI_Text::getColor()
{
	return _fillColor;
}

FloatRect UI_Text::getLocalBounds() const
{
    ensureGeometryUpdate();

    return _bounds;
}

FloatRect UI_Text::getGlobalBounds() const
{
    return getTransform().transformRect(getLocalBounds());
}














void UI_Text::draw(RenderTarget& target, RenderStates states) const
{
	if (_font)
	{
		ensureGeometryUpdate();

		states.transform *= getTransform();
		states.texture = &_font->getTexture(_characterSize);

		// Only draw the outline if there is something to draw
		/*
		if (m_outlineThickness != 0)
			target.draw(_outlineVertices, states);
		*/

		target.draw(_vertices, states);
	}
}

void UI_Text::ensureGeometryUpdate() const
{
	if (!_font)
		return;

	if (_string.isEmpty())
		return;

	// Do nothing, if geometry has not changed and the font texture has not changed
	if (!_geometryNeedUpdate)// && _font->getTexture(_characterSize).m_cacheId == _fontTextureId)
		return;

	// Save the current fonts texture id
	//m_fontTextureId = m_font->getTexture(m_characterSize).m_cacheId;

	// Mark geometry as updated
	_geometryNeedUpdate = false;

	// Clear the previous geometry
	_vertices.clear();
	_outlineVertices.clear();
	_bounds = FloatRect();


	// Compute values related to the text style
	bool  isBold             = false;//m_style & Bold;
	bool  isUnderlined       = false;//m_style & Underlined;
	bool  isStrikeThrough    = false;//m_style & StrikeThrough;
	float italicShear        = false;//(m_style & Italic) ? 0.209f : 0.f; // 12 degrees in radians
	float underlineOffset    = _font->getUnderlinePosition(_characterSize);
	float underlineThickness = _font->getUnderlineThickness(_characterSize);

	// Compute the location of the strike through dynamically
	// We use the center point of the lowercase 'x' glyph as the reference
	// We reuse the underline thickness as the thickness of the strike through as well
	FloatRect xBounds = _font->getGlyph(L'x', _characterSize, isBold).bounds;
	float strikeThroughOffset = xBounds.top + xBounds.height / 2.f;

	// Precompute the variables needed by the algorithm
	float whitespaceWidth = _font->getGlyph(L' ', _characterSize, isBold).advance;
	float letterSpacing   = ( whitespaceWidth / 3.f ) * ( _letterSpacingFactor - 1.f );
	whitespaceWidth      += letterSpacing;
	float lineSpacing     = _font->getLineSpacing(_characterSize) * _lineSpacingFactor;
	float x               = 0.f;
	float y               = static_cast<float>(_characterSize);
	_baseLineOffset = y;

	// Create one quad for each character
	float minX = static_cast<float>(_characterSize);
	float minY = static_cast<float>(_characterSize);
	float maxX = 0.f;
	float maxY = 0.f;
	Uint32 prevChar = 0;
	for (std::size_t i = 0; i < _string.getSize(); ++i)
	{
		Uint32 curChar = _string[i];

		// Skip the \r char to avoid weird graphical issues
		if (curChar == '\r')
			continue;

		// Apply the kerning offset
		x += _font->getKerning(prevChar, curChar, _characterSize);

		// If we're using the underlined style and there's a new line, draw a line
		if (isUnderlined && (curChar == L'\n' && prevChar != L'\n'))
		{
			addLine(_vertices, x, y, _fillColor, underlineOffset, underlineThickness);

			if (_outlineThickness != 0)
				addLine(_outlineVertices, x, y, _outlineColor, underlineOffset, underlineThickness, _outlineThickness);
		}

		// If we're using the strike through style and there's a new line, draw a line across all characters
		if (isStrikeThrough && (curChar == L'\n' && prevChar != L'\n'))
		{
			addLine(_vertices, x, y, _fillColor, strikeThroughOffset, underlineThickness);

			if (_outlineThickness != 0)
				addLine(_outlineVertices, x, y, _outlineColor, strikeThroughOffset, underlineThickness, _outlineThickness);
		}

		prevChar = curChar;

		// Handle special characters
		if ((curChar == L' ') || (curChar == L'\n') || (curChar == L'\t'))
		{
			// Update the current bounds (min coordinates)
			minX = std::min(minX, x);
			minY = std::min(minY, y);

			switch (curChar)
			{
				case L' ':  x += whitespaceWidth;     break;
				case L'\t': x += whitespaceWidth * 4; break;
				case L'\n': y += lineSpacing; x = 0;  break;
			}

			// Update the current bounds (max coordinates)
			maxX = std::max(maxX, x);
			maxY = std::max(maxY, y);

			// Next glyph, no need to create a quad for whitespace
			continue;
		}

		// Apply the outline
		if (_outlineThickness != 0)
		{
			const Glyph& glyph = _font->getGlyph(curChar, _characterSize, isBold, _outlineThickness);

			float left   = glyph.bounds.left;
			float top    = glyph.bounds.top;
			float right  = glyph.bounds.left + glyph.bounds.width;
			float bottom = glyph.bounds.top  + glyph.bounds.height;

			// Add the outline glyph to the vertices
			addGlyphQuad(_outlineVertices, Vector2f(x, y), _outlineColor, glyph, italicShear, _outlineThickness);

			// Update the current bounds with the outlined glyph bounds
			minX = std::min(minX, x + left   - italicShear * bottom - _outlineThickness);
			maxX = std::max(maxX, x + right  - italicShear * top    - _outlineThickness);
			minY = std::min(minY, y + top    - _outlineThickness);
			maxY = std::max(maxY, y + bottom - _outlineThickness);
		}

		// Extract the current glyph's description
		const Glyph& glyph = _font->getGlyph(curChar, _characterSize, isBold);

		// Add the glyph to the vertices
		addGlyphQuad(_vertices, Vector2f(x, y), _fillColor, glyph, italicShear);

		// Update the current bounds with the non outlined glyph bounds
		if (_outlineThickness == 0)
		{
			float left   = glyph.bounds.left;
			float top    = glyph.bounds.top;
			float right  = glyph.bounds.left + glyph.bounds.width;
			float bottom = glyph.bounds.top  + glyph.bounds.height;

			minX = std::min(minX, x + left  - italicShear * bottom);
			maxX = std::max(maxX, x + right - italicShear * top);
			minY = std::min(minY, y + top);
			maxY = std::max(maxY, y + bottom);
		}

		// Advance to the next character
		x += glyph.advance + letterSpacing;
	}

	// If we're using the underlined style, add the last line
	if (isUnderlined && (x > 0))
	{
		addLine(_vertices, x, y, _fillColor, underlineOffset, underlineThickness);

		if (_outlineThickness != 0)
			addLine(_outlineVertices, x, y, _outlineColor, underlineOffset, underlineThickness, _outlineThickness);
	}

	// If we're using the strike through style, add the last line across all characters
	if (isStrikeThrough && (x > 0))
	{
		addLine(_vertices, x, y, _fillColor, strikeThroughOffset, underlineThickness);

		if (_outlineThickness != 0)
			addLine(_outlineVertices, x, y, _outlineColor, strikeThroughOffset, underlineThickness, _outlineThickness);
	}

	// Update the bounding rectangle
	_bounds.left = minX;
	_bounds.top = minY;
	_bounds.width = maxX - minX;
	_bounds.height = maxY - minY;
}

}