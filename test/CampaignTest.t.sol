//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DeployCampaignFactory} from "script/DeployCampaignFactory.s.sol";
import {CampaignFactory} from "src/CampaignFactory.sol";
import {Campaign} from "src/Campaign.sol";

contract CampaignTest is Test {
    CampaignFactory public factory;
    Campaign public deployedCampaign;

    event DonationReceived(address mostRecentDonor, uint256 mostRecentDonationAmount);
    event CampaignWillBeClosedAfterTransfer();
    event GoalAmountNotReached(uint256 goalAmount, uint256 currentAmount);
    event CampaignClosed(uint256 finalAmount);

    address public constant USER = address(1); 
    address public constant USER2 = address(2);

    uint256 public constant GOAL_AMOUNT = 5 ether;
    uint256 public constant GOAL_AMOUNT2 = 7 ether;
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployCampaignFactory deployer = new DeployCampaignFactory();
        (factory) = deployer.deployCampaignFactory();
        vm.deal(USER2, STARTING_BALANCE);
        vm.deal(USER, STARTING_BALANCE);

        vm.startPrank(USER);
        factory.createDonation(GOAL_AMOUNT);
        deployedCampaign = Campaign(factory.getRecentCampaign());
        vm.stopPrank();
    }

    function testCampaignConstructorVariables() public {
        address expectedOwner = address(USER);
        uint256 expectedGoalAmount = GOAL_AMOUNT;
        uint256 expectedCurrentAmount = 0;

        assertEq(expectedOwner, deployedCampaign.getOwner());
        assertEq(expectedGoalAmount, deployedCampaign.getGoalAmount());
        assertEq(expectedCurrentAmount, deployedCampaign.getCurrentAmount());
    }

    function testCampaignConstructorCampaignState() public {
        assert(deployedCampaign.getCampaignState() == deployedCampaign.getCampaignState());
        vm.stopPrank();
    }

    ////////////////////
    ///// donate() /////
    ////////////////////

    function testCampaignRevertsOnInvalidDonation() public {
        vm.expectRevert(Campaign.Campaign__AmountMustBeMoreThanZero.selector);
        vm.startPrank(USER2);
        deployedCampaign.donate{value: 0}();
    }

    function testCampaignRevertsIfStateClosed() public {
        vm.startPrank(USER);
        deployedCampaign.closeCampaign();
        vm.stopPrank();

        vm.expectRevert(Campaign.Campaign__CampaignNotOpen.selector);
        vm.startPrank(USER2);
        deployedCampaign.donate{value: 1 ether}();
    }

    function testCampaignCurrentAmountUpdates() public {
        vm.startPrank(USER2);
        deployedCampaign.donate{value: 1 ether}();

        uint256 expectedBalance = 1 ether;
        uint256 actualBalance = deployedCampaign.getCurrentAmount();

        assertEq(expectedBalance, actualBalance);
    }

    function testCampaignMappingUpdates() public {
        vm.startPrank(USER2);
        deployedCampaign.donate{value: 1 ether}();

        uint256 expectedAmount = 1 ether;
        uint256 actualAmount = deployedCampaign.getDonationAmount(address(USER2));

        assertEq(expectedAmount, actualAmount);
    }

    function testCampaignDonorsUpdate() public {
        vm.startPrank(USER2);
        deployedCampaign.donate{value: 1 ether}();

        address expectedAddress = address(USER2);
        address actualAddress = deployedCampaign.getRecentDonor();

        assertEq(expectedAddress, actualAddress);
    }

    function testCampaignEmitsDonationEvent() public {
        vm.startPrank(USER2);

        vm.expectEmit(address(deployedCampaign));
        emit DonationReceived(USER2, 1 ether);

        deployedCampaign.donate{value: 1 ether}();
    }

    //////////////////////
    ///// withdraw() /////
    //////////////////////

    modifier donated(){
        vm.startPrank(USER2);
        deployedCampaign.donate{value: 1 ether}();
        _;
    }

    function testCampaignOnlyOwnerWithdraws() public donated{   
        vm.expectRevert(Campaign.Campaign__NotOwner.selector);     
        vm.startPrank(USER2);
        deployedCampaign.withdraw();
    }

    function testCampaignNoDonationsYet() public{
        vm.expectRevert(Campaign.Campaign__NoDonationsYet.selector);
        vm.startPrank(USER);
        deployedCampaign.withdraw();
    }

    function testCampaignGoalAmountNotReachedWithdrawEmits() public donated{
        vm.startPrank(USER);

        vm.expectEmit(address(deployedCampaign));
        emit GoalAmountNotReached(GOAL_AMOUNT, deployedCampaign.getCurrentAmount());
        emit CampaignWillBeClosedAfterTransfer();

        deployedCampaign.withdraw();
    }

    function testCampaignWithdrawCampaignCloseEmits() public donated{
        vm.startPrank(USER);

        vm.expectEmit(address(deployedCampaign));
        emit CampaignClosed(deployedCampaign.getCurrentAmount());

        deployedCampaign.withdraw();
    }

    function testCampaignWithdrawTransfersCorrectly() public donated{
        vm.startPrank(USER);
        deployedCampaign.withdraw();

        uint256 userBalance = address(USER).balance;
        assertEq(userBalance, deployedCampaign.getFinalAmount() + STARTING_BALANCE);
    }

    function testCampaignWithrdrawCurrentFinalUpdates() public donated{
        vm.startPrank(USER);
        
        deployedCampaign.withdraw();

        assertEq(deployedCampaign.getFinalAmount(), 1 ether);
        assertEq(deployedCampaign.getCurrentAmount(), 0);
    }

    // multiple donors
    modifier multipleDonated() {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 3;
        for(uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++){
            hoax(address(i), STARTING_BALANCE);
            deployedCampaign.donate{value: 1 ether}();
        }
        _;
    }

    function testCampaignMultipleDonors() public multipleDonated{
        vm.startPrank(USER);   
        deployedCampaign.withdraw();

        uint256 userBalance = address(USER).balance;
        assertEq(userBalance, deployedCampaign.getFinalAmount() + STARTING_BALANCE);        
        assertEq(deployedCampaign.getCurrentAmount(), 0);
        assertEq(address(deployedCampaign).balance, 0);
        assertEq(deployedCampaign.getFinalAmount(), 10 ether);
    }

    // miscellaneous

    function testCamapaignGetRecentDonationAmount() public multipleDonated(){
        vm.startPrank(USER);
        address[] memory donors = deployedCampaign.getAllDonors();
        uint256 amount = deployedCampaign.getRecentDonationAmount();
        assertEq(amount, 1 ether);
    }
}


