// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    // us -> FundMeTest -> FundMe

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        vm.deal(USER, STARTING_BALANCE);

        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        // test i_owner == fundMeTest using address(this)
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        console.log("Aggregator version:", version);
        assertGt(version, 0); // just check it's > 0, i.e. valid
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // expect the next line to revert
        fundMe.fund(); // with no value sent, should revert
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testWithdrawFailsForNonOwner() public funded {
        vm.prank(USER);
        // Expect the call to revert
        vm.expectRevert();
        // Try withdrawing as the non-owner
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal that address some ETH

            hoax(address(i), SEND_VALUE); // does both vm.prank and vm.deal
            fundMe.fund{value: SEND_VALUE}(); // have each of those addresses
                // that address funds the fundMe contract
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
    }

    // Make sure that the funders are reset properly
    function testCheapWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal that address some ETH

            hoax(address(i), SEND_VALUE); // does both vm.prank and vm.deal
            fundMe.fund{value: SEND_VALUE}(); // have each of those addresses
                // that address funds the fundMe contract
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        assertEq(address(fundMe).balance, 0); // should be drained
        assertGe(fundMe.getOwner().balance, startingOwnerBalance + startingFundMeBalance); // allow gas cost difference
    }

    // Make sure that the funders are reset properly
}
