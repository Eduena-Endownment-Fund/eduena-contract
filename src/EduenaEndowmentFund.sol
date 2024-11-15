// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IUSDe.sol";
import "forge-std/console.sol"; //NOTE: testing only

error InsufficientShares();
error InsufficientFunds();
error InsufficientBalance();
error OnlyOwner();
error DepositAmountZero();
error InsufficientYield();

contract EduenaEndowmentFund is ReentrancyGuard, ERC20 {
    using SafeERC20 for IERC20;

    address public owner;
    ISUSDe public sUSDe;
    IERC20 public USDe;
    uint256 public totalShares;
    uint256 public lastAssetValueInUSDe;
    uint256 public totalUnclaimedYield;
    mapping(address => uint256) public donorShares;

    event Deposit(address indexed donor, uint256 amount);
    event Stake(uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);
    event YieldUpdated(uint256 newAssetValueInUSDe, uint256 yield);

    constructor(address _USDeAddress, address _sUSDeAddress) {
        owner = msg.sender;
        USDe = IERC20(_USDeAddress);
        sUSDe = ISUSDe(_sUSDeAddress);
    }

    function poolBalance() public view returns (uint256) {
        return USDe.balanceOf(address(this));
    }
    
    function deposit(uint256 amount) external nonReentrant {
        if (amount == 0) revert DepositAmountZero();

        USDe.safeTransferFrom(msg.sender, address(this), amount);

        uint256 shares;
        if (totalShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalShares) / lastAssetValueInUSDe;
        }

        donorShares[msg.sender] += shares;
        totalShares += shares;
        emit Deposit(msg.sender, amount);

        _stake(amount);
        updateYield();
    }

    function _stake(uint256 amount) internal {
        USDe.approve(address(sUSDe), amount);
        sUSDe.deposit(amount, address(this));
        emit Stake(amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        uint256 shares = (amount * totalShares) / lastAssetValueInUSDe;
        if (donorShares[msg.sender] < shares) revert InsufficientShares();

        uint256 previewAmount = sUSDe.previewRedeem(shares);
        if (previewAmount < amount) revert InsufficientFunds();

        donorShares[msg.sender] -= shares;
        totalShares -= shares;

        //FIXME: Fix the withdraw to the donor as a sUSDe
        sUSDe.transfer(shares, msg.sender, address(this));
        emit Withdraw(msg.sender, previewAmount);
        updateYield();
    }

    //TODO: Implement the distribute function to distribute the returns to eligible students verified by scholarships creator
    //TODO: Use scholarship manager to handle the scholarship creation and verification
    function distribute(address payable student, uint256 amount) external {
        if (msg.sender != owner) revert OnlyOwner();
        if (amount > totalUnclaimedYield) revert InsufficientYield();

        uint256 sUSDeBalance = sUSDe.balanceOf(address(this));
        if (amount > sUSDeBalance) revert InsufficientBalance();

        uint256 previewAmount = sUSDe.previewRedeem(amount);
        // sUSDe.redeem(amount);
        USDe.safeTransfer(student, previewAmount);
        totalUnclaimedYield -= amount;

        emit Withdraw(student, previewAmount);
        updateYield();
    }

    function updateYield() public {
        //todo: Implement the yield calculation
        uint256 sUSDeBalance = sUSDe.balanceOf(address(this));

        uint256 assetValueInUSDe = sUSDe.previewDeposit(sUSDeBalance);
        lastAssetValueInUSDe = assetValueInUSDe;
        uint256 yield = assetValueInUSDe - lastAssetValueInUSDe;
        uint256 shares = (yield * totalShares) / lastAssetValueInUSDe;

        _mint(address(this), shares);

        totalUnclaimedYield += yield;
        emit YieldUpdated(assetValueInUSDe, yield);
    }
}
