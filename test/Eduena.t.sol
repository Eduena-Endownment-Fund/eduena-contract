// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Eduena.sol";
import "../src/interfaces/ISUSDe.sol";

contract EduenaTest is Test {
    IERC20 usde;
    ISUSDe susde;
    address usdeAddress = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address susdeAddress = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    Eduena eduena;

    function setUp() public {
        string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
        uint256 blockNumber = vm.envUint("FORK_BLOCK_NUMBER");

        vm.createSelectFork(rpcUrl, blockNumber);
        usde = IERC20(usdeAddress);
        susde = ISUSDe(susdeAddress);
        eduena = new Eduena(address(usde), address(susde));
    }

    function testDepositAndWithdraw() public {
        //Setup initial user and deposit
        address[] memory users = new address[](3);
        users[0] = address(0x123);
        users[1] = address(0x456);
        users[2] = address(0x789);
        uint256 amount = 100000 ether;

        //Deposit and stake for each user
        for (uint256 i = 0; i < users.length; i++) {
            deal(address(usde), users[i], amount);
            vm.startPrank(users[i]);
            usde.approve(address(eduena), amount);
            eduena.deposit(amount);
            vm.stopPrank();
        }

        //Ensure all usde is staked to susde
        assertEq(usde.balanceOf(address(eduena)), 0);

        //Withdraw all funds
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            eduena.withdraw(eduena.balanceOf(users[i]));
            vm.stopPrank();
            assertEq(eduena.balanceOf(users[i]), 0);
            assertEq(usde.balanceOf(users[i]), 0);
        }

        //Distribute any remaining yield
        address recipient = address(0x111);
        vm.startPrank(recipient);
        eduena.distribute(recipient, eduena.totalUnclaimedYieldInUSDe());
        vm.stopPrank();

        //Ensure all funds are withdrawn
        assertEq(eduena.totalSupply(), 0);
        assertEq(eduena.totalUnclaimedYieldInUSDe(), 0);
        assertEq(susde.balanceOf(address(eduena)), 0);
    }

    function testAccrueYield() public {
        // Setup initial user and deposit
        address user = address(0x123);
        uint256 amount = 100000 ether;
        deal(address(usde), user, amount);
        vm.startPrank(user);
        usde.approve(address(eduena), amount);
        eduena.deposit(amount);
        vm.stopPrank();

        // Rewarder deposits yield
        address rewarder = address(0x456);
        deal(address(usde), rewarder, 300_000_000 ether);
        vm.startPrank(rewarder);
        usde.transfer(susdeAddress, 300_000_000 ether);
        vm.stopPrank();

        // Setup second user and deposit
        address user2 = address(0x456);
        deal(address(usde), user2, amount);
        vm.startPrank(user2);
        usde.approve(address(eduena), amount);
        eduena.deposit(amount);
        vm.stopPrank();

        // Rewarder deposits more yield
        deal(address(usde), rewarder, 300_000_000 ether);
        vm.startPrank(rewarder);
        usde.transfer(susdeAddress, 300_000_000 ether);
        vm.stopPrank();

        // Setup third user and deposit
        address user3 = address(0x789);
        deal(address(usde), user3, amount);
        vm.startPrank(user3);
        usde.approve(address(eduena), amount);
        eduena.deposit(amount);
        vm.stopPrank();

        // Withdraw all funds for each user
        address[] memory users = new address[](3);
        users[0] = user;
        users[1] = user2;
        users[2] = user3;

        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            eduena.withdraw(eduena.balanceOf(users[i]));
            assertEq(eduena.balanceOf(users[i]), 0);
            vm.stopPrank();
        }

        //Distribute any remaining yield
        address recipient = address(0x111);
        vm.startPrank(recipient);
        eduena.distribute(recipient, eduena.totalUnclaimedYieldInUSDe());
        vm.stopPrank();

        // Ensure all funds are withdrawn
        assertEq(eduena.totalSupply(), 0);
        assertEq(susde.balanceOf(address(eduena)), 0);
    }
}
