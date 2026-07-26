/* Global variables in their various linkages and initializer forms, plus the
   constant expressions that appear in initializers. */

int counter = 0;
const int limit = 42;
static int hidden = 7;
char message[] = "olivine";
const char *pointer_to_literal = "literal";
int table[5] = {1, 2, 3, 4, 5};
double zeroed[4];

struct pair {
  int a;
  const char *b;
};
struct pair paired = {1, "two"};

int *address_of_counter = &counter;
int *interior = &table[2];

int bump(void) { return ++counter + hidden; }
