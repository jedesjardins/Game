#ifndef RANDOM_GENERATOR_HPP_
#define RANDOM_GENERATOR_HPP_

#include <random>

class RandomGenerator
{
public:

	RandomGenerator();
	void seed(int);
	double random();

private:
	std::default_random_engine engine;
	std::uniform_real_distribution<double> dist;
};

#endif