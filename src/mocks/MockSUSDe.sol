// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract MockSUSDe is ERC4626 {
    constructor(
        ERC20 _usdeToken
    ) ERC4626(_usdeToken) ERC20("Mock Staked USDe", "MSUSDe") {}
}