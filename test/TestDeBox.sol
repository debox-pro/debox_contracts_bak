// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { DeBoxToken } from "../src/DeBoxToken.sol";

contract BOXTest is Test {
  DeBoxToken public dbx;

  function setUp() public {
    dbx = new DeBoxToken();
  }

  function testInfo() public {
    assertEq(dbx.name(), "DeBoxToken");
    assertEq(dbx.symbol(), "BOX");
    assertEq(dbx.decimals(), 18);
    assertEq(dbx.totalSupply(), 1e10 ether);
  }

  function testTransfer() public {
    address bob = makeAddr("bob");
    dbx.transfer(bob, 100);
    assertEq(dbx.balanceOf(bob), 100);
  }

  function testDisableToBOX() public {
    vm.expectRevert(abi.encodeWithSelector(ERC20InvalidReceiver.selector, address(dbx)));
    dbx.transfer(address(dbx), 100);
  }
}

error ERC20InvalidReceiver(address receiver);
