// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { DBXLockup } from "../src/DBXLockup.sol";
import { DBXToken } from "../src/DBXToken.sol";

contract TestDBXLookup is Test {
  DBXLockup lockup;

  DBXToken dbx;
  address alice = makeAddr("alice");

  function setUp() public {
    dbx = new DBXToken();
    lockup = new DBXLockup(address(dbx));
  }

  function testAllowLockup() public {
    vm.prank(alice);
    lockup.acceptLockup(true);
    bool allow = lockup.canLock(alice);
    assertTrue(allow, "Allow lockup should be true.");

    vm.prank(alice);
    lockup.acceptLockup(false);
    allow = lockup.canLock(alice);
    assertTrue(!allow, "Allow lockup should be false.");
  }

  function testLock() public {
    uint256 amount = 100000 * 1e18;
    uint256 interval = 1 hours;
    uint256 releaseTimes = 10;

    oneLock(alice, amount, interval, releaseTimes);
    oneLock(alice, amount * 2, interval, releaseTimes);
  }

  // lock DBX
  function oneLock(address to, uint256 amount, uint256 interval, uint256 releaseTimes) public {
    if (lockup.canLock(to) == false) {
      vm.prank(to);
      lockup.acceptLockup(true);
    }

    dbx.approve(address(lockup), amount);

    uint256 dbxs = dbx.balanceOf(address(lockup));
    (uint256 total, uint256 releaseable) = lockup.balanceOf(to);

    lockup.lock(to, amount, interval, releaseTimes);

    (uint256 total2, uint256 releaseable2) = lockup.balanceOf(to);
    assertEq(total2, total + amount, "Total locked amount should be increased.");
    assertEq(releaseable2, releaseable, "Releaseable amount should be increased.");

    uint256 dbxs2 = dbx.balanceOf(address(lockup));
    assertEq(dbxs2, dbxs + amount, "DBX balance should be increased.");
  }
}
