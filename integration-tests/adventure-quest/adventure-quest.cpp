#include <algorithm>
#include <cstdlib>
#include <ctime>
#include <iostream>
#include <limits>
#include <map>
#include <sstream>
#include <string>
#include <vector>

// Forward declarations
class Item;
class Room;
class Enemy;
class Player;

// Utility functions
void clearScreen() {
#ifdef _WIN32
	system("cls");
#else
	system("clear");
#endif
}

std::string toLower(const std::string& str) {
	std::string result = str;
	std::transform(result.begin(), result.end(), result.begin(), ::tolower);
	return result;
}

// Item class
class Item {
private:
	std::string name;
	std::string description;
	int value;
	bool isWeapon;
	int damage;
	bool isArmor;
	int defense;
	bool isConsumable;
	int healthRestore;

public:
	Item(const std::string& name,
		const std::string& description,
		int value,
		bool isWeapon = false,
		int damage = 0,
		bool isArmor = false,
		int defense = 0,
		bool isConsumable = false,
		int healthRestore = 0)
		: name(name),
		  description(description),
		  value(value),
		  isWeapon(isWeapon),
		  damage(damage),
		  isArmor(isArmor),
		  defense(defense),
		  isConsumable(isConsumable),
		  healthRestore(healthRestore) {
	}

	std::string getName() const {
		return name;
	}
	std::string getDescription() const {
		return description;
	}
	int getValue() const {
		return value;
	}
	bool getIsWeapon() const {
		return isWeapon;
	}
	int getDamage() const {
		return damage;
	}
	bool getIsArmor() const {
		return isArmor;
	}
	int getDefense() const {
		return defense;
	}
	bool getIsConsumable() const {
		return isConsumable;
	}
	int getHealthRestore() const {
		return healthRestore;
	}

	void display() const {
		std::cout << name << " - " << description << std::endl;
		std::cout << "Value: " << value << " gold" << std::endl;

		if (isWeapon) {
			std::cout << "Damage: " << damage << std::endl;
		}

		if (isArmor) {
			std::cout << "Defense: " << defense << std::endl;
		}

		if (isConsumable) {
			std::cout << "Restores " << healthRestore << " health when used" << std::endl;
		}
	}
};

// Enemy class
class Enemy {
private:
	std::string name;
	std::string description;
	int health;
	int maxHealth;
	int damage;
	int defense;
	int goldReward;
	std::vector<Item> loot;

public:
	Enemy(const std::string& name, const std::string& description, int health, int damage, int defense, int goldReward)
		: name(name),
		  description(description),
		  health(health),
		  maxHealth(health),
		  damage(damage),
		  defense(defense),
		  goldReward(goldReward) {
	}

	std::string getName() const {
		return name;
	}
	std::string getDescription() const {
		return description;
	}
	int getHealth() const {
		return health;
	}
	int getMaxHealth() const {
		return maxHealth;
	}
	int getDamage() const {
		return damage;
	}
	int getDefense() const {
		return defense;
	}
	int getGoldReward() const {
		return goldReward;
	}

	void takeDamage(int amount) {
		int actualDamage = std::max(1, amount - defense);
		health = std::max(0, health - actualDamage);
		std::cout << name << " takes " << actualDamage << " damage!" << std::endl;
	}

	bool isAlive() const {
		return health > 0;
	}

	void addLoot(const Item& item) {
		loot.push_back(item);
	}

	std::vector<Item> getLoot() const {
		return loot;
	}

	void display() const {
		std::cout << name << " - " << description << std::endl;
		std::cout << "Health: " << health << "/" << maxHealth << std::endl;
		std::cout << "Attack: " << damage << std::endl;
		std::cout << "Defense: " << defense << std::endl;
	}
};

// Forward declaration of Player for Room
class Player;

// Room class
class Room {
private:
	std::string name;
	std::string description;
	std::map<std::string, Room*> exits;
	std::vector<Item> items;
	Enemy* enemy;
	bool visited;

public:
	Room(const std::string& name, const std::string& description)
		: name(name), description(description), enemy(nullptr), visited(false) {
	}

	~Room() {
		delete enemy;
	}

	std::string getName() const {
		return name;
	}
	std::string getDescription() const {
		return description;
	}
	bool hasBeenVisited() const {
		return visited;
	}

	void setVisited(bool value) {
		visited = value;
	}

	void addExit(const std::string& direction, Room* room) {
		exits[direction] = room;
	}

	Room* getExit(const std::string& direction) {
		if (exits.find(direction) != exits.end()) {
			return exits[direction];
		}
		return nullptr;
	}

	void addItem(const Item& item) {
		items.push_back(item);
	}

	void removeItem(const std::string& itemName) {
		for (auto it = items.begin(); it != items.end(); ++it) {
			if (toLower(it->getName()) == toLower(itemName)) {
				items.erase(it);
				break;
			}
		}
	}

	Item* findItem(const std::string& itemName) {
		for (auto& item : items) {
			if (toLower(item.getName()) == toLower(itemName)) {
				return &item;
			}
		}
		return nullptr;
	}

	std::vector<Item>& getItems() {
		return items;
	}

	void setEnemy(Enemy* newEnemy) {
		enemy = newEnemy;
	}

	Enemy* getEnemy() {
		return enemy;
	}

	void clearEnemy() {
		enemy = nullptr;
	}

	void display() const {
		std::cout << "==== " << name << " ====" << std::endl;
		std::cout << description << std::endl;

		// Display exits
		std::cout << "\nExits: ";
		bool hasExits = false;
		for (const auto& exit : exits) {
			std::cout << exit.first << " ";
			hasExits = true;
		}
		if (!hasExits) {
			std::cout << "None";
		}
		std::cout << std::endl;

		// Display items
		if (!items.empty()) {
			std::cout << "\nItems in this room:" << std::endl;
			for (const auto& item : items) {
				std::cout << "- " << item.getName() << std::endl;
			}
		}

		// Display enemy
		if (enemy != nullptr && enemy->isAlive()) {
			std::cout << "\nThere is a " << enemy->getName() << " here!" << std::endl;
		}
	}
};

// Player class
class Player {
private:
	std::string name;
	int health;
	int maxHealth;
	int damage;
	int defense;
	int gold;
	std::vector<Item> inventory;
	Room* currentRoom;
	Item* equippedWeapon;
	Item* equippedArmor;
	std::map<std::string, bool> questFlags;

public:
	Player(const std::string& name, Room* startingRoom)
		: name(name),
		  health(100),
		  maxHealth(100),
		  damage(5),
		  defense(0),
		  gold(10),
		  currentRoom(startingRoom),
		  equippedWeapon(nullptr),
		  equippedArmor(nullptr) {
	}

	std::string getName() const {
		return name;
	}
	int getHealth() const {
		return health;
	}
	int getMaxHealth() const {
		return maxHealth;
	}
	Room* getCurrentRoom() const {
		return currentRoom;
	}

	void setCurrentRoom(Room* room) {
		currentRoom = room;
	}

	int getTotalDamage() const {
		int totalDamage = damage;
		if (equippedWeapon != nullptr) {
			totalDamage += equippedWeapon->getDamage();
		}
		return totalDamage;
	}

	int getTotalDefense() const {
		int totalDefense = defense;
		if (equippedArmor != nullptr) {
			totalDefense += equippedArmor->getDefense();
		}
		return totalDefense;
	}

	void addGold(int amount) {
		gold += amount;
		std::cout << "You gained " << amount << " gold!" << std::endl;
	}

	bool spendGold(int amount) {
		if (gold >= amount) {
			gold -= amount;
			std::cout << "You spent " << amount << " gold." << std::endl;
			return true;
		}
		std::cout << "You don't have enough gold!" << std::endl;
		return false;
	}

	void takeDamage(int amount) {
		int actualDamage = std::max(1, amount - getTotalDefense());
		health = std::max(0, health - actualDamage);
		std::cout << "You take " << actualDamage << " damage!" << std::endl;
	}

	void heal(int amount) {
		int oldHealth = health;
		health = std::min(maxHealth, health + amount);
		std::cout << "You restored " << (health - oldHealth) << " health!" << std::endl;
	}

	bool isAlive() const {
		return health > 0;
	}

	void addToInventory(const Item& item) {
		inventory.push_back(item);
		std::cout << "You picked up " << item.getName() << "." << std::endl;
	}

	void removeFromInventory(const std::string& itemName) {
		for (auto it = inventory.begin(); it != inventory.end(); ++it) {
			if (toLower(it->getName()) == toLower(itemName)) {
				inventory.erase(it);
				break;
			}
		}
	}

	Item* findInInventory(const std::string& itemName) {
		for (auto& item : inventory) {
			if (toLower(item.getName()) == toLower(itemName)) {
				return &item;
			}
		}
		return nullptr;
	}

	void equipWeapon(const std::string& weaponName) {
		Item* weapon = findInInventory(weaponName);
		if (weapon != nullptr && weapon->getIsWeapon()) {
			equippedWeapon = weapon;
			std::cout << "You equipped " << weapon->getName() << "." << std::endl;
		} else {
			std::cout << "You don't have that weapon or it's not a weapon." << std::endl;
		}
	}

	void equipArmor(const std::string& armorName) {
		Item* armor = findInInventory(armorName);
		if (armor != nullptr && armor->getIsArmor()) {
			equippedArmor = armor;
			std::cout << "You equipped " << armor->getName() << "." << std::endl;
		} else {
			std::cout << "You don't have that armor or it's not armor." << std::endl;
		}
	}

	void useItem(const std::string& itemName) {
		Item* item = findInInventory(itemName);
		if (item != nullptr) {
			if (item->getIsConsumable()) {
				heal(item->getHealthRestore());
				removeFromInventory(itemName);
			} else {
				std::cout << "You can't use that item." << std::endl;
			}
		} else {
			std::cout << "You don't have that item." << std::endl;
		}
	}

	void setQuestFlag(const std::string& flag, bool value) {
		questFlags[flag] = value;
	}

	bool getQuestFlag(const std::string& flag) {
		return questFlags.find(flag) != questFlags.end() && questFlags[flag];
	}

	void displayStatus() {
		std::cout << "\n==== Player Status ====" << std::endl;
		std::cout << "Name: " << name << std::endl;
		std::cout << "Health: " << health << "/" << maxHealth << std::endl;
		std::cout << "Attack: " << damage;
		if (equippedWeapon != nullptr) {
			std::cout << " + " << equippedWeapon->getDamage() << " (Total: " << getTotalDamage() << ")";
		}
		std::cout << std::endl;

		std::cout << "Defense: " << defense;
		if (equippedArmor != nullptr) {
			std::cout << " + " << equippedArmor->getDefense() << " (Total: " << getTotalDefense() << ")";
		}
		std::cout << std::endl;

		std::cout << "Gold: " << gold << std::endl;

		std::cout << "\nEquipped:" << std::endl;
		std::cout << "Weapon: " << (equippedWeapon ? equippedWeapon->getName() : "None") << std::endl;
		std::cout << "Armor: " << (equippedArmor ? equippedArmor->getName() : "None") << std::endl;

		std::cout << "\nInventory:" << std::endl;
		if (inventory.empty()) {
			std::cout << "Empty" << std::endl;
		} else {
			for (const auto& item : inventory) {
				std::cout << "- " << item.getName() << std::endl;
			}
		}
	}
};

// Game class to handle overall game logic
class Game {
private:
	Player* player;
	std::vector<Room*> rooms;
	bool gameOver;
	bool victory;

	void createWorld() {
		// Create rooms
		Room* forest = new Room("Forest Clearing", "A peaceful clearing in the forest. Sunlight filters through the leaves.");
		Room* cave = new Room("Dark Cave", "A dark, damp cave. Water drips from the ceiling.");
		Room* riverbank = new Room("Riverbank", "A serene riverbank. The water flows gently past.");
		Room* mountain = new Room("Mountain Path", "A rocky path winding up the mountain. The view is breathtaking.");
		Room* village = new Room("Small Village", "A small, peaceful village with thatched huts.");
		Room* ruinedTemple = new Room("Ruined Temple", "An ancient temple, now in ruins. Strange symbols cover the walls.");

		// Connect rooms
		forest->addExit("north", cave);
		forest->addExit("east", riverbank);
		forest->addExit("west", village);

		cave->addExit("south", forest);
		cave->addExit("east", mountain);

		riverbank->addExit("west", forest);
		riverbank->addExit("north", mountain);

		mountain->addExit("west", cave);
		mountain->addExit("south", riverbank);
		mountain->addExit("north", ruinedTemple);

		village->addExit("east", forest);

		ruinedTemple->addExit("south", mountain);

		// Add items to rooms
		forest->addItem(Item("Stick", "A sturdy wooden stick.", 1, true, 2));
		forest->addItem(Item("Berry", "A juicy forest berry.", 1, false, 0, false, 0, true, 5));

		cave->addItem(Item("Rusty Sword", "An old but still usable sword.", 10, true, 5));
		cave->addItem(Item("Stone", "A smooth, round stone.", 1));

		riverbank->addItem(Item("Fishing Rod", "A simple fishing rod.", 5));
		riverbank->addItem(Item("Health Potion", "A small potion that restores health.", 15, false, 0, false, 0, true, 25));

		mountain->addItem(Item("Climbing Gear", "Equipment for scaling steep cliffs.", 20));

		village->addItem(Item("Bread", "A freshly baked loaf of bread.", 3, false, 0, false, 0, true, 10));
		village->addItem(Item("Leather Armor", "Simple armor made of tanned leather.", 25, false, 0, true, 3));

		ruinedTemple->addItem(Item("Ancient Amulet", "A mysterious amulet with strange inscriptions.", 100));
		ruinedTemple->addItem(Item("Steel Sword", "A finely crafted steel sword.", 50, true, 10));
		ruinedTemple->addItem(Item("Plate Armor", "Heavy armor made of metal plates.", 75, false, 0, true, 8));

		// Add enemies
		cave->setEnemy(new Enemy("Goblin", "A small, green creature with sharp teeth.", 20, 5, 0, 10));

		mountain->setEnemy(new Enemy("Wolf", "A fierce mountain wolf with gray fur.", 15, 7, 1, 8));

		riverbank->setEnemy(new Enemy("Slime", "A gelatinous blob that oozes around.", 10, 3, 0, 5));

		ruinedTemple->setEnemy(new Enemy("Ancient Guardian", "A stone statue brought to life by ancient magic.", 50, 12, 5, 100));
		ruinedTemple->getEnemy()->addLoot(Item("Guardian Crystal", "A glowing crystal from the ancient guardian.", 200));

		// Store the rooms
		rooms.push_back(forest);
		rooms.push_back(cave);
		rooms.push_back(riverbank);
		rooms.push_back(mountain);
		rooms.push_back(village);
		rooms.push_back(ruinedTemple);

		// Create the player
		std::string playerName;
		std::cout << "What is your name, adventurer? ";
		std::getline(std::cin, playerName);
		player = new Player(playerName, forest);
	}

	bool processCommand(const std::string& commandLine) {
		std::vector<std::string> tokens;
		std::string token;
		std::istringstream iss(commandLine);

		while (iss >> token) {
			tokens.push_back(toLower(token));
		}

		if (tokens.empty()) {
			return false;
		}

		std::string command = tokens[0];

		if (command == "quit" || command == "exit") {
			std::cout << "Are you sure you want to quit? (y/n) ";
			std::string confirm;
			std::getline(std::cin, confirm);
			if (toLower(confirm) == "y" || toLower(confirm) == "yes") {
				gameOver = true;
			}
		} else if (command == "help") {
			displayHelp();
		} else if (command == "look") {
			player->getCurrentRoom()->display();
		} else if (command == "north" || command == "south" || command == "east" || command == "west") {
			movePlayer(command);
		} else if (command == "go" && tokens.size() > 1) {
			movePlayer(tokens[1]);
		} else if (command == "examine" && tokens.size() > 1) {
			examineItem(tokens[1]);
		} else if (command == "take" && tokens.size() > 1) {
			takeItem(tokens[1]);
		} else if (command == "drop" && tokens.size() > 1) {
			dropItem(tokens[1]);
		} else if (command == "inventory" || command == "i") {
			player->displayStatus();
		} else if (command == "equip" && tokens.size() > 1) {
			equipItem(tokens[1]);
		} else if (command == "use" && tokens.size() > 1) {
			useItem(tokens[1]);
		} else if (command == "attack") {
			attackEnemy();
		} else if (command == "talk" && tokens.size() > 1) {
			talkTo(tokens[1]);
		} else {
			std::cout << "I don't understand that command. Type 'help' for a list of commands." << std::endl;
		}

		return true;
	}

	void displayHelp() {
		std::cout << "\n==== Commands ====" << std::endl;
		std::cout << "help        - Display this help message" << std::endl;
		std::cout << "look        - Look around the current room" << std::endl;
		std::cout << "north/south/east/west - Move in that direction" << std::endl;
		std::cout << "go [dir]    - Move in the specified direction" << std::endl;
		std::cout << "examine [item] - Look at an item more closely" << std::endl;
		std::cout << "take [item] - Pick up an item" << std::endl;
		std::cout << "drop [item] - Drop an item from your inventory" << std::endl;
		std::cout << "inventory   - Check your inventory and status" << std::endl;
		std::cout << "equip [item] - Equip a weapon or armor" << std::endl;
		std::cout << "use [item]  - Use a consumable item" << std::endl;
		std::cout << "attack      - Attack an enemy in the room" << std::endl;
		std::cout << "talk [npc]  - Talk to an NPC" << std::endl;
		std::cout << "quit        - Quit the game" << std::endl;
	}

	void movePlayer(const std::string& direction) {
		Room* currentRoom = player->getCurrentRoom();
		Room* nextRoom = currentRoom->getExit(direction);

		if (nextRoom) {
			player->setCurrentRoom(nextRoom);
			std::cout << "You go " << direction << "." << std::endl << std::endl;

			if (!nextRoom->hasBeenVisited()) {
				nextRoom->setVisited(true);
				nextRoom->display();
			} else {
				std::cout << "You are in the " << nextRoom->getName() << "." << std::endl;
			}

			// Check for victory condition
			if (nextRoom->getName() == "Ruined Temple" && player->getQuestFlag("ancient_guardian_defeated") &&
				player->findInInventory("Ancient Amulet") != nullptr && player->findInInventory("Guardian Crystal") != nullptr) {
				std::cout << "\nAs you hold both the Ancient Amulet and the Guardian Crystal, they begin to glow." << std::endl;
				std::cout << "The temple starts to shake, and a hidden passage appears!" << std::endl;
				std::cout << "You've discovered the secret of the ancient temple!" << std::endl;
				victory = true;
				gameOver = true;
			}

			// Check for enemies
			if (nextRoom->getEnemy() && nextRoom->getEnemy()->isAlive()) {
				std::cout << "\nA " << nextRoom->getEnemy()->getName() << " attacks you!" << std::endl;
			}
		} else {
			std::cout << "You can't go that way." << std::endl;
		}
	}

	void examineItem(const std::string& itemName) {
		// Check inventory first
		Item* invItem = player->findInInventory(itemName);
		if (invItem) {
			std::cout << "From your inventory: " << std::endl;
			invItem->display();
			return;
		}

		// Then check room
		Room* currentRoom = player->getCurrentRoom();
		Item* roomItem = currentRoom->findItem(itemName);
		if (roomItem) {
			roomItem->display();
		} else {
			std::cout << "You don't see that here." << std::endl;
		}
	}

	void takeItem(const std::string& itemName) {
		Room* currentRoom = player->getCurrentRoom();
		Item* item = currentRoom->findItem(itemName);

		if (item) {
			player->addToInventory(*item);
			currentRoom->removeItem(itemName);
		} else {
			std::cout << "You don't see that here." << std::endl;
		}
	}

	void dropItem(const std::string& itemName) {
		Item* item = player->findInInventory(itemName);

		if (item) {
			Room* currentRoom = player->getCurrentRoom();
			currentRoom->addItem(*item);
			player->removeFromInventory(itemName);
			std::cout << "You dropped " << itemName << "." << std::endl;
		} else {
			std::cout << "You don't have that item." << std::endl;
		}
	}

	void equipItem(const std::string& itemName) {
		Item* item = player->findInInventory(itemName);

		if (item) {
			if (item->getIsWeapon()) {
				player->equipWeapon(itemName);
			} else if (item->getIsArmor()) {
				player->equipArmor(itemName);
			} else {
				std::cout << "You can't equip that." << std::endl;
			}
		} else {
			std::cout << "You don't have that item." << std::endl;
		}
	}

	void useItem(const std::string& itemName) {
		player->useItem(itemName);
	}

	void attackEnemy() {
		Room* currentRoom = player->getCurrentRoom();
		Enemy* enemy = currentRoom->getEnemy();

		if (enemy && enemy->isAlive()) {
			// Player attacks enemy
			int playerDamage = player->getTotalDamage();
			std::cout << "You attack the " << enemy->getName() << "!" << std::endl;
			enemy->takeDamage(playerDamage);

			// Check if enemy is defeated
			if (!enemy->isAlive()) {
				std::cout << "You defeated the " << enemy->getName() << "!" << std::endl;

				// Reward player
				player->addGold(enemy->getGoldReward());

				// Add loot to room
				for (const auto& loot : enemy->getLoot()) {
					currentRoom->addItem(loot);
					std::cout << "The " << enemy->getName() << " dropped " << loot.getName() << "." << std::endl;
				}

				// Set quest flags
				if (enemy->getName() == "Ancient Guardian") {
					player->setQuestFlag("ancient_guardian_defeated", true);
					std::cout << "\nWith the Ancient Guardian defeated, you feel a change in the temple's atmosphere." << std::endl;
					std::cout << "Perhaps finding the Ancient Amulet and the Guardian Crystal will reveal more secrets..."
							  << std::endl;
				}

				return;
			}

			// Enemy attacks player
			int enemyDamage = enemy->getDamage();
			std::cout << "The " << enemy->getName() << " attacks you!" << std::endl;
			player->takeDamage(enemyDamage);

			// Check if player is defeated
			if (!player->isAlive()) {
				std::cout << "\nYou have been defeated by the " << enemy->getName() << "." << std::endl;
				gameOver = true;
			}
		} else {
			std::cout << "There's nothing to attack here." << std::endl;
		}
	}

	void talkTo(const std::string& npcName) {
		Room* currentRoom = player->getCurrentRoom();

		if (currentRoom->getName() == "Small Village" && toLower(npcName) == "villager") {
			std::cout << "Villager: \"Welcome to our humble village, traveler.\"" << std::endl;

			if (!player->getQuestFlag("village_quest_given")) {
				std::cout << "Villager: \"We've been troubled by a guardian in the temple to the north.\"" << std::endl;
				std::cout << "Villager: \"Legend says that the Ancient Amulet and Guardian Crystal together hold great power.\""
						  << std::endl;
				std::cout << "Villager: \"If you can defeat the guardian and bring these artifacts together, you might discover a "
							 "great secret.\""
						  << std::endl;
				player->setQuestFlag("village_quest_given", true);
			} else if (player->getQuestFlag("ancient_guardian_defeated")) {
				std::cout << "Villager: \"You defeated the Ancient Guardian? Incredible!\"" << std::endl;
				std::cout << "Villager: \"Now find the Ancient Amulet and Guardian Crystal. Take them back to the temple to reveal "
							 "its secrets.\""
						  << std::endl;
			} else {
				std::cout << "Villager: \"Be careful on your journey. The mountains are dangerous.\"" << std::endl;
			}
		} else {
			std::cout << "There's no one by that name here to talk to." << std::endl;
		}
	}

public:
	Game(): player(nullptr), gameOver(false), victory(false) {
		// Seed the random number generator
		std::srand(static_cast<unsigned int>(std::time(nullptr)));
	}

	~Game() {
		delete player;
		for (auto room : rooms) {
			delete room;
		}
	}

	void run() {
		// Display welcome message
		std::cout << "==================================================" << std::endl;
		std::cout << "               ADVENTURE QUEST                    " << std::endl;
		std::cout << "==================================================" << std::endl;
		std::cout << "Welcome to a text-based adventure game!" << std::endl;
		std::cout << "Type 'help' for a list of commands." << std::endl << std::endl;

		// Create the game world and player
		createWorld();

		// Display the starting room
		player->getCurrentRoom()->display();

		// Main game loop
		while (!gameOver) {
			std::cout << "\n> ";
			std::string command;
			std::getline(std::cin, command);

			if (command.empty()) {
				continue;
			}

			if (!processCommand(command)) {
				continue;
			}
		}

		// Display end game message
		if (victory) {
			std::cout << "\n==================================================" << std::endl;
			std::cout << "                   VICTORY!                       " << std::endl;
			std::cout << "==================================================" << std::endl;
			std::cout << "Congratulations, " << player->getName() << "!" << std::endl;
			std::cout << "You have discovered the ancient temple's secret and completed your quest!" << std::endl;
			std::cout << "Thank you for playing Adventure Quest!" << std::endl;
		} else {
			std::cout << "\n==================================================" << std::endl;
			std::cout << "                  GAME OVER                       " << std::endl;
			std::cout << "==================================================" << std::endl;
			if (player->isAlive()) {
				std::cout << "You have quit your adventure." << std::endl;
			} else {
				std::cout << "You have fallen in battle." << std::endl;
			}
			std::cout << "Better luck next time, adventurer!" << std::endl;
		}
	}
};

// Main function
int main() {
	Game game;
	game.run();
	return 0;
}
