struct Module {
	string datalayout;
	string triple;

	vector<Ref> comdats;

	vector<Global> globals;
	vector<Fn> decls;
	vector<Fn> defs;
};

extern Module context;
