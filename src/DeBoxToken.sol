//   _____    ______   ____     ____   __   __
//  |  __ \  |  ____| |  _ \   / __ \  \ \ / /
//  | |  | | | |__    | |_) | | |  | |  \ V /
//  | |  | | |  __|   |  _ <  | |  | |   > <
//  | |__| | | |____  | |_) | | |__| |  / . \
//  |_____/  |______| |____/   \____/  /_/ \_\
//
//  Author: https://debox.pro/
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title DeBoxToken
 * @author https://debox.pro/
 * @notice DeBoxToken is an ERC20 token with permit. It is the governance token of the DeBox platform.
 */
contract DeBoxToken is ERC20Permit {
  constructor() ERC20Permit("DeBoxToken") ERC20("DeBoxToken", "BOX") {
    _mint(0x2745F97f501087caF8eA740854Cfcac011fb34C3, 10_000_000 * 1e18); //IDO/IEO/Launchpad	      1.00%	  10,000,000
    _mint(0x2745F97f501087caF8eA740854Cfcac011fb34C3, 20_000_000 * 1e18); // Liquidity	            2.00%	  20,000,000
    _mint(0x5b1AfdB8C23569484773aF7bD4c98Af9ee7599D9, 50_000_000 * 1e18); // Commuinty	            5.00%	  50,000,000
    _mint(0xa0c3d11eE7e5FFAF0f39b2f99dE7A7732f90a2aD, 200_000_000 * 1e18); // Foundation	          20.00%	200,000,000
    _mint(0x37C8C7166B3ADCb1F58c1036d0272FbcD90D87Ea, 350_000_000 * 1e18); // Ecosystem Incentives	35.00%	350,000,000
    _mint(0xD0AE9A0b0596B9A68F56Ae629eaBfB8a58DA2F75, 200_000_000 * 1e18); // Investor	            20.00%	200,000,000
    _mint(0x866f585a1751D2A49aD67bf69Bce225F4e30dE8d, 170_000_000 * 1e18); // Team	                17.00%	170,000,000
    // safety check
    require(totalSupply() == 1_000_000_000 ether, "incorrect total supply"); // 1 billion
  }

  function _update(address from, address to, uint256 value) internal override {
    // disallow transfers to this contract
    if (to == address(this)) revert ERC20InvalidReceiver(to);

    super._update(from, to, value);
  }
}
