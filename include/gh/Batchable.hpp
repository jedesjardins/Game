#ifndef BATCHABLE_HPP_
#define BATCHABLE_HPP_

namespace gh
{

class SpriteBatch;

class Batchable
{
public:
	virtual ~Batchable() {}

private:
	friend class SpriteBatch;

	virtual void batch(SpriteBatch &) = 0;
};

}

#endif