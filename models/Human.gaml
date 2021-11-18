/**
* Name: Human
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Human

import "Id.gaml"

species Human skills: [moving, fipa] parent: Identifiable {
	
	float reach <- 2.0;
	float intoxication <- 0.0;
	
	agent target <- nil;
	
	bool can_reach(point p) {
		return p != nil and (location distance_to p) < reach;
	}
	
	bool can_reach(agent a) {
		return a != nil and (location distance_to a) < reach;
	}
	
	bool at_target {
		return can_reach(target);
	}
	
	reflex stumble when: intoxication > 0 {
		do move speed: intoxication heading: rnd(0.0, 360.0);
	}
	
	reflex move_to_target when: target != nil {
		do goto target:target;
	}
	
}