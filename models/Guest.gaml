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
import "Auctioneer.gaml"

species Guest parent: Human control: fsm {
	
	init {
		intoxication <- 0.1;
	
		Gate entry_gate <- any(Gate);
		if entry_gate != nil {
			location <- entry_gate.location;
		}
	}
	
	float wealth <- rnd(0.0, 2.0);
	
	list fan_of <- shuffle(rnd(1, length(signeers)) among signeers);
	
	list<Merch> inventory <- [];
	
	DanceFloor dance_floor <- any(DanceFloor);
	
	bool is_criminal <- false;
	
	bool hungry <- false update: hungry or flip(0.0001);
	bool thirsty <- false update: thirsty or flip(0.0001);
	
	Guest hurt_by <- nil;
	
	Auctioneer auctioneer <- nil;
	Merch currently_auctioned <- nil;
	
	state idle initial: true {
		
		enter {
			target <- any_location_in(dance_floor.shape);
			auctioneer <- nil;
		}
		
		if at_target() {
			target <- dance_floor.shape;
		}
		
		loop r over: requests {
			if read(r) = 'give me your money' {
				if flip(0.25) {
					do refuse message: r contents: ['no'];
				} else {
					do agree message: r contents: ['okay'];
				}
			}
		}
		
		transition to: hurt when: hurt_by != nil;
		
		transition to: find_center when: hungry or thirsty {
			target <- Center closest_to self;
		}
		
		transition to: find_victim when: flip(0.001) {
			target <- (peers where (each.state = 'idle')) closest_to self;
		}
		
		list possible_auctions <- informs where (read(each) = 'auctioning' and want_merch(read_agent(each, 1) as Merch));
		
		transition to: find_auction when: !empty(possible_auctions) {
			do agree message: first(possible_auctions) contents: ['will participate'];
			auctioneer <- first(possible_auctions).sender as Auctioneer;
			currently_auctioned <- read_agent(first(possible_auctions), 1) as Merch;
		}
	
	}
	
	bool want_merch(Merch merch) {
		return empty(inventory where (each.item = merch.item)) and (fan_of contains merch.signed_by);
	}
	
	int percieved_price(Merch merch) {
		return float(merch.price) * (1.35 ^ float(fan_of index_of merch.signed_by)) * wealth;
	}
	
	state find_auction {
		
		enter {
			unknown old_target <- target;
			target <- nil;
			string auction_type;
		}
		
		bool cancelled <- false;

		loop i over: informs {
			if i.sender = auctioneer {
				switch read(i) {
					match 'auction starting' {
						target <- auctioneer.shape;
						auction_type <- read(i, 1);
					}
					match 'auction cancelled' {
						cancelled <- true;
					}
				}
			}
		}
				
		transition to: idle when: cancelled or dead(auctioneer) or (target = nil and state_cycle > 25) {
			target <- old_target;
		}

		transition to: participate_dutch_auction when: at_target() and auction_type = 'dutch';
		transition to: participate_english_auction when: at_target() and auction_type = 'english';
		transition to: participate_vickrey_auction when: at_target() and auction_type = 'vickrey'; 

		exit {
			if at_target() {
				do log("Participating in X auction at X", [auction_type, auctioneer]);
			}
		}

	}
	
	state participate_dutch_auction {
		
		enter {
			bool has_ended <- false;
		}
		
		loop i over: informs where (each.sender = auctioneer) {
			if read(i) = 'auction ended' or read(i) = 'auction cancelled' {
				has_ended <- true;
			}
		}
		
		loop a over: accept_proposals where (each.sender = auctioneer) {
			if read(a) = 'sold' {
				do inform message: a contents: ['thank you'];
				Merch merch <- Merch(read_agent(a, 1));
				add merch to: inventory;
				do log('Bought X for X from X', [merch, '?', auctioneer]);
			}
		}
		
		loop r over: reject_proposals {
			do end_conversation message: r contents: [];
		}
		
		loop cfp over: cfps {
			if cfp.sender = auctioneer and read(cfp) = 'going for' {
				int price <- int(read(cfp, 1));
				if price < percieved_price(currently_auctioned) {
					do propose message: cfp contents: ['buy for current'];
				} else {
					do refuse message: cfp contents: ['no offer'];
				}
			}
		}
		
		transition to: idle when: has_ended or dead(auctioneer);
		
	}
	
	state participate_english_auction {
		
		enter {
			int willing_to_pay <- percieved_price(currently_auctioned);
			int last_bid <- 0;
			bool has_ended <- false;
		}
		
		loop i over: informs {
			if i.sender = auctioneer {
				switch read(i) {
					match 'starting at' {
						int starting_price <- int(read(i, 1));
												
						if starting_price * 1.1 <= willing_to_pay {
							last_bid <- starting_price * rnd(1.05, 1.1);
							do propose message: i contents: ['bidding', last_bid];
							do log('Bidding X', [last_bid]);
						}
					}
					match 'sold to for' {
						if read_agent(i, 2) = self {
							add Merch(read_agent(i, 1)) to: inventory;
						}
						has_ended <- true;
					}
					match 'bid by' {
						if read_agent(i, 2) != self {
							int bid <- int(read(i, 1));
							if bid > last_bid and bid * 1.1 <= willing_to_pay {
								last_bid <- bid * rnd(1.05, 1.1);
								do propose message: i contents: ['bidding', last_bid];
								do log('Bidding X', [last_bid]);
							}
						}
					}
					match 'auction ended' {
						has_ended <- true;
					}
				}
			}
		}
		
		transition to: idle when: has_ended or dead(auctioneer);
		
	}
	
	state participate_vickrey_auction {
		
		enter {
			int willing_to_pay <- percieved_price(currently_auctioned);
			bool has_ended <- false;
		}
		
		loop q over: queries {
			if q.sender = auctioneer and read(q) = 'your bid' {
				do propose message: q contents: ['bidding', percieved_price(currently_auctioned)];
			}
		}
		
		loop i over: informs {
			if i.sender = auctioneer {
				switch read(i) {
					match 'sold to for' {
						if read_agent(i, 2) = self {
							add Merch(read_agent(i, 1)) to: inventory;
						}
						has_ended <- true;
					}
					match 'auction ended' {
						has_ended <- true;
					}
				}
			}
		}
		
		transition to: idle when: has_ended or dead(auctioneer);
		
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
				do start_conversation to: [target as Center] protocol: 'fipa-query' performative: 'query' contents: ['closest store', 'food required: ' + hungry, 'water required: ' + thirsty];
			}
			
			if hurt_by != nil and !dead(hurt_by) {
				do start_conversation to: [target] protocol: 'fipa-request' performative: 'request' contents: ['kill', hurt_by.id];
			}
		}
		
		loop a over: agrees {
			
		}
		
		loop i over: informs {
			if i.sender = target and read(i) = 'closest store' {
				target <- Store(read_agent(i, 1));
			}
		}
		
		transition to: find_store when: target is Store;
		
		transition to: idle when: target = nil or (!hungry and !thirsty);
		
		exit {
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
		
		draw cone3D(0.5, 2) color: agent_color;
		draw sphere(0.5) at: location + {0,0,1} color: agent_color;
		
		if !empty(inventory where (each.item = 'hat')) {
			draw cone3D(0.6, 0.5) at: location + {0,0,1.8} color: #yellow;
		}
		
		if !empty(inventory where (each.item = 'shirt')) {
			draw cone3D(0.5, 1.8) at: location + {0,0,0.2} color: #blue;
		}
		
		if draw_target_lines {
			draw link(self, target as point) color: #red;
		}
		
	}
	
}