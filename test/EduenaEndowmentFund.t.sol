// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/EduenaEndowmentFund.sol";
import "../src/mocks/MockUSDe.sol";
import "../src/mocks/MockSUSDe.sol";

contract EduEnaTest is Test {
    EduenaEndowmentFund eduEna;
    MockUSDe USDe;
    MockSUSDe sUSDe;
    address owner;
    address donor;

    function setUp() public {
        owner = address(this);
        donor = address(0x123);

        USDe = new MockUSDe();
        sUSDe = new MockSUSDe(USDe);
        eduEna = new EduenaEndowmentFund(address(USDe), address(sUSDe));

        USDe.mint(donor, 1000 ether);
    }

    function testDeposit() public {
        uint256 amount = 100 ether;

        vm.startPrank(donor);
        USDe.approve(address(eduEna), amount);
        eduEna.deposit(amount);
        vm.stopPrank();

        assertEq(eduEna.donorShares(donor), amount);
        assertEq(USDe.balanceOf(address(eduEna)), 0);
        assertEq(sUSDe.balanceOf(address(eduEna)), amount);
    }

    function testWithdraw() public {
        uint256 depositAmount = 100 ether;
        uint256 withdrawAmount = 50 ether;

        vm.startPrank(donor);
        USDe.approve(address(eduEna), depositAmount);
        eduEna.deposit(depositAmount);
        vm.stopPrank();

        vm.startPrank(donor);
        uint256 donorBalance = USDe.balanceOf(donor);
        eduEna.withdraw(withdrawAmount);
        vm.stopPrank();

        assertEq(eduEna.donorShares(donor), depositAmount - withdrawAmount);
        //FIXME: assert sUSDe balance of donor, instead of USDe balance of donor
        assertEq(USDe.balanceOf(donor), withdrawAmount + donorBalance);
        assertEq(sUSDe.balanceOf(address(eduEna)), depositAmount - withdrawAmount);

        console.log("sUSDe balance of donor: %s", sUSDe.balanceOf(donor));
        console.log("USDe balance of donor: %s", USDe.balanceOf(donor));
        console.log(
            "sUSDe balance of eduEna contract: %s",
            sUSDe.balanceOf(address(eduEna))
        );
    }
}
