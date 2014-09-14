import 'package:unittest/unittest.dart';

//var assert = require("./chai").assert,
//    util = require("../lib/util");

sum() {
  group("util.sum", () {
    test("returns the sum of all elements in the array", () {
      expect(util.sum([1,2,3,4]), equals(10));
    });

    test("returns 0 if there are no elements in the array", () {
      expect(util.sum([]), equals(0));
    });
  });
}

all() {
  group("util.all", () {
    test("returns true if f(x) holds for all x in xs", () {
      expect(util.all([1,2,3,4], (x) {
        return x > 0;
      }), isTrue);
    });

    test("returns false if f(x) does not hold for all x in xs", () {
      expect(util.all([1,2,3,-1], (x) {
        return x > 0;
      }), isFalse);
    });

    test("fails fast if f(x) does not hold for all x in xs", () {
      var lastSeen;
      expect(util.all([1,2,-1,3,4], (x) {
        lastSeen = x;
        return x > 0;
      }), isFalse);
      expect(lastSeen, equals(-1));
    });
  });
}