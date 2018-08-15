
#include "random_generator.hpp"


RandomGenerator::RandomGenerator()
:engine(), dist(0, 1)
{}

void RandomGenerator::seed(int seed)
{
	this->engine.seed(seed);
	this->dist.reset();
}

double RandomGenerator::random()
{
	return this->dist(engine);
}