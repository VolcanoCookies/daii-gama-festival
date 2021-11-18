/**
* Name: Festival
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Festival

/* Insert your model definition here */

import "Guest.gaml"
import "Guard.gaml"
import "Store.gaml"
import "Center.gaml"
import "Gate.gaml"
import "DanceFloor.gaml"

global {

	int GUEST_COUNT <- 50 const: true;
	int GUARD_COUNT <- 5 const: true;
	int STORE_COUNT <- 3 const: true;
	int CENTER_COUNT <- 2 const: true;
	int GATE_COUNT <- 1 const: true;
	int DANCE_FLOOR_COUNT <- 2 const: true;

	init {
		
		create Store number: STORE_COUNT; 
		create Center number: CENTER_COUNT;
		create DanceFloor number: DANCE_FLOOR_COUNT;
		create Gate number: GATE_COUNT;
		create Guard number: GUARD_COUNT;
		create Guest number: GUEST_COUNT;
		
		if Store first_with (each.has_food and each.has_water) = nil {
			Store s <- any(Store);
			s.has_food <- true;
			s.has_water <- true;
		}
		
	}

	float distanceTraveledWithoutMemory <- 0.0;
	float distanceTraveledWithMemory <- 0.0;

}

experiment Festival type: gui {
	output {
		display "World" type: opengl background: #white { 
			species Guest aspect: base;
			species Store aspect: base;
			species Center aspect: base;
			species Guard aspect: base;
			species Gate aspect: base;
			species DanceFloor aspect: base;
		}
	}
}