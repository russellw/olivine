use std::collections::HashMap;
use std::io::{self, Write};
use std::process;

// Define the game state
struct GameState {
    current_location: String,
    inventory: Vec<String>,
    visited_locations: HashMap<String, bool>,
    game_flags: HashMap<String, bool>,
}

// Define a location in the game world
struct Location {
    name: String,
    description: String,
    connections: HashMap<String, String>,
    items: Vec<String>,
    interactions: HashMap<String, String>,
}

// Main game struct
struct Game {
    locations: HashMap<String, Location>,
    state: GameState,
}

impl Game {
    // Initialize a new game
    fn new() -> Self {
        // Create the game world
        let mut locations = HashMap::new();
        
        // Cabin
        locations.insert(
            "cabin".to_string(),
            Location {
                name: "Abandoned Cabin".to_string(),
                description: "You are in an old, dusty cabin. Sunlight streams through cracks in the wooden walls. There's a door to the north and a small table in the corner.".to_string(),
                connections: {
                    let mut conn = HashMap::new();
                    conn.insert("north".to_string(), "forest_path".to_string());
                    conn
                },
                items: vec!["dusty_key".to_string()],
                interactions: {
                    let mut inter = HashMap::new();
                    inter.insert("table".to_string(), "A small wooden table with a dusty key on it.".to_string());
                    inter.insert("door".to_string(), "A sturdy wooden door leading outside.".to_string());
                    inter
                },
            },
        );

        // Forest Path
        locations.insert(
            "forest_path".to_string(),
            Location {
                name: "Forest Path".to_string(),
                description: "You're on a narrow path winding through tall pine trees. The cabin is to the south, and the path continues to the east.".to_string(),
                connections: {
                    let mut conn = HashMap::new();
                    conn.insert("south".to_string(), "cabin".to_string());
                    conn.insert("east".to_string(), "river_crossing".to_string());
                    conn
                },
                items: vec![],
                interactions: {
                    let mut inter = HashMap::new();
                    inter.insert("trees".to_string(), "Tall pine trees surround you, their needles rustling in the breeze.".to_string());
                    inter
                },
            },
        );

        // River Crossing
        locations.insert(
            "river_crossing".to_string(),
            Location {
                name: "River Crossing".to_string(),
                description: "A rushing river blocks your path. There's a rickety bridge to the north, and the forest path is to the west. A cave entrance is visible to the east.".to_string(),
                connections: {
                    let mut conn = HashMap::new();
                    conn.insert("west".to_string(), "forest_path".to_string());
                    conn.insert("north".to_string(), "bridge".to_string());
                    conn.insert("east".to_string(), "cave_entrance".to_string());
                    conn
                },
                items: vec!["sturdy_stick".to_string()],
                interactions: {
                    let mut inter = HashMap::new();
                    inter.insert("river".to_string(), "The water is flowing rapidly, too dangerous to cross without the bridge.".to_string());
                    inter.insert("bridge".to_string(), "A rickety wooden bridge that looks like it might collapse at any moment.".to_string());
                    inter
                },
            },
        );

        // Bridge
        locations.insert(
            "bridge".to_string(),
            Location {
                name: "Rickety Bridge".to_string(),
                description: "You're on a swaying wooden bridge over the rushing river. The planks creak under your weight.".to_string(),
                connections: {
                    let mut conn = HashMap::new();
                    conn.insert("south".to_string(), "river_crossing".to_string());
                    conn.insert("north".to_string(), "mountain_trail".to_string());
                    conn
                },
                items: vec![],
                interactions: {
                    let mut inter = HashMap::new();
                    inter.insert("planks".to_string(), "The wooden planks of the bridge are worn and creaky.".to_string());
                    inter.insert("river".to_string(), "The river rushes below you, its waters crashing against rocks.".to_string());
                    inter
                },
            },
        );

        // Mountain Trail
        locations.insert(
            "mountain_trail".to_string(),
            Location {
                name: "Mountain Trail".to_string(),
                description: "A steep trail winds up the mountainside. The bridge is to the south, and there's a small shrine at the top of the path to the north.".to_string(),
                connections: {
                    let mut conn = HashMap::new();
                    conn.insert("south".to_string(), "bridge".to_string());
                    conn.insert("north".to_string(), "shrine".to_string());
                    conn
                },
                items: vec![],
                interactions: {
                    let mut inter = HashMap::new();
                    inter.insert("mountains".to_string(), "The mountains loom tall and majestic around you.".to_string());
                    inter
                },
            },
        );

        // Shrine
        locations.insert(
            "shrine".to_string(),
            Location {
                name: "Ancient Shrine".to_string(),
                description: "A small stone shrine sits at the top of the mountain. There's a locked chest in the center and strange symbols carved into the walls.".to_string(),
                connections: {
                    let mut conn = HashMap::new();
                    conn.insert("south".to_string(), "mountain_trail".to_string());
                    conn
                },
                items: vec![],
                interactions: {
                    let mut inter = HashMap::new();
                    inter.insert("chest".to_string(), "A locked stone chest with an ancient keyhole.".to_string());
                    inter.insert("symbols".to_string(), "Strange symbols are carved into the walls, telling a story of an ancient treasure.".to_string());
                    inter.insert("use dusty_key chest".to_string(), "You insert the dusty key into the chest. It fits! The chest opens, revealing a golden amulet. You've found the treasure!".to_string());
                    inter
                },
            },
        );

        // Cave Entrance
        locations.insert(
            "cave_entrance".to_string(),
            Location {
                name: "Cave Entrance".to_string(),
                description: "A dark cave mouth yawns before you. Cool air flows from within. The river crossing is to the west.".to_string(),
                connections: {
                    let mut conn = HashMap::new();
                    conn.insert("west".to_string(), "river_crossing".to_string());
                    conn.insert("enter".to_string(), "cave_interior".to_string());
                    conn
                },
                items: vec![],
                interactions: {
                    let mut inter = HashMap::new();
                    inter.insert("cave".to_string(), "The cave is dark. You'll need a light source to explore it.".to_string());
                    inter
                },
            },
        );

        // Cave Interior - only accessible with a light
        locations.insert(
            "cave_interior".to_string(),
            Location {
                name: "Cave Interior".to_string(),
                description: "The cave is filled with glittering crystals that reflect your light. There's a small underground pool in the center.".to_string(),
                connections: {
                    let mut conn = HashMap::new();
                    conn.insert("exit".to_string(), "cave_entrance".to_string());
                    conn
                },
                items: vec!["crystal_shard".to_string()],
                interactions: {
                    let mut inter = HashMap::new();
                    inter.insert("pool".to_string(), "The water in the pool is crystal clear and seems to glow with an inner light.".to_string());
                    inter.insert("crystals".to_string(), "Beautiful crystals line the walls, glowing with a soft blue light.".to_string());
                    inter
                },
            },
        );

        // Initialize game state
        let state = GameState {
            current_location: "cabin".to_string(),
            inventory: vec![],
            visited_locations: HashMap::new(),
            game_flags: {
                let mut flags = HashMap::new();
                flags.insert("found_treasure".to_string(), false);
                flags.insert("has_light".to_string(), false);
                flags
            },
        };

        Game { locations, state }
    }

    // Print the current location description
    fn look(&self) {
        let location = self.locations.get(&self.state.current_location).unwrap();
        println!("\n=== {} ===", location.name);
        println!("{}", location.description);
        
        // List items
        if !location.items.is_empty() {
            println!("\nYou can see:");
            for item in &location.items {
                match item.as_str() {
                    "dusty_key" => println!("- A dusty old key"),
                    "sturdy_stick" => println!("- A sturdy wooden stick"),
                    "crystal_shard" => println!("- A glowing crystal shard"),
                    _ => println!("- {}", item),
                }
            }
        }
        
        // List exits
        println!("\nExits:");
        for (direction, _) in &location.connections {
            println!("- {}", direction);
        }
    }

    // Process player movement
    fn go(&mut self, direction: &str) {
        let location = self.locations.get(&self.state.current_location).unwrap();
        
        if direction == "enter" && self.state.current_location == "cave_entrance" && !self.state.game_flags["has_light"] {
            println!("It's too dark to enter the cave. You need a light source.");
            return;
        }
        
        match location.connections.get(direction) {
            Some(new_location) => {
                self.state.current_location = new_location.clone();
                self.state.visited_locations.insert(new_location.clone(), true);
                self.look();
            }
            None => println!("You can't go that way."),
        }
    }

    // Process examining objects
    fn examine(&self, object: &str) {
        let location = self.locations.get(&self.state.current_location).unwrap();
        
        match location.interactions.get(object) {
            Some(description) => println!("{}", description),
            None => {
                // Check if the object is in the inventory
                if self.state.inventory.contains(&object.to_string()) {
                    match object {
                        "dusty_key" => println!("An old iron key covered in dust. It might open something important."),
                        "sturdy_stick" => println!("A strong branch that could be used as a torch if lit."),
                        "crystal_shard" => println!("A beautiful crystal that glows with an inner light. It's bright enough to see by!"),
                        _ => println!("You see nothing special about it."),
                    }
                } else {
                    println!("You don't see that here.");
                }
            }
        }
    }

    // Process taking items
    fn take(&mut self, item: &str) {
        let location = self.locations.get_mut(&self.state.current_location).unwrap();
        
        // Handle variations of item names
        let item_internal = match item {
            "key" | "dusty key" => "dusty_key",
            "stick" | "sturdy stick" => "sturdy_stick",
            "crystal" | "shard" | "crystal shard" => "crystal_shard",
            _ => item,
        };
        
        if location.items.contains(&item_internal.to_string()) {
            // Remove from location
            let index = location.items.iter().position(|i| i == item_internal).unwrap();
            location.items.remove(index);
            
            // Add to inventory
            self.state.inventory.push(item_internal.to_string());
            
            // Special item effects
            if item_internal == "crystal_shard" {
                self.state.game_flags.insert("has_light".to_string(), true);
                println!("You pick up the crystal shard. It glows brightly in your hand, providing enough light to see by!");
            } else {
                println!("You take the {}.", item);
            }
        } else {
            println!("You don't see that here.");
        }
    }

    // Process dropping items
    fn drop(&mut self, item: &str) {
        // Handle variations of item names
        let item_internal = match item {
            "key" | "dusty key" => "dusty_key",
            "stick" | "sturdy stick" => "sturdy_stick",
            "crystal" | "shard" | "crystal shard" => "crystal_shard",
            _ => item,
        };
        
        if self.state.inventory.contains(&item_internal.to_string()) {
            // Remove from inventory
            let index = self.state.inventory.iter().position(|i| i == item_internal).unwrap();
            self.state.inventory.remove(index);
            
            // Add to location
            let location = self.locations.get_mut(&self.state.current_location).unwrap();
            location.items.push(item_internal.to_string());
            
            // Special item effects
            if item_internal == "crystal_shard" {
                self.state.game_flags.insert("has_light".to_string(), false);
            }
            
            println!("You drop the {}.", item);
        } else {
            println!("You don't have that.");
        }
    }

    // Process using items
    fn use_item(&mut self, item: &str, target: &str) {
        // Handle variations of item names
        let item_internal = match item {
            "key" | "dusty key" => "dusty_key",
            "stick" | "sturdy stick" => "sturdy_stick",
            "crystal" | "shard" | "crystal shard" => "crystal_shard",
            _ => item,
        };
        
        let use_command = format!("use {} {}", item_internal, target);
        let location = self.locations.get(&self.state.current_location).unwrap();
        
        // Check if we have a specific interaction for this use
        if let Some(result) = location.interactions.get(&use_command) {
            // Special case for opening the chest
            if item_internal == "dusty_key" && target == "chest" && self.state.current_location == "shrine" {
                self.state.game_flags.insert("found_treasure".to_string(), true);
                println!("{}", result);
                println!("\nCongratulations! You've completed the adventure!");
            } else {
                println!("{}", result);
            }
        } else if !self.state.inventory.contains(&item_internal.to_string()) {
            println!("You don't have the {}.", item);
        } else {
            println!("You can't use the {} on that.", item);
        }
    }

    // Check inventory
    fn inventory(&self) {
        if self.state.inventory.is_empty() {
            println!("Your inventory is empty.");
        } else {
            println!("Inventory:");
            for item in &self.state.inventory {
                match item.as_str() {
                    "dusty_key" => println!("- A dusty old key"),
                    "sturdy_stick" => println!("- A sturdy wooden stick"),
                    "crystal_shard" => println!("- A glowing crystal shard"),
                    _ => println!("- {}", item),
                }
            }
        }
    }

    // Help command
    fn help(&self) {
        println!("\n=== Commands ===");
        println!("look - Look around the current location");
        println!("go [direction] - Move in a direction (north, south, east, west, etc.)");
        println!("examine [object] - Look more closely at an object");
        println!("take [item] - Pick up an item");
        println!("drop [item] - Drop an item from your inventory");
        println!("use [item] [target] - Use an item on a target (e.g., use key door)");
        println!("inventory - Check your inventory");
        println!("help - Show this help message");
        println!("quit - End the game");
    }

    // Main game loop
    fn run(&mut self) {
        println!("\n=== Welcome to the Mountain Mystery Adventure ===");
        println!("Type 'help' for a list of commands.\n");
        
        self.look();
        
        loop {
            print!("> ");
            io::stdout().flush().unwrap();
            
            let mut input = String::new();
            io::stdin().read_line(&mut input).unwrap();
            let input = input.trim().to_lowercase();
            
            let words: Vec<&str> = input.split_whitespace().collect();
            
            match words.as_slice() {
                ["look"] => self.look(),
                ["go", direction] => self.go(direction),
                ["north"] | ["n"] => self.go("north"),
                ["south"] | ["s"] => self.go("south"),
                ["east"] | ["e"] => self.go("east"),
                ["west"] | ["w"] => self.go("west"),
                ["enter"] => self.go("enter"),
                ["exit"] => self.go("exit"),
                ["examine", object] | ["look", "at", object] | ["x", object] => self.examine(object),
                ["take", item] | ["get", item] => self.take(item),
                ["drop", item] => self.drop(item),
                ["use", item, target] => self.use_item(item, target),
                ["inventory"] | ["i"] => self.inventory(),
                ["help"] | ["?"] => self.help(),
                ["quit"] | ["q"] | ["exit"] => {
                    println!("Thanks for playing!");
                    break;
                },
                [] => continue,
                _ => println!("I don't understand that command. Type 'help' for a list of commands."),
            }
            
            // Check if the game is won
            if self.state.game_flags["found_treasure"] {
                println!("\nYou've completed the adventure! The golden amulet glows with an ancient power.");
                println!("Type 'quit' to end the game or continue exploring if you wish.");
            }
        }
    }
}

fn main() {
    let mut game = Game::new();
    game.run();
}