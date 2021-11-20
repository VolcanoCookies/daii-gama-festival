/**
* Name: Human
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Human

import "Base.gaml"
import "Store.gaml"
import "Center.gaml"

global {
	geometry world_plane <- square(100) translated_by {50, 50};
}

species Human skills: [moving, fipa] parent: Base virtual: true {
	
	float reach <- 2.0;
	float reachable_from <- 0.0;
	float intoxication <- 0.0;
	
	unknown target <- nil;
	
	bool can_reach(unknown u) {
		
		if u = nil or (agent(u) != nil and dead(agent(u))) {
			return false;
		} else if u is point {
			return (location distance_to point(u)) < reach;
		} else if (u as Human) != nil {
			float k <- Human(u).reachable_from;
			return (location distance_to point(u)) < reach + k; 
		} else if (u as agent) != nil {
			return (location distance_to point(u)) < reach;
		} else if u is geometry {
			return (location intersects geometry(u));
		} else {
			return false;
		}
		
	}
	
	bool at_target {
		return target != nil and can_reach(target);
	}
	
	geometry bounds { 
		if target is geometry and at_target() {
			return geometry(target);
		} else {
			return host.world.shape;
		}
	}
	
	reflex move_to_target when: target != nil and !at_target() {
		do goto target: target;
	}
	
	reflex stumble when: intoxication > 0 {
		do wander speed: intoxication bounds: bounds();
	}
	
	reflex separate {
		list too_close <- peers at_distance 1.75;
		if !empty(too_close) {
			point center <- mean(too_close collect each.location) as point;
			float angle <- location towards center;
			do move heading: angle speed: -0.5 bounds: bounds();
		}
	}
	
	reflex avoid_obstacle {
		list obstacles <- (list(Store) + list(Center)) at_distance (reach * 3);
		loop o over: obstacles {
			if o != target {
				float angle <- location direction_to o;
				do move heading: angle speed: -0.5 bounds: bounds();	
			}
		}
	}
	
}