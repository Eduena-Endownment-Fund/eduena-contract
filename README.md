# Eduena

## Eduena Frontend
[Eduena Frontend](https://github.com/Eduena-Endownment-Fund/eduena-web)

## Eduena Smart Contract

The `Eduena` smart contract is an ERC20 token that allows users to deposit and withdraw USDe tokens, stake them to earn yield, and distribute yield. It includes the following key functions:

### Smart Contract Functionality

#### Functions

- **deposit(uint256 amount)**: Allows users to deposit a specified amount of USDe tokens and it immediately staked to sUSDe. The equivalent amount of Eduena tokens (EDN) is minted and assigned to the user.
- **withdraw(uint256 shares)**: Allows users to withdraw a specified amount of Eduena tokens (EDN). The equivalent amount of sUSDe tokens is transferred back to the user.
- **distribute(address recipient, uint256 amount)**: Distributes a specified amount of yield to a recipient.
- **updateYield()**: Updates the yield based on the current asset value in USDe.

#### Events

- **Deposit(address indexed donor, uint256 amount)**: Emitted when a deposit is made.
- **Stake(uint256 amount)**: Emitted when tokens are staked.
- **Withdraw(address indexed recipient, uint256 amount)**: Emitted when a withdrawal is made.
- **YieldUpdated(uint256 newAssetValueInUSDe, uint256 yield)**: Emitted when the yield is updated.

#### Errors

- **InsufficientBalance()**: Thrown when a user tries to withdraw more than their balance.
- **OnlyOwner()**: Thrown when a non-owner tries to perform an owner-only action.
- **DepositAmountZero()**: Thrown when a deposit amount is zero.
- **InsufficientYield()**: Thrown when there is insufficient yield.
- **ExceedsUnclaimedYield()**: Thrown when the amount exceeds the unclaimed yield.

#### Testing

The `EduenaTest` contract in `test/Eduena.t.sol` includes tests for the deposit and withdrawal functionalities.

```solidity
function testDeposit() public {
    // Test deposit functionality
}

function testWithdraw() public {
    // Test withdraw functionality
}

