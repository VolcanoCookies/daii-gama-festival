/**
* Name: Id
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Id

global {
	
	int c <- 0;
	map<string, Identifiable> entities <- [];
	
}

species Identifiable {
	
	init {
		id <- string(type_of(self)) + "-" + c;
		add self at: id to: entities;
		c <- c + 1;
	}
	
	
	
	Identifiable agent_from_message(message m, int index <- 0) {
		list<string> content <- m.contents as list<string>;
		return from_id(content at index);
	}
	
	Identifiable from_id(string agent_id) {
		return entities at agent_id;
	}
	
	action die_gracefully {
		remove key: id from: entities;
		do die;
	}
	
	string id;
	
}

