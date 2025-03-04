struct Module {
	string datalayout;
	string triple;

	vector<Ref> comdats;

	vector<Global> globals;
	vector<Fn> decls;
	vector<Fn> defs;

	// This is the set of global variables and functions that have external visibility
	// Everything not mentioned in this set, has internal visibility only
	unordered_set<Ref> externals;
};

extern vector<Module*> modules;
extern Module context;
