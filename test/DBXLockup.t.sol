// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import "../src/BOXLockup.sol";
import { DeBoxToken } from "../src/DeBoxToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TestBOXLookup is Test {
  BOXLockup lockup;

  DeBoxToken dbx;
  address alice = makeAddr("alice");

  function setUp() public {
    dbx = new DeBoxToken();

    BOXLockup impl = new BOXLockup();
    ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(address)", address(dbx)));
    lockup = BOXLockup(address(proxy));

    vm.prank(0x37C8C7166B3ADCb1F58c1036d0272FbcD90D87Ea);
    dbx.transfer(address(this), 350_000_000 ether);
  }

  function testAllowLockup() public {
    vm.prank(alice);
    lockup.acceptLockup(address(this), true);
    bool allow = lockup.canLock(alice, address(this));
    assertTrue(allow, "Allow lockup should be true.");

    vm.prank(alice);
    lockup.acceptLockup(address(this), false);
    allow = lockup.canLock(alice, address(this));
    assertTrue(!allow, "Allow lockup should be false.");
  }

  function testAlicCannotLockForMeBeforeAccept() public {
    dbx.transfer(alice, 10000 * 1e18);

    address me = makeAddr("me");
    vm.prank(alice);
    vm.expectRevert("BOXLockup: not allowed to lock");
    lockup.lock(me, 10000 * 1e18, 1 days, 10);

    // can lock after accept

    vm.prank(me);
    lockup.acceptLockup(alice, true);
    oneLock(alice, me, 10000 * 1e18, 1 days, 10);
  }

  function testLock() public {
    uint256 amount = 100000 * 1e18;
    uint256 interval = 1 days;
    uint256 releaseTimes = 10;

    oneLock(alice, amount, interval, releaseTimes);
    oneLock(alice, amount * 2, interval, releaseTimes);
  }

  function testLockOne() public {
    uint256 amount = 100000 * 1e18;
    uint256 interval = 1 days;
    uint256 releaseTimes = 1;
    oneLock(alice, amount, interval, releaseTimes);

    // will revert because no releaseable amount
    vm.prank(alice);
    vm.expectRevert("BOXLockup: no releaseable amount");
    lockup.release();

    // release
    skip(interval);
    oneRelease(alice, true);

    // will revert because no releaseable amount
    vm.prank(alice);
    vm.expectRevert("BOXLockup: no releaseable amount");
    lockup.release();

    // balance is zero
    skip(interval);
    (uint256 balance, uint256 releaseable) = lockup.balanceOf(alice);
    assertEq(releaseable, 0);
    assertEq(balance, 0);
  }

  function testLockManyTimes() public {
    uint256 amount = 100000 * 1e18;

    oneLock(alice, amount, 1 hours, 10);
    oneLock(alice, amount, 1.5 hours, 5);
    oneLock(alice, amount, 3.1 hours, 8);

    for (uint256 i = 0; i < 8; i++) {
      skip(3.1 hours);
      oneRelease(alice, true);
      console.log("alice balance:", dbx.balanceOf(alice));
    }

    skip(360 days);
    (uint256 balance, uint256 releaseable) = lockup.balanceOf(alice);
    assertEq(releaseable, 0);
    assertEq(balance, 0);
  }

  function testLock12Months() public {
    uint256 amount = 350_000_000 ether;
    uint256 interval = 30 days;
    uint256 releaseTimes = 12;

    oneLock(alice, amount, interval, releaseTimes);

    for (uint256 i = 0; i < releaseTimes; i++) {
      skip(interval);
      oneRelease(alice, true);
    }

    (uint256 balance, uint256 releaseable) = lockup.balanceOf(alice);
    assertEq(releaseable, 0);
    assertEq(balance, 0);
  }

  function testRelease() public {
    uint256 amount = 100000 * 1e18;
    uint256 interval = 1 hours;
    uint256 releaseTimes = 10;

    oneLock(alice, amount, interval, releaseTimes);

    // unlock
    vm.prank(alice);
    lockup.acceptLockup(address(this), false); // disallow lock，but can release

    for (uint256 i = 0; i < releaseTimes; i++) {
      skip(interval);
      oneRelease(alice, true);
      oneRelease(alice, false);
    }
    (uint256 balance, uint256 releaseable) = lockup.balanceOf(alice);
    assertEq(releaseable, 0, "Releaseable amount should be 0.");
    assertEq(balance, 0, "balance amount should be 0.");

    // will revert
    vm.prank(alice);
    vm.expectRevert("BOXLockup: no releaseable amount");
    lockup.release();
  }

  function oneRelease(address who, bool mustRelease) public {
    (, uint256 releaseable) = lockup.balanceOf(who);
    if (releaseable > 0) {
      uint256 dbxs = dbx.balanceOf(who);
      vm.prank(who);
      lockup.release();
      uint256 dbxs2 = dbx.balanceOf(who);
      assertEq(dbxs2, dbxs + releaseable, "BOX balance should be increased.");
    } else if (mustRelease) {
      revert("No releaseable amount.");
    }
  }

  function testLockDiv() public {
    uint256 amount = 33333 ether;
    uint256 interval = 1 hours;
    uint256 releaseTimes = 9;

    oneLock(alice, amount, interval, releaseTimes);

    skip(interval);
    (uint256 balance, uint256 releaseable) = lockup.balanceOf(alice);
    assertEq(releaseable, 3703666666666666666666);
    assertEq(balance, 33333 ether, "balance amount should be 33333 BOX");

    // need 10 times to release all
    for (uint256 i = 0; i < 9; i++) {
      oneRelease(alice, true);
      skip(interval);
    }
    (balance, releaseable) = lockup.balanceOf(alice);
    assertEq(releaseable, 0, "Releaseable amount should be 0.");
    assertEq(balance, 0, "balance amount should be 0.");
    assertEq(dbx.balanceOf(alice), amount);

    // will revert
    vm.prank(alice);
    vm.expectRevert("BOXLockup: no releaseable amount");
    lockup.release();
  }

  function testReleaseAll() public {
    uint256 amount = 100000 * 1e18;
    uint256 interval = 1 hours;
    uint256 releaseTimes = 10;

    oneLock(alice, amount, interval, releaseTimes);

    {
      skip(2.5 hours);
      (uint256 balance, uint256 releaseable) = lockup.balanceOf(alice);
      assertEq(releaseable, 10000 * 2 * 1e18);
      assertEq(balance, amount);
    }

    {
      skip(5.2 hours);
      (uint256 balance, uint256 releaseable) = lockup.balanceOf(alice);
      assertEq(releaseable, 10000 * 7 * 1e18);
      assertEq(balance, amount);

      // release onece
      oneRelease(alice, true);
      (, uint256 releaseable2) = lockup.balanceOf(alice);
      assertEq(releaseable2, 0, "Releaseable amount should be 0.");
    }
    {
      skip(360 days);

      oneRelease(alice, true);
      (uint256 balance, uint256 releaseable) = lockup.balanceOf(alice);
      assertEq(releaseable, 0);
      assertEq(balance, 0);
      assertEq(dbx.balanceOf(alice), amount);
    }
  }

  function oneLock(address to, uint256 amount, uint256 interval, uint256 releaseTimes) public {
    if (lockup.canLock(to, address(this)) == false) {
      vm.prank(to);
      lockup.acceptLockup(address(this), true);
    }
    oneLock(address(this), to, amount, interval, releaseTimes);
  }
  // lock BOX

  function oneLock(address from, address to, uint256 amount, uint256 interval, uint256 releaseTimes) public {
    vm.startPrank(from);
    dbx.approve(address(lockup), amount);

    uint256 dbxs = dbx.balanceOf(address(lockup));
    (uint256 total, uint256 releaseable) = lockup.balanceOf(to);

    lockup.lock(to, amount, interval, releaseTimes);

    vm.stopPrank();

    (uint256 total2, uint256 releaseable2) = lockup.balanceOf(to);
    assertEq(total2, total + amount, "Total locked amount should be increased.");
    assertEq(releaseable2, releaseable, "Releaseable amount should be increased.");

    uint256 dbxs2 = dbx.balanceOf(address(lockup));
    assertEq(dbxs2, dbxs + amount, "BOX balance should be increased.");
  }
}
