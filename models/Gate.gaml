/**
* Name: Gate
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Gate

import "Guest.gaml"
import "Guard.gaml"
import "Store.gaml"
import "Base.gaml"
import "Festival.gaml"

species Gate skills: [fipa] parent: Base {
	
	reflex when: !empty(requests) {
		message r <- requests at 0;
		string content <- (r.contents as list) at 0;
		switch content {
			match 'let guest in' {
				do agree message: r contents: ['will let guest in'];
				create Guest {
					location <- myself.location;
				}
			}
		}
	}
	
	aspect base {
		draw cube(2) color: #yellow;
	}
	
}
