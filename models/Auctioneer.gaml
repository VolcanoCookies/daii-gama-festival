/**
* Name: Center
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Center

import "Guest.gaml"
import "Guard.gaml"
import "Store.gaml"
import "Id.gaml"

species Center skills: [fipa] parent: Identifiable {
	
	list<Guest> hitlist <- [];

	reflex respond_to_queries when: !empty(queries) {
		message query <- queries at 0;
		bool require_food <- at(query.contents as list, 1) = 'food required: true';
		bool require_water <- at(query.contents as list, 2) = 'water required: true';
		
		Store s <- (Store where ((!require_food or each.has_food) and (!require_water or each.has_water))) closest_to location;
		
		do agree message: query contents: ['accepted'];
		do inform message: query contents: [s.id];
	}
	
	reflex respond_to_requests when: !empty(requests) {
		message r <- requests at 0;
		Guest thief <- agent_from_message(r, 1) as Guest;
		add thief to: hitlist;
		do agree message: r contents: ['okay'];
	}
	
	reflex when: !empty(proposes) {
		
		
		map<Guest, list> hit_map <- proposes group_by agent_from_message(each, 1);
		
		Guest hit <- any(hit_map.keys);
		list<message> proposals <- hit_map at hit;
		
		float cd <- #max_float;
		message cm <- nil;
		loop proposal over: proposals {
			Guard g <- proposal.sender as Guard;
			if g distance_to hit < cd {
				cm <- proposal;
			}
		}
		
		do accept_proposal message: cm contents: ['hit granted', hit.id];
		remove hit from: hitlist;
		
		loop reject_p over: (proposals - cm) {
			do reject_proposal message: reject_p contents: ['already taken'];
		}
		
	}
	
	reflex when: !empty(hitlist) {
		Guest top <- hitlist at 0;
		do start_conversation to: list(Guard) protocol: 'fipa-contract-net' performative: 'cfp' contents: ['kill', top.id] ;
	}
	

	reflex when: !empty(refuses) {
		remove all: true from: refuses;
	}
	
	aspect base {
		draw cube(2) color: #blue;
	}
	
}
