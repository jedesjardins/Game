#ifndef COLLISION_HPP_
#define COLLISION_HPP_

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

#endif