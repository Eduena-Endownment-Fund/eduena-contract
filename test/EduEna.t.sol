// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Eduena.sol";
import "../src/interfaces/ISUSDe.sol";
import "../src/mocks/MockUSDe.sol";
import "../src/mocks/MockSUSDe.sol";

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

    function testDeposit() public {
        address user = address(0x123);
        uint256 amount = 100 ether;

        deal(address(usde), user, amount);
        vm.startPrank(user);
        usde.approve(address(eduena), amount);
        eduena.deposit(amount);
        vm.stopPrank();

        uint256 finalSusdeBalance = susde.balanceOf(address(eduena));

        assertEq(usde.balanceOf(address(eduena)), 0);
        assertEq(usde.balanceOf(user), 0);
        assertEq(finalSusdeBalance, susde.previewDeposit(amount));
        assertEq(eduena.totalSupply(), amount);
        assertEq(eduena.totalUnclaimedYieldInUSDe(), 0);

        console.log(susde.totalAssets());

        vm.makePersistent(address(eduena));

        vm.rollFork(21185274);

        address user2 = address(0x123);
        deal(address(usde), user2, amount);
        vm.startPrank(user2);
        usde.approve(address(eduena), amount);
        eduena.deposit(amount);
        vm.stopPrank();

        console.log(susde.totalAssets());
    }

    function testWithdraw() public {}

    function testDistributeScholarship() public {}
}
