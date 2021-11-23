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
import "Base.gaml"

species Center skills: [fipa] parent: Base {
	
	list<Guest> hitlist <- [];

	reflex respond_to_queries when: !empty(queries) {
		message query <- queries at 0;
		bool require_food <- at(query.contents as list, 1) = 'food required: true';
		bool require_water <- at(query.contents as list, 2) = 'water required: true';
		
		Store s <- (Store where ((!require_food or each.has_food) and (!require_water or each.has_water))) closest_to location;
		
		do agree message: query contents: ['okay'];
		do inform message: query contents: ['closest store', s.id];
	}
	
	reflex respond_to_requests when: !empty(requests) {
		message r <- requests at 0;
		Guest thief <- Guest(read_agent(r, 1));
		add thief to: hitlist;
		do agree message: r contents: ['okay'];
	}
	
	reflex when: !empty(proposes) {
		
		hitlist <- distinct(hitlist where !dead(each));
		
		Guest hit <- any(hitlist);
		
		list props <- (proposes where (read_agent(each, 1) != hit));
		props <- props sort_by (Guard(each.sender) distance_to hit);
		
		if !empty(props) {
			do accept_proposal message: props at 0 contents: ['hit granted', hit.id];
			remove index: 0 from: props;
		}
		loop p over: props {
			do reject_proposal message: p contents: ['already taken'];	
		}
		
	}
	
	reflex when: !empty(hitlist) {
		Guest top <- hitlist at 0;
		if !dead(top) {
			do start_conversation to: list(Guard) protocol: 'fipa-contract-net' performative: 'cfp' contents: ['kill', top.id] ;	
		}
	}
	

	reflex when: !empty(refuses) {
		remove all: true from: refuses;
	}
	
	aspect base {
		draw cube(2) color: #blue;
	}
	
}
