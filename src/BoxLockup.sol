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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title BOXLockup is a contract to lock BOX for a period of time
 * @author https://debox.pro/
 * @dev BOXLockup is a contract to lock BOX for a period of time, and release it by the beneficiary.
 * 1. the lock amount will be released by the beneficiary, and can't be released by the contract owner.
 * 2. if beneficiary loses the private key, the BOX will be locked forever!
 * 3. MUST accept lockup before lock. it can safely allow/disallow lockup to prevent new lockup, but can't disallow existing lockup.
 * 4. the lock amount will be transferred from msg.sender to this contract, and will be released by the beneficiary.
 */
contract BOXLockup is UUPSUpgradeable, OwnableUpgradeable {
  using SafeERC20 for IERC20;

  event Released(address indexed beneficiary, uint256 amount);
  event Lockup(address indexed beneficiary, uint256 amount, uint256 interval, uint256 releaseTimes);
  event AcceptLockup(address indexed beneficiary, address locker, bool ok);

  uint256 private constant _ONE = 1e18;
  IERC20 public box;
  mapping(address => Lock[]) public locked;

  struct Lock {
    uint256 lockAmount;
    uint256 interval;
    uint256 oneReleaseAmount;
    uint256 nextReleaseAt;
  }

  constructor() {
    _disableInitializers();
  }

  // Initializer function instead of constructor
  function initialize(IERC20 _box) public initializer {
    require(address(_box) != address(0), "BOXLockup: invalid BOX address");
    __Ownable_init(msg.sender);
    __UUPSUpgradeable_init();
    box = _box;
  }

  function _authorizeUpgrade(address) internal view override {
    _checkOwner();
  }

  function withdraw() external onlyOwner {
    box.safeTransfer(msg.sender, box.balanceOf(address(this)));
  }

  /**
   * @notice get the total and releaseable amount of the beneficiary
   * @param beneficiary is the beneficiary address
   * @return total return the total locked amount of the beneficiary
   * @return releaseable return the releaseable amount of the beneficiary
   */
  function balanceOf(address beneficiary) public view returns (uint256 total, uint256 releaseable) {
    for (uint256 i = 0; i < locked[beneficiary].length; i++) {
      Lock storage item = locked[beneficiary][i];
      total += item.lockAmount;
      releaseable += _calculate(item);
    }
  }

  function lockWithDays(uint256 lockAmount, uint256 intervalDays, uint256 releaseTimes) external {
    lock(lockAmount, intervalDays * 1 days, releaseTimes);
  }

  /**
   * @notice lock BOX
   * @dev the lock amount will be transferred from msg.sender to this contract, and will be released by the beneficiary.
   * if msg.sender loses the private key, the BOX will be locked forever!
   * @param lockAmount is the amount of BOX to lock, MUST be greater than 10000 BOX
   * @param interval is the interval of each release, in seconds, MUST be greater than 1 hour.
   * @param releaseTimes is the release times, MUST be greater than 1
   */
  function lock(uint256 lockAmount, uint256 interval, uint256 releaseTimes) public {
    address beneficiary = msg.sender;
    require(locked[beneficiary].length <= 16, "BOXLockup: lock limit reached"); // only allow 16 locks per address
    require(interval >= 1 hours && interval <= 365 days, "BOXLockup: interval invalid");
    require(releaseTimes > 0 && releaseTimes * interval <= 6 * 365 days, "BOXLockup: release times invalid");
    require(lockAmount >= 10000 * _ONE, "BOXLockup: lock amount too low");

    uint256 oneReleaseAmount = lockAmount / releaseTimes;
    require(oneReleaseAmount >= _ONE, "BOXLockup: release amount too low");

    // transfer
    box.safeTransferFrom(msg.sender, address(this), lockAmount);

    // add lock
    locked[beneficiary].push(
      Lock({
        lockAmount: lockAmount,
        interval: interval,
        oneReleaseAmount: oneReleaseAmount,
        nextReleaseAt: block.timestamp + interval
      })
    );

    emit Lockup(beneficiary, lockAmount, interval, releaseTimes);
  }

  /**
   * @notice release the releaseable amount
   * @dev only the beneficiary can release BOX.
   */
  function release() external {
    uint256 releaseable;
    address beneficiary = msg.sender;

    // check and release
    for (uint256 i = 0; i < locked[beneficiary].length; i++) {
      Lock storage item = locked[beneficiary][i];
      uint256 ant = _calculate(item);
      if (ant > 0) {
        releaseable += ant;
        // update lock
        item.lockAmount -= ant;
        uint256 releaseTimes = (block.timestamp - item.nextReleaseAt) / item.interval + 1;
        item.nextReleaseAt += releaseTimes * item.interval;
      }
    }
    require(releaseable > 0, "BOXLockup: no releaseable amount");
    box.safeTransfer(beneficiary, releaseable);
    emit Released(beneficiary, releaseable);
  }

  // @dev calculate the releaseable amount
  function _calculate(Lock storage item) private view returns (uint256) {
    if (block.timestamp < item.nextReleaseAt) return 0;
    unchecked {
      uint256 balance = item.lockAmount;
      if (balance < 2 * item.oneReleaseAmount) {
        return balance;
      }
      uint256 releaseTimes = (block.timestamp - item.nextReleaseAt) / item.interval + 1;
      uint256 releaseable = item.oneReleaseAmount * releaseTimes;
      return releaseable > balance ? balance : releaseable;
    }
  }
}
