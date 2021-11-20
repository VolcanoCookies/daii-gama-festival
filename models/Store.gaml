/**
* Name: Store
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Store

import "Base.gaml"

species Store parent: Base {
	
	init {
		if flip(0.3) {
			has_food <- true;
			has_water <- true;
		} else {
			has_food <- flip(0.5);
			has_water <- !has_food;
		}
	}
	
	bool has_food;
	bool has_water;
	
	aspect base {
		draw cube(2) color: #green;
	}
	
}
