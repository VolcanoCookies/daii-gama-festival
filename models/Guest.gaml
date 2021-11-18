/**
* Name: Guest
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/

model Guest

import "Human.gaml"
import "Store.gaml"
import "Center.gaml"
import "DanceFloor.gaml"
import "Gate.gaml"

species Guest parent: Human control: fsm {
	
	init {
		intoxication <- 0.1;
	
		Gate entry_gate <- any(Gate);
		if entry_gate != nil {
			location <- entry_gate.location;
		}
	}
	
	DanceFloor dance_floor <- any(DanceFloor);
	
	bool is_criminal <- false;
	
	bool hungry <- false update: hungry or flip(0.0001);
	bool thirsty <- false update: thirsty or flip(0.0001);
	
	Identifiable hurt_by <- nil;
	
	state idle initial: true {
		
		transition to: hurt when: hurt_by != nil;
		
		transition to: find_center when: hungry or thirsty {
			target <- Center closest_to self;
		}
		
		transition to: find_victim when: flip(0.001) {
			target <- (Guest - self) closest_to self;
		}
		
		if self distance_to dance_floor < dance_floor.radius - reach {
			do wander;
		} else {
			do goto target: dance_floor;
		}
		
	}
	
	state find_victim {
		
		transition to: mug when: at_target() {
			do start_conversation (to :: [target], protocol :: 'fipa-request', performative :: 'request', contents :: ['give me your money']);
		}
		
	}
	
	state mug { 

		transition to: idle when: !empty(refuses) {
			// Such a vicious beating
			remove index: 0 from: refuses;
			ask target as Guest {
				hurt_by <- myself;
			}
			is_criminal <- true;
			target <- nil;
		}
		
		transition to: idle when: !empty(agrees) {
			// Such a vicious beating
			remove index: 0 from: agrees;
			ask target as Guest {
				hurt_by <- myself;
			}
			is_criminal <- true;
			target <- nil;
		}
		
	}

	state find_center {
		
		transition to: hurt when: hurt_by != nil;
		
		enter {
			target <- Center closest_to self;
		}
		
		transition to: ask_center when: at_target();
		
	}
	
	state ask_center {
		
		enter {
			if hungry or thirsty {
				do start_conversation (to :: [target], protocol :: 'fipa-query', performative :: 'query', contents :: ['closest store', 'food required: ' + hungry, 'water required: ' + thirsty]);
			}
			
			if hurt_by != nil {
				do start_conversation (to :: [target], protocol :: 'fipa-request', performative :: 'request', contents :: ['kill', hurt_by.id]);
			}
		}
		
		if !empty(informs) {
			message inform <- informs at 0;
			Store s <- agent_from_message(inform) as Store;
			target <- s;
		}
		
		if !empty(agrees) {
			remove index: 0 from: agrees;
			target <- nil;
		}
		
		transition to: find_store when: target is Store;
		
		transition to: idle when: target = nil {
			hurt_by <- nil;
		}
		
	}
	
	state find_store {

		transition to: hurt when: hurt_by != nil;

		transition to: idle when: at_target() {
			
			Store s <- target as Store;
			
			if hungry {
				hungry <- !s.has_food;
			}
			
			if thirsty {
				thirsty <- !s.has_water;
			}
			
			target <- nil;
			
		}
		
	}
	
	state hurt {
		
		enter {
			target <- Center closest_to self;
		}
		
		transition to: ask_center when: at_target();
		
	}

	reflex when: !empty(requests) {
		message r <- requests at 0;
		string req <- (r.contents as list) at 0;
		
		switch req {
			match 'give me your money' {
				
				if flip(0.25) {
					do refuse message: r contents: ['no'];
				} else {
					do agree message: r contents: ['okay'];
				}
				
			}
		}
				
	}

	reflex remove_agrees when: !empty(agrees) {
		remove all: true from: agrees;
	}

	aspect base {
		
		rgb agent_color <- rgb(100, 200, 75);
		
		if is_criminal {
			agent_color <- rgb(50, 10, 10);
		} else if (hurt_by != nil) {
			agent_color <- rgb(245, 30, 40);
		} else if hungry and thirsty {
			agent_color <- rgb(120, 100, 100);
		} else if hungry {
			agent_color <- rgb(240, 100, 75);
		} else if thirsty {
			agent_color <- rgb(160, 200, 100);
		}
		
		draw sphere(1) color: agent_color;
		
		if state = 'find_victim' {
			draw link(self, target) color: #red;
		}
		
	}
	
}