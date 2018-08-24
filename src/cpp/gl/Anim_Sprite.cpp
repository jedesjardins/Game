
#include "gh/Anim_Sprite.hpp"

namespace gh
{

Anim_Sprite::Anim_Sprite()
:_texture(NULL), _rect(), _frames(1, 1), _frame()
{
}

Anim_Sprite::Anim_Sprite(const sf::Texture &texture, const sf::Vector2u &frames, const sf::Vector2u &frame)
:_texture(NULL), _rect(),  _frames(frames), _frame(frame)
{
	setTexture(texture);
}

Anim_Sprite::~Anim_Sprite()
{
}

void Anim_Sprite::setTexture(const sf::Texture &texture)
{
	//bool reset = (resetRect || (!_texture && (_rect == IntRect()))) && _texture && !(texture.getSize() == _texture->getSize());
	_texture = &texture;

	//if(reset)
		resetTextureRect();
}

const sf::Texture* Anim_Sprite::getTexture() const
{
	return this->_texture;
}


void Anim_Sprite::setFrames(const sf::Vector2u &frames)
{
	if(frames.x == 0 || frames.y == 0 || frames == _frames)
		return;

	_frames = frames;
	resetTextureRect();
}

const sf::Vector2u& Anim_Sprite::getFrames()
{
	return _frames;
}

void Anim_Sprite::setFrame(const sf::Vector2u &frame)
{
	if(frame == _frame)
		return;

	_frame = frame;
	resetTextureRect();
}

const sf::Vector2u& Anim_Sprite::getFrame()
{
	return _frame;
}


void Anim_Sprite::resetTextureRect()
{
	if(!_texture) return;
	int width = _texture->getSize().x / _frames.x;
	int height = _texture->getSize().y / _frames.y;

	setOrigin(((float)width)/2, ((float)height)/2);

	const sf::IntRect rectangle{
		static_cast<int>(_frame.x*width),
		static_cast<int>(_frame.y*height),
		width,
		height
	};

	if (rectangle != _rect)
	{
		_rect = rectangle;
		updatePositions();
		updateTexCoords();
	}
}

const sf::IntRect& Anim_Sprite::getTextureRect() const
{
	return this->_rect;
}

void Anim_Sprite::setColor(const sf::Color& color)
{
	// Update the vertices' color
	_vertices[0].color = color;
	_vertices[1].color = color;
	_vertices[2].color = color;
	_vertices[3].color = color;
}

const sf::Color& Anim_Sprite::getColor() const
{
	return _vertices[0].color;
}


void Anim_Sprite::draw(sf::RenderTarget& target, sf::RenderStates states) const
{
	if (_texture)
	{
		states.transform *= getTransform();
		states.texture = _texture;
		target.draw(_vertices, 4, sf::TriangleStrip, states);
	}
}

sf::FloatRect Anim_Sprite::getLocalBounds() const
{
	float width = static_cast<float>(std::abs(_rect.width));
	float height = static_cast<float>(std::abs(_rect.height));

	return sf::FloatRect(0.f, 0.f, width, height);
}

sf::FloatRect Anim_Sprite::getGlobalBounds() const
{
	return getTransform().transformRect(getLocalBounds());
}

void Anim_Sprite::updatePositions()
{
	sf::FloatRect bounds = getLocalBounds();

	_vertices[0].position = sf::Vector2f(0, 0);
	_vertices[1].position = sf::Vector2f(0, bounds.height);
	_vertices[2].position = sf::Vector2f(bounds.width, 0);
	_vertices[3].position = sf::Vector2f(bounds.width, bounds.height);
}

void Anim_Sprite::updateTexCoords()
{
	float left   = static_cast<float>(_rect.left);
	float right  = left + _rect.width;
	float top    = static_cast<float>(_rect.top);
	float bottom = top + _rect.height;

	_vertices[0].texCoords = sf::Vector2f(left, top);
	_vertices[1].texCoords = sf::Vector2f(left, bottom);
	_vertices[2].texCoords = sf::Vector2f(right, top);
	_vertices[3].texCoords = sf::Vector2f(right, bottom);
}

}
