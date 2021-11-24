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
import "Auctioneer.gaml"
import "Human.gaml"

global {

	bool draw_target_lines <- false;

	int GUEST_COUNT <- 100 const: true;
	int GUARD_COUNT <- 5 const: true;
	int STORE_COUNT <- 3 const: true;
	int CENTER_COUNT <- 2 const: true;
	int GATE_COUNT <- 1 const: true;
	int DANCE_FLOOR_COUNT <- 2 const: true;
	int AUCTIONEER_COUNT <- 1;

	init {
		
		create Store number: STORE_COUNT; 
		create Center number: CENTER_COUNT;
		create DanceFloor number: DANCE_FLOOR_COUNT;
		create Gate number: GATE_COUNT;
		create Guard number: GUARD_COUNT;
		create Guest number: GUEST_COUNT;
		create Auctioneer number: AUCTIONEER_COUNT;
		
		if Store first_with (each.has_food and each.has_water) = nil {
			Store s <- any(Store);
			s.has_food <- true;
			s.has_water <- true;
		}
		
	}

}

experiment Festival type: gui {
	
	parameter 'Target Lines' var: draw_target_lines;
	parameter 'Only dutch auctions' var: only_dutch_auctions;
	parameter 'Enable all logs' var: enable_all_logs;
	parameter 'Auctioneer count' var: AUCTIONEER_COUNT;
	
	output {
		
		display "World" type: opengl background: #white { 
			species Guest aspect: base;
			species Store aspect: base refresh: false;
			species Center aspect: base refresh: false;
			species Guard aspect: base;
			species Gate aspect: base refresh: false;
			species DanceFloor aspect: base refresh: false;
			species Auctioneer aspect: base;
			
			
		}
	}
}