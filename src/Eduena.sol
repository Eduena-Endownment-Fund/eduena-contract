// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISUSDe.sol";
import "forge-std/console.sol"; //NOTE: testing only

error InsufficientBalance();
error OnlyOwner();
error DepositAmountZero();
error InsufficientYield();
error ExceedsUnclaimedYield();
error NotEligibleForScholarship();

contract Eduena is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;
    ISUSDe public sUSDe;
    IERC20 public USDe;
    uint256 public lastAssetValueInUSDe;
    uint256 public totalUnclaimedYieldInUSDe;

    event Deposit(address indexed donor, uint256 amount);
    event Stake(uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);
    event YieldUpdated(uint256 newAssetValueInUSDe, uint256 yield);

    constructor(address _USDe, address _sUSDe) ERC20("Eduena", "EDN") {
        owner = msg.sender;
        USDe = IERC20(_USDe);
        sUSDe = ISUSDe(_sUSDe);
    }

    function deposit(uint256 amount) external nonReentrant {
        if (amount == 0) revert DepositAmountZero();

        uint256 shares;

        if (totalSupply() == 0) {
            shares = amount;
            lastAssetValueInUSDe = amount;
        } else {
            shares = (amount * totalSupply()) / lastAssetValueInUSDe;
            lastAssetValueInUSDe += amount;
        }

        _mint(msg.sender, shares);
        emit Deposit(msg.sender, amount);

        USDe.safeTransferFrom(msg.sender, address(this), amount);
        _stake(amount);
        updateYield();
    }

    function _stake(uint256 amount) internal {
        USDe.approve(address(sUSDe), amount);
        sUSDe.deposit(amount, address(this));
        emit Stake(amount);
    }

    function withdraw(uint256 shares) external nonReentrant {
        if (shares > balanceOf(msg.sender)) revert InsufficientBalance();

        _withdraw(msg.sender, shares);
    }

    function _withdraw(address recipient, uint256 shares) private {
        uint256 amount = (shares * sUSDe.balanceOf(address(this))) /
            totalSupply();

        _burn(recipient, shares);
        sUSDe.transfer(recipient, amount);
        emit Withdraw(msg.sender, amount);
        updateYield();
    }

    function distribute(
        address recipient,
        uint256 amount
    ) external nonReentrant {
        if (amount > totalUnclaimedYieldInUSDe) revert ExceedsUnclaimedYield();

        uint256 sUSDeBalance = sUSDe.balanceOf(address(this));
        if (amount > sUSDeBalance) revert InsufficientBalance();

        _withdraw(recipient, amount);
    }

    //FIXME: Fix the logic of this function
    function updateYield() private {
        uint256 currentAssetValueInUSDe = sUSDe.previewRedeem(
            sUSDe.balanceOf(address(this))
        );
        console.log(lastAssetValueInUSDe);
        console.log(currentAssetValueInUSDe);

        if (currentAssetValueInUSDe < lastAssetValueInUSDe) {
            totalUnclaimedYieldInUSDe = 0;
        } else {
            uint256 yield = currentAssetValueInUSDe - lastAssetValueInUSDe;
            totalUnclaimedYieldInUSDe += yield;

            _mint(address(this), _calculateShares(yield));
            emit YieldUpdated(
                sUSDe.previewRedeem(sUSDe.balanceOf(address(this))),
                yield
            );
        }
    }

    function _calculateShares(uint256 amount) internal view returns (uint256) {
        if (totalSupply() == 0) {
            return amount;
        } else {
            return (amount * totalSupply()) / lastAssetValueInUSDe;
        }
    }
}
