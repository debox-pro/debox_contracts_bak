// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { DBXToken } from "../src/DBXToken.sol";

contract DBXTest is Test {
  DBXToken public dbx;

  function setUp() public {
    dbx = new DBXToken();
  }

  function testInfo() public {
    assertEq(dbx.name(), "DeBoxToken");
    assertEq(dbx.symbol(), "DBX");
    assertEq(dbx.decimals(), 18);
    assertEq(dbx.totalSupply(), 1e10 ether);
  }

  function testTransfer() public {
    address bob = makeAddr("bob");
    dbx.transfer(bob, 100);
    assertEq(dbx.balanceOf(bob), 100);
  }

  function testDisableToDBX() public {
    vm.expectRevert(abi.encodeWithSelector(ERC20InvalidReceiver.selector, address(dbx)));
    dbx.transfer(address(dbx), 100);
  }
}

error ERC20InvalidReceiver(address receiver);
