/**
* Name: Auctioneer
* Based on the internal empty template. 
* Author: frane
* Tags: 
*/


model Auctioneer

import "Guest.gaml"
import "Base.gaml"
import "Human.gaml"

global {
	
	list auctionable_items <- ['shirt', 'hat'];
	list auction_types <- ['dutch', 'english', 'vickrey'];
	list signeers <- ['Aba', 'Elon Musk', 'Putin', 'Alexander Hamilton', 'Joe Biden', 'Donald Duck'];
	
	bool only_dutch_auctions <- false;
	
	int dutch_value_gained <- 0;
	int english_value_gained <- 0;
	int vickrey_value_gained <- 0;
	
	int dutch_completed <- 0;
	int english_completed <- 0;
	int vickrey_completed <- 0;
	
}

species Merch parent: Base {
	int price <- rnd(10, 10000);
	string item <- any(auctionable_items);
	string signed_by <- any(signeers);
	
	string to_string {
		return "[" + item + " : " + price + "]";
	}
}

species Auctioneer skills: [fipa] parent: Human control: fsm {

	init {
		create Merch number: 10 returns: created_merch;
		merchandise <- created_merch;

		do goto target: host.world.location speed: 5;

		shape <- (circle(6) inter host.world.shape) - circle(3);
	}	

	list<Merch> merchandise;
	Merch currently_auctioning <- nil;
	int minimum_participants <- 10;
	list<Guest> participants <- [];

	state idle initial: true {
		
		transition to: leave when: empty(merchandise) {
			do log("No more merch, leaving festival");
		}
		
		transition to: starting_auction when: !empty(merchandise) {
			currently_auctioning <- any(merchandise);
			remove currently_auctioning from: merchandise;
		}
		
	}
	
	state starting_auction {
		
		enter {
			string auction_type;
			if only_dutch_auctions {
				auction_type <- 'dutch';
			} else {
				auction_type <- any(auction_types);
			}
			
			do start_conversation to: list(Guest) protocol: 'no-protocol' performative: 'inform' contents: ['auctioning', currently_auctioning.id];
			int waited <- 0;
			do log("Starting X auction for X", [auction_type, currently_auctioning]);
			
		}
		
		waited <- waited + 1;
		participants <- participants where !dead(each);
		
		if waited = 4 {
			
			list auction_agrees <- agrees where (read(each) = 'will participate');			
			participants <- auction_agrees collect (each.sender as Guest);
			bool will_start <- length(participants) >= minimum_participants;
			
			loop a over: auction_agrees {
				if will_start {
					do inform message: a contents: ['auction starting', auction_type];
					do end_conversation message: a contents: [];	
				} else {
					do inform message: a contents: ['auction cancelled'];
					do end_conversation message: a contents: [];	
				}
			}
		
			loop r over: refuses {
				do end_conversation message: r contents: [];
			}
			
		}
		
		transition to: idle when: waited > 200 or (waited > 4 and length(participants) < minimum_participants) {
			remove all: true from: conversations;
			if !empty(participants) {
				do start_conversation to: participants protocol: 'no-protocol' performative: 'cancel' contents: ['auction cancelled'];
			}
			do log("Not enough participants for auction");
		}
		
		bool can_hold <- (participants all_match (each.at_target())) and length(participants) >= minimum_participants;
		
		transition to: hold_dutch_auction when: can_hold and auction_type = 'dutch';
		
		transition to: hold_english_auction when: can_hold and auction_type = 'english';
		
		transition to: hold_vickrey_auction when: can_hold and auction_type = 'vickrey';
		
		exit {
			if can_hold {
				do log("Holding X auction for X with X participants", [auction_type, currently_auctioning, length(participants)]);
			}
		}
		
	}
	
	state hold_dutch_auction {
		
		enter {
			list<Guest> waiting_for <- [];
			int min_price <- currently_auctioning.price;
			int current_price <- min_price * rnd(10, 20);
			int price_step <- (current_price - min_price) / 50;
			bool sold <- false;
		}
		
		waiting_for <- waiting_for where !dead(each);
		participants <- participants where !dead(each);
		
		loop i over: informs {
			Guest g <- i.sender as Guest;
			if read(i) = 'leaving auction' {
				remove g from: participants;
				remove g from: waiting_for;
				do end_conversation message: i contents: ['ok'];
			}
		}
		
		loop p over: proposes {
			Guest g <- p.sender as Guest;
			remove g from: waiting_for;
			if read(p) = 'buy for current' and (participants contains g) {
				if sold {
					do reject_proposal message: p contents: ['already sold'];
				} else {
					do accept_proposal message: p contents: ['sold', currently_auctioning.id];
					sold <- true;
					do log('Sold X to X for X', [currently_auctioning, p.sender, current_price]);
					dutch_value_gained <- dutch_value_gained + current_price - currently_auctioning.price;
					dutch_completed <- dutch_completed + 1;
				}
			} else {
				do reject_proposal message: p contents: ['unknown'];
			}
		}
		
		loop r over: refuses {
			Guest g <- r.sender as Guest;
			if read(r) = 'no offer' {
				remove g from: waiting_for;
			}
		}
		
		if empty(waiting_for) and current_price >= min_price {
			add all: participants to: waiting_for;
			do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: ['going for', current_price];
			do log("Going for X", [current_price]);
			current_price <- current_price - price_step;
		}
		
		transition to: end_auction when: sold or (empty(waiting_for) and current_price < min_price) or empty(participants) {
			do log("Auction for X ended", [currently_auctioning]);
			do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: ['auction ended'];
		}
		
	}
	
	state hold_english_auction {
		
		enter {
			int waited <- 0;
			Guest last_bidder <- nil;
			int last_bid <- currently_auctioning.price;
			do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: ['starting at', last_bid];
			do log('Starting bids at X', [last_bid]);
		}
		waited <- waited + 1;
		
		loop p over: proposes {
			if participants contains p.sender and read(p) = 'bidding' {
				int bid <- int(read(p, 1));
				if bid > last_bid {
					last_bid <- bid;
					last_bidder <- p.sender;
					do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: ['bid by', bid, last_bidder.id];
					waited <- 0;
					do log('X by X', [bid, p.sender]);
				}
			}
		}
		
		transition to: end_auction when: waited > 10 {
			
			if last_bidder != nil {
				do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: ['sold to for', currently_auctioning.id, last_bidder.id, last_bid];	
				english_value_gained <- english_value_gained + last_bid - currently_auctioning.price;
				english_completed <- english_completed + 1;
			} else {
				do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: ['auction ended'];
			}
			
		}
		
	}

	state hold_vickrey_auction {
		
		enter {
			do start_conversation to: participants protocol: 'no-protocol' performative: 'query' contents: ['your bid'];
		}
		
		transition to: end_auction when: state_cycle > 10 {
			
			list bids <- (proposes where (read(each) = 'bidding')) sort_by -int(read(each, 1));
			
			if length(bids) < 2 {
				do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: ['auction ended'];
				do log('Not enough bids for vickrey auction');
			} else {
				Guest winner <- (bids at 0).sender as Guest;
				int price <- int(read(bids at 1, 1));
				
				do log('Sold to X for X', [winner, price]);
				
				vickrey_value_gained <- vickrey_value_gained + price - currently_auctioning.price;
				vickrey_completed <- vickrey_completed + 1;
				do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: ['sold to for', currently_auctioning.id, winner.id, price];
			}
			
		}
		
	}
	
	state end_auction {
		
		enter {
			int cooldown <- rnd(10, 100);
			currently_auctioning <- nil;
			participants <- [];
		}		
		cooldown <- cooldown - 1;

		transition to: idle when: cooldown < 0;
		
		loop m over: mailbox {
			do end_conversation message: m contents: [];
		}
		
	}
	
	state leave {
		
		enter {
			target <- any(Gate);
		}
		
		if at_target() {
			do die_gracefully;
		}
		
	}
	
	aspect base {
		draw sphere(1) color: #blue;
		draw shape color: #pink;
		
		if draw_target_lines {
			draw link(self, target as point) color: #red;
		}
		
	}
	
}
