// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { DeBoxToken } from "../src/DeBoxToken.sol";

contract BOXTest is Test {
  DeBoxToken public dbx;

  function setUp() public {
    dbx = new DeBoxToken();
    vm.prank(0x37C8C7166B3ADCb1F58c1036d0272FbcD90D87Ea);
    dbx.transfer(address(this), 350_000_000 ether);
  }

  function testInfo() public {
    assertEq(dbx.name(), "DeBoxToken");
    assertEq(dbx.symbol(), "BOX");
    assertEq(dbx.decimals(), 18);
    assertEq(dbx.totalSupply(), 1e9 ether);
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
