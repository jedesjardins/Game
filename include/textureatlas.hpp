#ifndef TEXTUREATLAS_HPP
#define TEXTUREATLAS_HPP

#include <SFML/Graphics.hpp>
#include <list>
#include <unordered_map>
#include <string>

namespace sf
{

typedef sf::Rect<unsigned int> UnsRect;


class TextureAtlas
{
public:
	TextureAtlas();

	const Texture& getTexture();
	const IntRect& getTextureRect(std::string);

	void setTexturePath(std::string);

private:
	void insertTexture(std::string, const Texture &);

	RenderTexture target;
	std::list<IntRect> open_rects;
	std::unordered_map<std::string, IntRect> texture_rects;
	std::string path;
};


class SpriteBatch;

class Batchable
{
public:
	virtual ~Batchable() {}

private:
	friend class SpriteBatch;

	virtual void batch(SpriteBatch &) = 0;
};

class SpriteBatch: public Drawable
{
public:
	SpriteBatch();

	void resize(std::size_t);

	void batch(Batchable &batch);
	void batch(const Vertex* vertices, std::size_t vertexCount);

	void addAtlas(TextureAtlas &);

private:

	virtual void draw(RenderTarget& target, RenderStates states) const;

	VertexArray m_vertices;
	TextureAtlas *m_atlas;
};

class AtlasSprite: public Transformable, public Drawable, public Batchable
{
public:
	AtlasSprite();

	void setTexture(const Texture &texture);
	const Texture* getTexture() const;

	void setTextureRect(const IntRect &rect);
	const IntRect& getTextureRect() const;

	void setFrame(const Vector2u &frame);
	const Vector2u& getFrame() const;

	void setFrames(const Vector2u &frames);
	const Vector2u& getFrames() const;

	FloatRect getLocalBounds() const;
	FloatRect getGlobalBounds() const;

	friend class SpriteBatch;
private:
	virtual void draw(RenderTarget& target, RenderStates states) const;
	virtual void batch(SpriteBatch &);

	void updatePositions();
	void updateTexCoords();
	void updateTransformPositions();

	Vector2u m_frame;
	Vector2u m_frames;
	IntRect m_rect;

	const Texture* m_texture;
	Vertex m_vertices[4];

	//cached vertex transformations
	bool updateTranslatedTexturePoints;
	Vertex m_translated[4];
	Transform cached;
};

}
#endif