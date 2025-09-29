// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;
    // us -> FundMeTest -> FundMe

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    // function testUserCanFundInteractions() public {
    //     FundFundMe fundFundMe = new FundFundMe();
    //     vm.prank(USER);
    //     fundFundMe.fundFundMe{value: SEND_VALUE}(address(fundMe));

    //     // USER funds with 1 ether
    //     WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
    //     vm.prank(fundMe.getOwner());
    //     withdrawFundMe.withdrawFundMe(address(fundMe));

    //     // impersonate the contract owner

    //     assert(address(fundMe).balance == 0);
    // }
    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        vm.prank(USER);
        fundFundMe.fundFundMe{value: SEND_VALUE}(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
