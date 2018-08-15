#include "ui_text.hpp"


namespace sf
{

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
		_geometryNeedUpdate = true;
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
	/*
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
    m_geometryNeedUpdate = false;

    // Clear the previous geometry
    _vertices.clear();
    _outlineVertices.clear();
    _bounds = FloatRect();


    // Compute values related to the text style
    //bool  isBold             = m_style & Bold;
    //bool  isUnderlined       = m_style & Underlined;
    //bool  isStrikeThrough    = m_style & StrikeThrough;
    //float italicShear        = (m_style & Italic) ? 0.209f : 0.f; // 12 degrees in radians
    //float underlineOffset    = m_font->getUnderlinePosition(m_characterSize);
    //float underlineThickness = m_font->getUnderlineThickness(m_characterSize);

    // Compute the location of the strike through dynamically
    // We use the center point of the lowercase 'x' glyph as the reference
    // We reuse the underline thickness as the thickness of the strike through as well
    //FloatRect xBounds = m_font->getGlyph(L'x', m_characterSize, isBold).bounds;
    //float strikeThroughOffset = xBounds.top + xBounds.height / 2.f;

    // Precompute the variables needed by the algorithm
    float whitespaceWidth = m_font->getGlyph(L' ', m_characterSize, isBold).advance;
    float letterSpacing   = ( whitespaceWidth / 3.f ) * ( m_letterSpacingFactor - 1.f );
    whitespaceWidth      += letterSpacing;
    float lineSpacing     = _font->getLineSpacing(_characterSize) * _lineSpacingFactor;
    float x               = 0.f;
    float y               = static_cast<float>(_characterSize);

    // Create one quad for each character
    float minX = static_cast<float>(_characterSize);
    float minY = static_cast<float>(_characterSize);
    float maxX = 0.f;
    float maxY = 0.f;
    Uint32 prevChar = 0;
    for (std::size_t i = 0; i < m_string.getSize(); ++i)
    {
        Uint32 curChar = m_string[i];

        // Skip the \r char to avoid weird graphical issues
        if (curChar == '\r')
            continue;

        // Apply the kerning offset
        x += m_font->getKerning(prevChar, curChar, m_characterSize);

        // If we're using the underlined style and there's a new line, draw a line
        if (isUnderlined && (curChar == L'\n' && prevChar != L'\n'))
        {
            addLine(m_vertices, x, y, m_fillColor, underlineOffset, underlineThickness);

            if (m_outlineThickness != 0)
                addLine(m_outlineVertices, x, y, m_outlineColor, underlineOffset, underlineThickness, m_outlineThickness);
        }

        // If we're using the strike through style and there's a new line, draw a line across all characters
        if (isStrikeThrough && (curChar == L'\n' && prevChar != L'\n'))
        {
            addLine(m_vertices, x, y, m_fillColor, strikeThroughOffset, underlineThickness);

            if (m_outlineThickness != 0)
                addLine(m_outlineVertices, x, y, m_outlineColor, strikeThroughOffset, underlineThickness, m_outlineThickness);
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
        if (m_outlineThickness != 0)
        {
            const Glyph& glyph = m_font->getGlyph(curChar, m_characterSize, isBold, m_outlineThickness);

            float left   = glyph.bounds.left;
            float top    = glyph.bounds.top;
            float right  = glyph.bounds.left + glyph.bounds.width;
            float bottom = glyph.bounds.top  + glyph.bounds.height;

            // Add the outline glyph to the vertices
            addGlyphQuad(m_outlineVertices, Vector2f(x, y), m_outlineColor, glyph, italicShear, m_outlineThickness);

            // Update the current bounds with the outlined glyph bounds
            minX = std::min(minX, x + left   - italicShear * bottom - m_outlineThickness);
            maxX = std::max(maxX, x + right  - italicShear * top    - m_outlineThickness);
            minY = std::min(minY, y + top    - m_outlineThickness);
            maxY = std::max(maxY, y + bottom - m_outlineThickness);
        }

        // Extract the current glyph's description
        const Glyph& glyph = m_font->getGlyph(curChar, m_characterSize, isBold);

        // Add the glyph to the vertices
        addGlyphQuad(m_vertices, Vector2f(x, y), m_fillColor, glyph, italicShear);

        // Update the current bounds with the non outlined glyph bounds
        if (m_outlineThickness == 0)
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
        addLine(m_vertices, x, y, m_fillColor, underlineOffset, underlineThickness);

        if (m_outlineThickness != 0)
            addLine(m_outlineVertices, x, y, m_outlineColor, underlineOffset, underlineThickness, m_outlineThickness);
    }

    // If we're using the strike through style, add the last line across all characters
    if (isStrikeThrough && (x > 0))
    {
        addLine(m_vertices, x, y, m_fillColor, strikeThroughOffset, underlineThickness);

        if (m_outlineThickness != 0)
            addLine(m_outlineVertices, x, y, m_outlineColor, strikeThroughOffset, underlineThickness, m_outlineThickness);
    }

    // Update the bounding rectangle
    m_bounds.left = minX;
    m_bounds.top = minY;
    m_bounds.width = maxX - minX;
    m_bounds.height = maxY - minY;
    */
}

}