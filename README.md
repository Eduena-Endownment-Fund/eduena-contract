## Eduena Frontend

[Eduena Frontend](https://github.com/Eduena-Endownment-Fund/eduena-web)

## Smart Contract Functionality

The `Eduena` contract in [`src/Eduena.sol`](src/Eduena.sol)

### Functions

- **deposit(uint256 amount)**: Allows users to deposit a specified amount of USDe tokens and it immediately staked to sUSDe. The equivalent amount of Eduena tokens (EDN) is minted and assigned to the user.
- **withdraw(uint256 shares)**: Allows users to withdraw a specified amount of Eduena tokens (EDN). The equivalent amount of sUSDe tokens is transferred back to the user.
- **distribute(address recipient, uint256 shares)**: Distributes a specified amount of yield to a recipient.
- **accrueYield()**: Updates the yield based on the current asset value in USDe.

### Events

- **DepositAndStake(address indexed user, uint256 amount)**: Emitted when a deposit is made and staked.
- **Withdraw(address indexed recipient, uint256 amount)**: Emitted when a withdrawal is made.
- **Distribute(address indexed recipient, uint256 amount)**: Emitted when yield is distributed.
- **YieldAccrued(uint256 newAssetValueInUSDe, uint256 yield)**: Emitted when the yield is updated.

### Errors

- **InsufficientBalance()**: Thrown when a user tries to withdraw more than their balance.
- **DepositAmountZero()**: Thrown when a deposit amount is zero.
- **ExceedsUnclaimedYield()**: Thrown when the amount exceeds the unclaimed yield.

## Testing

The `EduenaTest` contract in [`test/Eduena.t.sol`](test/Eduena.t.sol) includes tests for the deposit and withdrawal functionalities.

### Example Test Functions

```solidity
function testDepositAndWithdraw() public {
    // Test deposit and withdrawal functionality
}

function testAccrueYield() public {
    // Test yield accrual functionality
}
```

### Setting Up Environment Variables

To run the tests, you need to set up the following environment variables in a `.env` file:

```env
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/account_key_xxx
FORK_BLOCK_NUMBER=21272472
```

Running the Tests
To run the tests using Foundry, use the following command:

```
forge test
```

### Deployment

The Eduena contract is deployed on [Tenderly](https://tenderly.co/) for testing purposes.

#### Fund account

Fund VETH for gas fee:

```
curl --location 'https://virtual.mainnet.rpc.tenderly.co/fad38b2e-0b26-4b16-b2c3-c24ac629af36' \
--header 'Content-Type: application/json' \
--data '{
  "jsonrpc": "2.0",
  "method": "tenderly_setBalance",
  "params": [["USER_WALLET_ADDRESS"], "0x152d02c7e14af6000000"]
}'
```

Fund your account with USDe for testing Eduena deposits. The first parameter is the USDe contract address, the second parameter is your wallet address, and the third parameter is a 32-byte hash representing the token amount in wei. The example below sets a balance of $100,000 USDe to the user's address.

```
curl --location 'https://virtual.mainnet.rpc.tenderly.co/fad38b2e-0b26-4b16-b2c3-c24ac629af36' \
--header 'Content-Type: application/json' \
--data '{
    "jsonrpc": "2.0",
    "method": "tenderly_setErc20Balance",
    "params": [
        "0x4c9EDD5852cd905f086C759E8383e09bff1E68B3",
        "USER_WALLET_ADDRESS",
        "0x152d02c7e14af6000000"
    ]
}'
```

#### Deploy smart contract

```
echo "
unknown_chain = { key = \"${TENDERLY_ACCESS_KEY}\", chain = 1, url = \"https://virtual.mainnet.rpc.tenderly.co/fad38b2e-0b26-4b16-b2c3-c24ac629af36\" }" >> foundry.toml

forge create Eduena \
--private-key $PRIVATE_KEY \
--rpc-url https://virtual.mainnet.rpc.tenderly.co/fad38b2e-0b26-4b16-b2c3-c24ac629af36 \
--etherscan-api-key $TENDERLY_ACCESS_KEY \
--verify \
--verifier-url https://virtual.mainnet.rpc.tenderly.co/fad38b2e-0b26-4b16-b2c3-c24ac629af36/verify/etherscan \
--constructor-args 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497
```
