// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { DeBoxSBT } from "../src/DeBoxSBT.sol";

contract SBTTest is Test {
  DeBoxSBT sbt;

  address admin = makeAddr("admin");

  function setUp() public {
    vm.prank(admin);
    sbt = new DeBoxSBT("https://data.debox.pro/nft/sbt/");
  }

  function testAirdrop(uint256 count) public {
    vm.assume(count > 0 && count < 100);

    address[] memory users = new address[](count);
    for (uint256 i = 0; i < users.length; i++) {
      users[i] = makeAddr(string.concat("user", vm.toString(i)));
    }
    vm.prank(admin);
    sbt.mint(1, users);

    assertEq(sbt.totalSupply(1), count, "total supply should be equal to count");

    for (uint256 i = 0; i < users.length; i++) {
      assertEq(sbt.balanceOf(users[i], 1), 1, string.concat("abc:", vm.toString(users[i])));
    }
  }

  function testSBTURL() public {
    address bob = makeAddr("bob");
    airdrop(bob);
    assertEq(sbt.uri(1), "https://data.debox.pro/nft/sbt/1");

    vm.prank(admin);
    sbt.setURI("https://data.debox.pro/");
    assertEq(sbt.uri(1), "https://data.debox.pro/1");
  }

  function testFailedAirdropRole() public {
    address[] memory users = new address[](1);
    users[0] = makeAddr("bob");
    sbt.mint(1, users);
  }

  function testTransfer() public {
    address bob = makeAddr("bob");
    airdrop(bob);

    vm.expectRevert("disabled");
    vm.prank(bob);
    sbt.setApprovalForAll(address(this), true);

    vm.expectRevert("transfers not allowed");
    vm.prank(bob);
    sbt.safeTransferFrom(bob, makeAddr("alice"), 1, 1, "");

    // allow burn
    vm.prank(bob);
    sbt.burn(1, 1);
  }

  function airdrop(address to) public {
    address[] memory users = new address[](1);
    users[0] = to;

    vm.prank(admin);
    sbt.mint(1, users);
  }
}
