#include "all.h"
#include <boost/test/unit_test.hpp>

// Test fixture to reset global state between tests
struct TestFixture {
	TestFixture() {
		// Clear global state before each test
		modules.clear();
		context = Module{};
	}

	~TestFixture() {
		// Clean up any allocated modules
		for (auto* module : modules) {
			delete module;
		}
		modules.clear();
	}
};

BOOST_FIXTURE_TEST_SUITE(link_target_info_tests, TestFixture)

BOOST_AUTO_TEST_CASE(test_empty_modules) {
	// Test with no modules
	modules.clear();
	context.datalayout = "";
	context.triple = "";

	// Should not throw and should not modify context
	BOOST_CHECK_NO_THROW(linkTargetInfo());
	BOOST_CHECK_EQUAL(context.datalayout, "");
	BOOST_CHECK_EQUAL(context.triple, "");
}

BOOST_AUTO_TEST_CASE(test_single_module_with_data) {
	// Test with a single module containing datalayout and triple
	auto* module = new Module();
	module->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module);

	// Should copy values to context
	linkTargetInfo();
	BOOST_CHECK_EQUAL(context.datalayout, module->datalayout);
	BOOST_CHECK_EQUAL(context.triple, module->triple);
}

BOOST_AUTO_TEST_CASE(test_multiple_modules_consistent) {
	// Test with multiple modules with consistent datalayout and triple
	auto* module1 = new Module();
	module1->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module1->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module1);

	auto* module2 = new Module();
	module2->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module2->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module2);

	// Should not throw and should copy values to context
	BOOST_CHECK_NO_THROW(linkTargetInfo());
	BOOST_CHECK_EQUAL(context.datalayout, module1->datalayout);
	BOOST_CHECK_EQUAL(context.triple, module1->triple);
}

BOOST_AUTO_TEST_CASE(test_multiple_modules_inconsistent_datalayout) {
	// Test with multiple modules with inconsistent datalayout
	auto* module1 = new Module();
	module1->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module1->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module1);

	auto* module2 = new Module();
	module2->datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module2->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module2);

	// Should throw runtime_error for inconsistent datalayout
	BOOST_CHECK_EXCEPTION(linkTargetInfo(), std::runtime_error, [](const std::runtime_error& e) {
		return std::string(e.what()).find("Inconsistent datalayout") != std::string::npos;
	});
}

BOOST_AUTO_TEST_CASE(test_multiple_modules_inconsistent_triple) {
	// Test with multiple modules with inconsistent triple
	auto* module1 = new Module();
	module1->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module1->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module1);

	auto* module2 = new Module();
	module2->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module2->triple = "aarch64-unknown-linux-gnu";
	modules.push_back(module2);

	// Should throw runtime_error for inconsistent triple
	BOOST_CHECK_EXCEPTION(linkTargetInfo(), std::runtime_error, [](const std::runtime_error& e) {
		return std::string(e.what()).find("Inconsistent target triple") != std::string::npos;
	});
}

BOOST_AUTO_TEST_CASE(test_some_modules_empty_data) {
	// Test with some modules having empty datalayout or triple
	auto* module1 = new Module();
	module1->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module1->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module1);

	auto* module2 = new Module();
	module2->datalayout = ""; // Empty datalayout
	module2->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module2);

	auto* module3 = new Module();
	module3->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module3->triple = ""; // Empty triple
	modules.push_back(module3);

	// Should not throw and should copy values to context
	BOOST_CHECK_NO_THROW(linkTargetInfo());
	BOOST_CHECK_EQUAL(context.datalayout, module1->datalayout);
	BOOST_CHECK_EQUAL(context.triple, module1->triple);
}

BOOST_AUTO_TEST_CASE(test_all_modules_empty_data) {
	// Test with all modules having empty datalayout and triple
	auto* module1 = new Module();
	module1->datalayout = "";
	module1->triple = "";
	modules.push_back(module1);

	auto* module2 = new Module();
	module2->datalayout = "";
	module2->triple = "";
	modules.push_back(module2);

	// Should not throw and should not modify context
	BOOST_CHECK_NO_THROW(linkTargetInfo());
	BOOST_CHECK_EQUAL(context.datalayout, "");
	BOOST_CHECK_EQUAL(context.triple, "");
}

BOOST_AUTO_TEST_CASE(test_context_already_has_data) {
	// Test when context already has datalayout and triple
	auto* module = new Module();
	module->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module);

	context.datalayout = "existing-datalayout";
	context.triple = "existing-triple";

	// Should not modify existing context values
	linkTargetInfo();
	BOOST_CHECK_EQUAL(context.datalayout, "existing-datalayout");
	BOOST_CHECK_EQUAL(context.triple, "existing-triple");
}

BOOST_AUTO_TEST_CASE(test_context_has_partial_data) {
	// Test when context already has some data but not all
	auto* module = new Module();
	module->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module->triple = "x86_64-unknown-linux-gnu";
	modules.push_back(module);

	context.datalayout = "existing-datalayout";
	context.triple = ""; // Empty triple

	// Should only copy missing values to context
	linkTargetInfo();
	BOOST_CHECK_EQUAL(context.datalayout, "existing-datalayout"); // Should not change
	BOOST_CHECK_EQUAL(context.triple, module->triple);			  // Should be copied
}

BOOST_AUTO_TEST_SUITE_END()
