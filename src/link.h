// Link target information (datalayout and triple) from `::modules` into `::context`
// That is, if the input modules have consistent target information, copy it into context
// If the input modules disagree with each other, raise a runtime error
void linkTargetInfo();

// Link several modules into one
// Specifically, link `::modules` into `::context`
// The result is the input to the optimization process
void link();
