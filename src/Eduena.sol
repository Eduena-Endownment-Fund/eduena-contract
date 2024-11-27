// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISUSDe.sol";

error InsufficientBalance();
error DepositAmountZero();
error ExceedsUnclaimedYield();

contract Eduena is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;
    ISUSDe public sUSDe;
    IERC20 public USDe;
    uint256 public lastAssetValueInUSDe;
    uint256 public totalUnclaimedYieldInUSDe;

    event DepositAndStake(address indexed user, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);
    event Distribute(address indexed recipient, uint256 amount);
    event YieldAccrued(uint256 newAssetValueInUSDe, uint256 yield);

    /**
     * @dev Constructor to initialize the contract with USDe and sUSDe token addresses.
     * @param _USDe Address of the USDe token contract.
     * @param _sUSDe Address of the sUSDe token contract.
     */
    constructor(address _USDe, address _sUSDe) ERC20("Eduena", "EDN") {
        owner = msg.sender;
        USDe = IERC20(_USDe);
        sUSDe = ISUSDe(_sUSDe);
    }

    /**
     * @dev Deposits USDe tokens into the contract, stakes them into sUSDe, and mints corresponding shares.
     * @param amount Amount of USDe tokens to deposit.
     */
    function deposit(uint256 amount) external nonReentrant {
        accrueYield();

        if (amount == 0) revert DepositAmountZero();

        uint256 shares;

        if (totalSupply() == 0) {
            shares = sUSDe.previewRedeem(sUSDe.previewDeposit(amount));
            lastAssetValueInUSDe = sUSDe.previewRedeem(
                sUSDe.previewDeposit(amount)
            );
        } else {
            lastAssetValueInUSDe = sUSDe.previewRedeem(
                sUSDe.balanceOf(address(this))
            );
            shares = (amount * totalSupply()) / lastAssetValueInUSDe;
            lastAssetValueInUSDe += sUSDe.previewRedeem(
                sUSDe.previewDeposit(amount)
            );
        }

        _mint(msg.sender, shares);

        USDe.safeTransferFrom(msg.sender, address(this), amount);

        USDe.approve(address(sUSDe), amount);
        sUSDe.deposit(amount, address(this));

        emit DepositAndStake(msg.sender, amount);
    }

    /**
     * @dev Withdraws shares from the contract and transfers corresponding USDe tokens to the user.
     * @param shares Amount of shares to withdraw.
     */
    function withdraw(uint256 shares) external nonReentrant {
        accrueYield();

        if (shares > balanceOf(msg.sender)) revert InsufficientBalance();

        uint256 amount = (shares * sUSDe.balanceOf(address(this))) /
            totalSupply();
        lastAssetValueInUSDe -= sUSDe.previewRedeem(
            sUSDe.previewWithdraw(amount)
        );

        _burn(msg.sender, shares);
        sUSDe.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Distributes yield to a recipient by burning shares and transferring sUSDe tokens.
     * @param recipient Address of the recipient.
     * @param shares Amount of shares to distribute.
     */
    function distribute(
        address recipient,
        uint256 shares
    ) external nonReentrant {
        accrueYield();

        if (shares > totalUnclaimedYieldInUSDe) revert ExceedsUnclaimedYield();

        uint256 amount = (shares * sUSDe.balanceOf(address(this))) /
            totalSupply();
        totalUnclaimedYieldInUSDe -= shares;

        _burn(address(this), shares);

        sUSDe.transfer(recipient, amount);
        emit Distribute(msg.sender, amount);
    }

    /**
     * @dev Accrues yield by calculating the difference in asset value and minting new shares.
     */
    function accrueYield() public {
        uint256 currentAssetValueInUSDe = sUSDe.previewRedeem(
            sUSDe.balanceOf(address(this))
        );

        uint256 yield = currentAssetValueInUSDe > lastAssetValueInUSDe
            ? currentAssetValueInUSDe - lastAssetValueInUSDe
            : 0;

        totalUnclaimedYieldInUSDe += yield;

        uint256 shares;
        if (totalSupply() == 0) {
            shares = yield;
        } else {
            shares = (yield * totalSupply()) / lastAssetValueInUSDe;
        }

        _mint(address(this), shares);
        emit YieldAccrued(currentAssetValueInUSDe, yield);
        lastAssetValueInUSDe = currentAssetValueInUSDe;
    }
}
