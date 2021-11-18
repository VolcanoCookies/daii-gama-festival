/**
* Name: DanceFloor
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model DanceFloor

import "Id.gaml"

species DanceFloor parent: Identifiable {
	
	int radius <- 15;
	
	aspect base {
		draw circle(radius) color: rgb(200, 100, 225, 100);
	}
	
}
