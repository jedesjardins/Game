
#include "gh/SpriteBatch.hpp"

namespace gh
{

SpriteBatch::SpriteBatch()
{
	m_vertices.setPrimitiveType(sf::Quads);
}

void SpriteBatch::resize(std::size_t vertexCount)
{
	m_vertices.resize(vertexCount);
}

void SpriteBatch::batch(Batchable &sprite)
{
	sprite.batch(*this);
}
void SpriteBatch::batch(const sf::Vertex* vertices, std::size_t vertexCount)
{
	/*
	for (std::size_t i = 0; i < vertexCount; ++i)
	{
		m_vertices.append(vertices[i]);
	}
	*/

	m_vertices.append(vertices[0]);
	m_vertices.append(vertices[1]);
	m_vertices.append(vertices[3]);
	m_vertices.append(vertices[2]);
}

void SpriteBatch::draw(sf::RenderTarget& target, sf::RenderStates states) const
{
	states.texture = &m_atlas->getTexture();
	target.draw(m_vertices, states);
}

void SpriteBatch::addAtlas(TextureAtlas &atlas)
{
	m_atlas = &atlas;
}

} //namespace gh