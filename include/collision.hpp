#ifndef COLLISION_HPP_
#define COLLISION_HPP_

#include <SFML/System/Vector2.hpp>
#include <SFML/Graphics/Rect.hpp>
#include <SFML/Graphics/Transform.hpp>

#include <limits>

#include <vector>
#include <utility>
#include <cmath>
#include <iomanip>

#include "sol.hpp"

const double PI = 3.141592653589793238463;

struct Rect
{
	double x;
	double y;
	double w;
	double h;
	double r;
};

std::vector<std::pair<double, double>> 
getPoints(const Rect &, const std::pair<double, double> &);


double 
magnitude(const std::pair<double, double> &vec)
{
	return(sqrt(vec.first*vec.first + vec.second*vec.second));
}

double
overlap(const std::pair<double, double> &axis,
		const std::vector<std::pair<double, double>> &A,
		const std::vector<std::pair<double, double>> &B);

std::pair<double, double>
projectPoints(const std::pair<double, double> &axis,
			  const std::vector<std::pair<double, double>> &A);


void
collide(sol::table t1, sol::table t2, sol::table output)
{
	Rect r1;
	r1.x = t1["x"];
	r1.y = t1["y"];
	r1.w = t1["w"];
	r1.h = t1["h"];
	r1.r = t1["r"];

	Rect r2;
	r2.x = t2["x"];
	r2.y = t2["y"];
	r2.w = t2["w"];
	r2.h = t2["h"];
	r2.r = t2["r"];

	double min_overlap = 1000000;
	double new_overlap;
	std::pair<double, double> min_axis{};
	
	if (r1.r != 0 || r2.r != 0) 
	{
		//do SAT//

		std::vector<std::pair<double, double>> A = getPoints(r1, {t1["rx"], t1["ry"]});
		std::vector<std::pair<double, double>> B = getPoints(r2, {t2["rx"], t2["ry"]});

		std::vector<std::pair<double, double>> axi {
			{
				A[1].first-A[0].first,
				A[1].second-A[0].second
			},
			{
				A[0].first-A[2].first,
				A[0].second-A[2].second
			},
			{
				B[1].first-B[0].first,
				B[1].second-B[0].second
			},
			{
				B[0].first-B[2].first,
				B[0].second-B[2].second
			}
		};

		for (auto axis: axi)
		{
			double mag = magnitude(axis);
			axis.first = axis.first/mag;
			axis.second = axis.second/mag;

			new_overlap = overlap(axis, A, B);

			if (fabs(new_overlap) < fabs(min_overlap))
			{
				min_overlap = new_overlap;
				min_axis = axis;
			}

			if (min_overlap == 0) break;
		}

		output["overlap"] = min_overlap;
		output["x"] = min_axis.first*min_overlap;
		output["y"] = min_axis.second*min_overlap;
	}
	else
	{
		/*
		std::cout << "Square Collision: " << 
		(r1.x - r1.w/2 < r2.x + r2.w/2
		&& r1.x + r1.w/2 > r2.x - r2.w/2
		&& r1.y + r1.h/2 > r2.y - r2.h/2
		&& r1.y - r1.h/2 < r2.y + r2.h/2)
		<< std::endl;
		*/
		
		if (r1.x - r1.w/2 < r2.x + r2.w/2) //r1 to the right of r2
		{
			new_overlap = (r2.x + r2.w/2) - (r1.x - r1.w/2);
			if (fabs(new_overlap) < fabs(min_overlap))
			{
				min_overlap = new_overlap;
				min_axis = {1, 0};
			}
		}
		else
		{
			output["overlap"] = 0;
			return;
		}

		if (r1.x + r1.w/2 > r2.x - r2.w/2) //r1 to the left of r2
		{
			new_overlap = (r2.x - r2.w/2) - (r1.x + r1.w/2);
			if (fabs(new_overlap) < fabs(min_overlap))
			{
				min_overlap = new_overlap;
				min_axis = {1, 0};
			}
		}
		else
		{
			output["overlap"] = 0;
			return;
		}

		if (r1.y + r1.h/2 > r2.y - r2.h/2) //r1 below r2
		{
			new_overlap = (r2.y - r2.h/2) - (r1.y + r1.h/2);
			if (fabs(new_overlap) < fabs(min_overlap))
			{
				min_overlap = new_overlap;
				min_axis = {0, 1};
			}
		}
		else
		{
			output["overlap"] = 0;
			return;
		}

		if (r1.y - r1.h/2 < r2.y + r2.h/2) //r1 above r2
		{
			new_overlap = (r2.y + r2.h/2) - (r1.y - r1.h/2);
			if (fabs(new_overlap) < fabs(min_overlap))
			{
				min_overlap = new_overlap;
				min_axis = {0, 1};
			}
		}
		else
		{
			output["overlap"] = 0;
			return;
		}
	}

	output["overlap"] = min_overlap;
	output["x"] = min_axis.first*min_overlap;
	output["y"] = min_axis.second*min_overlap;
}

std::vector<std::pair<double, double>>
getPoints(const Rect &r, const std::pair<double, double> &vec)
{
	std::vector<std::pair<double, double>> p {
		{r.x-r.w/2-vec.first, r.y+r.h/2-vec.second},
		{r.x+r.w/2-vec.first, r.y+r.h/2-vec.second},
		{r.x-r.w/2-vec.first, r.y-r.h/2-vec.second},
		{r.x+r.w/2-vec.first, r.y-r.h/2-vec.second}
	};

	return {
		{
			(p[0].first * cos(r.r*PI/180) - p[0].second * sin(r.r*PI/180)) + vec.first,
			(p[0].first * sin(r.r*PI/180) + p[0].second * cos(r.r*PI/180)) + vec.second
		},
		{
			(p[1].first * cos(r.r*PI/180) - p[1].second * sin(r.r*PI/180)) + vec.first,
			(p[1].first * sin(r.r*PI/180) + p[1].second * cos(r.r*PI/180)) + vec.second
		},
		{
			(p[2].first * cos(r.r*PI/180) - p[2].second * sin(r.r*PI/180)) + vec.first,
			(p[2].first * sin(r.r*PI/180) + p[2].second * cos(r.r*PI/180)) + vec.second
		},
		{
			(p[3].first * cos(r.r*PI/180) - p[3].second * sin(r.r*PI/180)) + vec.first,
			(p[3].first * sin(r.r*PI/180) + p[3].second * cos(r.r*PI/180)) + vec.second
		}
	};
}

double
overlap(const std::pair<double, double> &axis,
		const std::vector<std::pair<double, double>> &A,
		const std::vector<std::pair<double, double>> &B)
{
	auto a_vals = projectPoints(axis, A);
	double aMin = a_vals.first;
	double aMax = a_vals.second;

	auto b_vals = projectPoints(axis, B);
	double bMin = b_vals.first;
	double bMax = b_vals.second;

	if (aMax < bMin or bMax < aMin)
		return 0;
	else
	{
		if (aMax - bMin < bMax - aMin)
			return bMin - aMax;
		else
			return bMax - aMin;
	}
}

std::pair<double, double>
projectPoints(const std::pair<double, double> &axis,
			  const std::vector<std::pair<double, double>> &A)
{
	double val = (axis.first*A[0].first)+(axis.second*A[0].second);
	double v_min = val;
	double v_max = val;

	for (auto p: A)
	{
		val = (axis.first*p.first)+(axis.second*p.second);
		v_min = v_min < val ? v_min : val;
		v_max = v_max > val ? v_max : val;
	}

	return {v_min, v_max};	
}















/*
 *  Project points onto a unit vector
 */
const std::pair<float, float> projectPoints2(const sf::Vector2f &axis, const std::vector<sf::Vector2f> &points)
{
	float val = axis.x*points[0].x + axis.y*points[0].y; // fix this
	float min = val;
	float max = val;

	for(const sf::Vector2f point: points)
	{
		val = axis.x*point.x + axis.y*point.y;

		min = min < val ? min : val;
		max = max > val ? max : val;
	}

	return {min, max};
}


/*
 *  Each rect describes a collision box, top and left are the center of the collision rect
 *  Each transformable describes the transform on the shape, origin around the entity center,
 *      not the collision center
 */
sf::Vector2f collide2(const sf::FloatRect &r1, const sf::FloatRect &r2,
					  const sf::Transformable &t1 = {}, const sf::Transformable &t2 = {})
{
	if(t1.getRotation() != 0 || t1.getRotation() != 0)
	{
		//SAT
		//get points ordered clockwise from top left
		auto transform1 = t1.getTransform();
		std::vector<sf::Vector2f> points1 = {
			transform1.transformPoint(r1.left-r1.width/2, r1.top+r1.height/2),
			transform1.transformPoint(r1.left+r1.width/2, r1.top+r1.height/2),
			transform1.transformPoint(r1.left+r1.width/2, r1.top-r1.height/2),
			transform1.transformPoint(r1.left-r1.width/2, r1.top-r1.height/2),
		};

		auto transform2 = t2.getTransform();
		std::vector<sf::Vector2f> points2 = {
			transform2.transformPoint(r2.left-r2.width/2, r2.top+r2.height/2),
			transform2.transformPoint(r2.left+r2.width/2, r2.top+r2.height/2),
			transform2.transformPoint(r2.left+r2.width/2, r2.top-r2.height/2),
			transform2.transformPoint(r2.left-r2.width/2, r2.top-r2.height/2),
		};

		//check axis
		std::vector<sf::Vector2f> axi = {
			points1[1] - points1[0],
			points1[0] - points1[3],
			points2[1] - points2[0],
			points2[0] - points2[3],
		};

		float min_overlap = std::numeric_limits<float>::max();
		sf::Vector2f min_axis;

		for(auto axis : axi)
		{	
			//normalize axis
			float length = sqrt(axis.x*axis.x + axis.y*axis.y);
			axis /= length;

			const std::pair<float, float> proj1 = projectPoints2(axis, points1);
			const std::pair<float, float> proj2 = projectPoints2(axis, points2);

			if(proj1.second < proj2.first || proj2.second < proj1.first)
				//found gap, return no overlap

				return {};
			else
			{
				float overlap;
				if(proj1.second - proj2.first < proj2.second - proj1.first)
					overlap = proj2.first - proj1.second;
				else
					overlap = proj2.second - proj1.first;

				if(fabs(overlap) < fabs(min_overlap))
				{
					min_overlap = overlap;
					min_axis = axis;
				}
			}
		}
		return min_axis*min_overlap;
	}
	else
	{
		//vertical axis
		float min1 = r1.top-r1.height/2;
		float max1 = r1.top+r1.height/2;
		float min2 = r2.top-r2.height/2;
		float max2 = r2.top+r2.height/2;
		float vertical_overlap;
		if(max1 < min2 || max2 < min1)
				//found gap, return no overlap
			return {};
		else
		{
			if(max1 - min2 < max2 - min1)
				vertical_overlap = min2 - max1;
			else
				vertical_overlap = max2 - min1;
		}

		//horizontal axis
		min1 = r1.left-r1.width/2;
		max1 = r1.left+r1.width/2;
		min2 = r2.left-r2.width/2;
		max2 = r2.left+r2.width/2;
		float horizontal_overlap;
		if(max1 < min2 || max2 < min1)
				//found gap, return no overlap
			return {};
		else
		{
			if(max1 - min2 < max2 - min1)
				horizontal_overlap = min2 - max1;
			else
				horizontal_overlap = max2 - min1;
		}

		if(vertical_overlap < horizontal_overlap)
			return {0, vertical_overlap};
		else
			return {horizontal_overlap, 0};

	}
}

#endif