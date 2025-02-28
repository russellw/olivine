// Some things, like the target platform, and declarations of external functions
// are effectively global constants during the operation of the optimizer
namespace context {
extern string datalayout;
extern string triple;
extern std::set<Ref> comdats;
extern vector<Fn> decls;

void clear();
} // namespace context
