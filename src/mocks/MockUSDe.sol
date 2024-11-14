// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDe is ERC20 {
    constructor() ERC20("Mock USDe", "mUSDe") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}