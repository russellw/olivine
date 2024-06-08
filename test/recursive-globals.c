struct Pointers {
	void* a;
	void* b;
	void* c;
};

struct Record {
	int header;
	struct Pointers pointers;
};

struct Record r = {99, &r, &r, &r + 1};

int main() {
	return 0;
}
