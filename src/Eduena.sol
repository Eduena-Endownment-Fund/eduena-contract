// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IUSDe.sol";
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

        USDe.safeTransferFrom(msg.sender, address(this), amount);
        uint256 shares = _calculateShares(amount);
        _stake(amount);
        _mint(msg.sender, shares);
        emit Deposit(msg.sender, amount);
        
        if (lastAssetValueInUSDe == 0) {
            lastAssetValueInUSDe = sUSDe.previewRedeem(sUSDe.balanceOf(address(this)));
        } 

        if (lastAssetValueInUSDe > 0) {
            uint256 yield = sUSDe.previewRedeem(sUSDe.balanceOf(address(this))) - lastAssetValueInUSDe;
            totalUnclaimedYieldInUSDe += yield;
            _mint(address(this), _calculateShares(yield));
            emit YieldUpdated(sUSDe.previewRedeem(sUSDe.balanceOf(address(this))), yield);
        }
    }

    function _stake(uint256 amount) internal {
        USDe.approve(address(sUSDe), amount);
        sUSDe.deposit(amount, address(this));
        emit Stake(amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        _withdraw(msg.sender, amount);
    }

    function _withdraw(address recipient, uint256 amount) private {
        uint256 shares = _calculateShares(amount);
        uint256 previewAmount = sUSDe.previewRedeem(shares);

        _burn(msg.sender, shares);
        sUSDe.transfer(recipient, amount);
        emit Withdraw(recipient, previewAmount);
        updateYield();
    }

    // This function is a simulation to demonstrate the distribution of scholarships to students.
    function distribute(
        address recipient,
        uint256 amount
    ) external nonReentrant {
        bool isEligible = checkEligibility(recipient);
        if (!isEligible) revert NotEligibleForScholarship();

        if (amount > totalUnclaimedYield) revert ExceedsUnclaimedYield();

        uint256 sUSDeBalance = sUSDe.balanceOf(address(this));
        if (amount > sUSDeBalance) revert InsufficientBalance();

        _withdraw(recipient, amount);
    }

    function checkEligibility(address student) internal pure returns (bool) {
        return true;
    }

    //FIXME: Fix the logic of this function
    function updateYield() public {
        if (totalSupply() == 0) {

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
