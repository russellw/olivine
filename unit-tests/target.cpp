#include "all.h"
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(ParserTests)

// Test parsing target triple and datalayout
BOOST_AUTO_TEST_CASE(TargetInfo) {
	context::clear();
	Parser parser("test.ll", "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n"
							 "target triple = \"x86_64-unknown-linux-gnu\"\n");

	BOOST_CHECK_EQUAL(context::datalayout, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
	BOOST_CHECK_EQUAL(context::triple, "x86_64-unknown-linux-gnu");
}

BOOST_AUTO_TEST_SUITE_END()
