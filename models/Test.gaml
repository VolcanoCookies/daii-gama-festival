 /**
* Name: Test
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/

model Test

global {
	
	init {
		create Test;
	}
	
}

species Test {

	aspect base {
		draw cone3D(0.5, 2) color: #red;
		draw sphere(0.5) at: location + {0,0,1} color: #blue;
		draw cone3D(0.6, 0.5) at: location + {0,0,1.8} color: #green;
	}
	
}

experiment Model type: gui {
	
	
	output {
		display "World" type: opengl background: #white { 
			species Test aspect: base;
		}
	}
}