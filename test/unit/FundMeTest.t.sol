// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 20 ether;
    uint256 constant MINIMUM_USD = 5e18;
    uint256 constant VERSION = 10;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        console.log("Address of FundMeTest contract is ", address(this));
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        console.log("value of msg.sender is ", msg.sender);
        console.log("address of FundMeTest contract ", address(this));
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarValueIsFive() public view {
        console.log("Function to test the minimum dollar value");
        assertEq(fundMe.getMinimumUsd(), MINIMUM_USD);
    }

    function testOwnerisContractCreator() public view {
        console.log(
            "Testing to see if the contract owner is msg.sender(contract creater)"
        );
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testToCheckVersionOfPriceFeed() public view {
        console.log("Testing to check the version of price feed");
        console.log("eth price ", fundMe.getLatestEthPrice());
        assertEq(fundMe.getVersion(), VERSION);
    }

    function testIfFundFailsWithoutMinimumEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funder {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testOnlyOwnerCanWithdrawFunds() public funder {
        // vm.prank(fundMe.getOwner());
        vm.expectRevert();
        fundMe.withdraw();
    }

    modifier funder() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunders() public funder {
        address funderAddress = fundMe.getFunder(0);
        assertEq(funderAddress, USER);
    }

    function testWithdrawWithSingleFunder() public funder {
        uint256 startingBalanceOwner = fundMe.getOwner().balance;
        uint256 startingBalanceFundMe = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingBalanceOwner = fundMe.getOwner().balance;
        uint256 endingBalanceFundMe = address(fundMe).balance;

        assertEq(endingBalanceFundMe, 0);
        assertEq(
            endingBalanceOwner,
            startingBalanceOwner + startingBalanceFundMe
        );
    }

    function testWithdrawWithMultipleFunders() public funder {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingBalanceOwner = fundMe.getOwner().balance;
        uint256 startingBalanceFundMe = address(fundMe).balance;

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        uint256 endingBalanceOwner = fundMe.getOwner().balance;
        uint256 endingBalanceFundMe = address(fundMe).balance;

        assertEq(endingBalanceFundMe, 0);
        assertEq(
            endingBalanceOwner,
            startingBalanceFundMe + startingBalanceOwner
        );
    }
}
