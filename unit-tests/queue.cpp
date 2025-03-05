#include "all.h"
#include <boost/test/unit_test.hpp>

// Constants for test
const int SENTINEL_VALUE = -1;

BOOST_AUTO_TEST_CASE(test_constructor) {
	vector<int> values = {1, 2, 3};
	queue<int, SENTINEL_VALUE> q(values);

	BOOST_CHECK_EQUAL(q.size(), 3);
	BOOST_CHECK_EQUAL(*q, 1);
}

BOOST_AUTO_TEST_CASE(test_dereference_operator) {
	vector<int> values = {5, 6, 7};
	queue<int, SENTINEL_VALUE> q(values);

	BOOST_CHECK_EQUAL(*q, 5);
	q.pop();
	BOOST_CHECK_EQUAL(*q, 6);
}

BOOST_AUTO_TEST_CASE(test_index_operator) {
	vector<int> values = {10, 20, 30, 40};
	queue<int, SENTINEL_VALUE> q(values);

	BOOST_CHECK_EQUAL(q[0], 10);
	BOOST_CHECK_EQUAL(q[1], 20);
	BOOST_CHECK_EQUAL(q[2], 30);
	BOOST_CHECK_EQUAL(q[3], 40);

	// Access beyond end of queue returns sentinel
	BOOST_CHECK_EQUAL(q[4], SENTINEL_VALUE);
	BOOST_CHECK_EQUAL(q[100], SENTINEL_VALUE);
}

BOOST_AUTO_TEST_CASE(test_pop) {
	vector<int> values = {100, 200, 300};
	queue<int, SENTINEL_VALUE> q(values);

	BOOST_CHECK_EQUAL(q.pop(), 100);
	BOOST_CHECK_EQUAL(q.pop(), 200);
	BOOST_CHECK_EQUAL(q.pop(), 300);

	// Pop on empty queue returns sentinel
	BOOST_CHECK_EQUAL(q.pop(), SENTINEL_VALUE);
	BOOST_CHECK_EQUAL(q.pop(), SENTINEL_VALUE); // Multiple pops should still return sentinel
}

BOOST_AUTO_TEST_CASE(test_push) {
	vector<int> values = {1000};
	queue<int, SENTINEL_VALUE> q(values);

	q.push(2000);
	q.push(3000);

	BOOST_CHECK_EQUAL(q.size(), 3);
	BOOST_CHECK_EQUAL(q[0], 1000);
	BOOST_CHECK_EQUAL(q[1], 2000);
	BOOST_CHECK_EQUAL(q[2], 3000);
}

BOOST_AUTO_TEST_CASE(test_size) {
	vector<int> values = {1, 2, 3, 4, 5};
	queue<int, SENTINEL_VALUE> q(values);

	BOOST_CHECK_EQUAL(q.size(), 5);

	q.pop();
	BOOST_CHECK_EQUAL(q.size(), 4);

	q.pop();
	q.pop();
	BOOST_CHECK_EQUAL(q.size(), 2);

	q.pop();
	q.pop();
	BOOST_CHECK_EQUAL(q.size(), 0);

	// Size after emptying
	q.pop(); // Try to pop from empty queue
	BOOST_CHECK_EQUAL(q.size(), 0);
}

BOOST_AUTO_TEST_CASE(test_mixed_operations) {
	vector<int> values = {42};
	queue<int, SENTINEL_VALUE> q(values);

	BOOST_CHECK_EQUAL(q.size(), 1);
	BOOST_CHECK_EQUAL(*q, 42);

	q.push(43);
	BOOST_CHECK_EQUAL(q.size(), 2);
	BOOST_CHECK_EQUAL(q[1], 43);

	BOOST_CHECK_EQUAL(q.pop(), 42);
	BOOST_CHECK_EQUAL(q.size(), 1);
	BOOST_CHECK_EQUAL(*q, 43);

	BOOST_CHECK_EQUAL(q.pop(), 43);
	BOOST_CHECK_EQUAL(q.size(), 0);
	BOOST_CHECK_EQUAL(*q, SENTINEL_VALUE);

	q.push(99);
	BOOST_CHECK_EQUAL(q.size(), 1);
	BOOST_CHECK_EQUAL(*q, 99);
}

BOOST_AUTO_TEST_CASE(test_different_types) {
	// Test with char type
	const char CHAR_SENTINEL = '\0';
	vector<char> chars = {'a', 'b', 'c'};
	queue<char, CHAR_SENTINEL> char_queue(chars);

	BOOST_CHECK_EQUAL(char_queue.size(), 3);
	BOOST_CHECK_EQUAL(*char_queue, 'a');
	BOOST_CHECK_EQUAL(char_queue.pop(), 'a');
	BOOST_CHECK_EQUAL(char_queue[1], 'c');
	BOOST_CHECK_EQUAL(char_queue[5], CHAR_SENTINEL);
}

BOOST_AUTO_TEST_CASE(test_empty_queue) {
	vector<int> empty;
	queue<int, SENTINEL_VALUE> q(empty);

	BOOST_CHECK_EQUAL(q.size(), 0);
	BOOST_CHECK_EQUAL(*q, SENTINEL_VALUE);
	BOOST_CHECK_EQUAL(q[0], SENTINEL_VALUE);
	BOOST_CHECK_EQUAL(q.pop(), SENTINEL_VALUE);
}
