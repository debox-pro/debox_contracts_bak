// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { DeBoxSBT } from "../src/DeBoxSBT.sol";

contract SBTScript is Script {
  string constant FILE = "./deployed.json";

  function setUp() public { }

  function deploy() public {
    vm.startBroadcast();

    DeBoxSBT sbt = new DeBoxSBT("https://data.debox.pro/nft/sbt/");

    console.log("SBT deployed at:", address(sbt));

    vm.stopBroadcast();

    writeAddr(".sbt", address(sbt));
  }

  function airdrop(address[] calldata list) public {
    DeBoxSBT sbt = DeBoxSBT(getAddr(".sbt"));

    vm.broadcast();
    sbt.mint(1, list);
  }

  function writeAddr(string memory key, address addr) public {
    // get chain id
    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    key = string.concat(".", vm.toString(chainId), key);

    vm.writeJson(vm.toString(addr), FILE, key);
  }

  function getAddr(string memory key) private returns (address) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    key = string.concat(".", vm.toString(chainId), key);
    string memory data = vm.readFile(FILE);
    return vm.parseJsonAddress(data, key);
  }
}
