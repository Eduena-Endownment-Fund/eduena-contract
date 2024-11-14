// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISUSDe {
    function approve(address spender, uint256 amount) external;

    function transfer(
        address to,
        uint256 amount
    ) external returns (uint256);

    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address _owner
    ) external returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}
