// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Eduena.sol";
import "../src/mocks/MockUSDe.sol";
import "../src/mocks/MockSUSDe.sol";

contract EduenaTest is Test {
    Eduena eduena;
    MockUSDe USDe;
    MockSUSDe sUSDe;
    address owner;
    address donor;
    address donor2;

    function setUp() public {
        owner = address(this);
        donor = address(0x123);
        donor2 = address(0x456);

        USDe = new MockUSDe();
        sUSDe = new MockSUSDe(USDe);
        eduena = new Eduena(address(USDe), address(sUSDe));

        USDe.mint(donor, 1000 ether);
        USDe.mint(donor2, 1000 ether);
    }

    function testDeposit() public {
        uint256 amount = 100 ether;

        vm.startPrank(donor);
        USDe.approve(address(eduena), amount);
        eduena.deposit(amount);
        vm.stopPrank();

        assertEq(USDe.balanceOf(address(eduena)), 0);
        assertEq(sUSDe.balanceOf(address(eduena)), amount);
        assertEq(sUSDe.totalSupply(), amount);

        //TODO: test yield, increasing the value of the asset and donor2 depositing

        vm.startPrank(donor2);
        USDe.approve(address(eduena), amount);
        eduena.deposit(amount);
        vm.stopPrank();

        // assertEq(USDe.balanceOf(address(eduena)), 0);
        // assertEq(sUSDe.balanceOf(address(eduena)), amount * 2);
        // assertEq(sUSDe.totalSupply(), amount * 2);
        
        // console.log(eduena.totalSupply());
        // console.log(eduena.lastAssetValueInUSDe());
        // console.log(eduena.totalUnclaimedYield());
    }

    function testWithdraw() public {
        uint256 depositAmount = 100 ether;
        uint256 withdrawAmount = 100 ether;

        vm.startPrank(donor);
        USDe.approve(address(eduena), depositAmount);
        eduena.deposit(depositAmount);
        vm.stopPrank();

        vm.startPrank(donor);
        eduena.withdraw(withdrawAmount);
        vm.stopPrank();

        assertEq(USDe.balanceOf(donor), 900 ether);
        assertEq(
            sUSDe.balanceOf(address(eduena)),
            depositAmount - withdrawAmount
        );
        assertEq(sUSDe.balanceOf(donor), 100 ether);
        assertEq(eduena.totalUnclaimedYield(), 0);
        assertEq(eduena.lastAssetValueInUSDe(), 0 ether);
    }

    function testDistributeScholarship() public {
        // uint256 depositAmount = 100 ether;
        // address student = address(0x123);
        // vm.startPrank(donor);
        // USDe.approve(address(eduena), depositAmount);
        // eduena.deposit(depositAmount);
        // vm.stopPrank();
        // vm.startPrank(donor);
        // eduena.distributeScholarship(student, depositAmount);
        // vm.stopPrank();
        // assertEq(USDe.balanceOf(student), depositAmount);
        // assertEq(sUSDe.balanceOf(address(eduena)), 0);
        // assertEq(sUSDe.totalSupply(), 0);
    }
}
