/**
* Name: Guard
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/

model Guard

import "Human.gaml"
import "Guest.gaml"
import "Store.gaml"
import "Center.gaml"
import "Gate.gaml"

species Guard parent: Human control: fsm {
	
	init {
		intoxication <- 0.0;
	}
	
	state idle initial: true {

		enter {
			target <- nil;
		}

		if !empty(cfps) {
			message cfp <- cfps at 0;
			do propose message: cfp contents: cfp.contents;
		}
		
		transition to: hunt when: !empty(accept_proposals) {
			message p <- accept_proposals at 0;
			target <- agent_from_message(p, 1);
		}
		
		do wander;
		
	}
	
	state hunt {
		
		if !empty(cfps) {
			loop cfp over: cfps {
				do refuse message: cfp contents: ['busy'];
			}
		}
		
		transition to: idle when: at_target() {
			ask target as Guest {
				do die_gracefully();
			}
			
			do start_conversation (to :: [any(Gate)], protocol :: 'fipa-request', performative :: 'request', contents :: ['let guest in']);
			
			target <- nil;
		}
		
	}
	
	reflex when: !empty(reject_proposals) {
		remove all: true from: reject_proposals;
	}
	
	reflex when: !empty(refuses) or !empty(agrees) {
		remove all: true from: refuses;
		remove all: true from: agrees;
	}
	
	aspect base {		
		draw sphere(1.5) color: rgb(150, 150, 255);
		draw link(self, target) color: #blue;
	}
	
}