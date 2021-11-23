/**
* Name: Auctioneer
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Base

global {

	int c <- 0;
	map<string, Base> entities <- [];
	
	string OBJECT_PLACEHOLDER <- 'X';
	
	bool enable_all_logs <- false;
	
}

species Base skills: [fipa] virtual: true {

	init {
		id <- string(type_of(self)) + "-" + c;
		add self at: id to: entities;
		c <- c + 1;
		
		last_state <- self get 'state';
		state_cycle <- 0;
	
	}
	
	int internal_cycle <- cycle update: internal_cycle + 1;
	
	string last_state;
	int state_cycle update: state_cycle + 1;
	
	reflex check_state_change { 
		string current_state <- self get 'state';
		if current_state != last_state {
			state_cycle <- 0;
		}
		last_state <- current_state;
	}
		
	Base from_id(string agent_id) {
		return entities at agent_id;
	}
	
	action die_gracefully {
		remove key: id from: entities;
		do die;
	}
	
	string read(message m, int i <- 0) {
		if length(list(m.contents)) <= i {
			return nil;
		}
		return string(list(m.contents) at i);
	}
	
	Base read_agent(message m, int i <- 0) {
		return from_id(read(m, i));
	}
	
	string id;

	bool logs <- false;
	
	action log(string m, list obj <- []) {
		if !enable_all_logs and !logs {
			return;
		}
		
		loop o over: obj {
			int i <- m index_of OBJECT_PLACEHOLDER;
			string s <- copy_between(m, 0, i);
			string e <- copy_between(m, i + length(OBJECT_PLACEHOLDER), length(m));
			if o is Base and Base(o) != nil {
				m <- s + Base(o).to_string() + e;
			} else if o is string {
				m <- s + o + e;				
			} else {
				m <- s + o + e;
			}
		}
		
		write "[" + to_string() + "] : " + m;  
	}
	
	string to_string {
		return self.name;
	}
	
}
