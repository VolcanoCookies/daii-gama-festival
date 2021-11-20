/**
* Name: DanceFloor
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model DanceFloor

import "Base.gaml"

species DanceFloor parent: Base {
	
	init {
		visible <- hexagon(15) inter host.world.shape;
		shape <- hexagon(12) inter host.world.shape;
	}
	
	geometry visible;
	
	aspect base {
		draw visible color: rgb(200, 100, 225, 100);
	}
	
}
