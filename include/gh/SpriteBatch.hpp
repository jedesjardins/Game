#ifndef SPRITEBATCH_HPP_
#define SPRITEBATCH_HPP_

#include <SFML/Graphics/Drawable.hpp>
#include <SFML/Graphics/RenderTarget.hpp>
#include <SFML/Graphics/RenderStates.hpp>
#include <SFML/Graphics/VertexArray.hpp>
#include <SFML/Graphics/Vertex.hpp>

#include <gh/TextureAtlas.hpp>
#include <gh/Batchable.hpp>

namespace gh
{

class SpriteBatch: public sf::Drawable
{
public:
	SpriteBatch();

	void resize(std::size_t);

	void batch(Batchable &batch);
	void batch(const sf::Vertex* vertices, std::size_t vertexCount);

	void addAtlas(TextureAtlas &);

private:

	virtual void draw(sf::RenderTarget& target, sf::RenderStates states) const;

	sf::VertexArray m_vertices;
	TextureAtlas *m_atlas;
};

}

#endif