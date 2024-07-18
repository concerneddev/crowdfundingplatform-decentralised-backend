//SPDX-License-Identifier: MIT

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DeployCampaignFactory} from "script/DeployCampaignFactory.s.sol";
import {CampaignFactory} from "src/CampaignFactory.sol";
import {Campaign} from "src/Campaign.sol";

contract CampaignFactoryTest is Test{
    CampaignFactory public factory;

    address public constant USER = address(1); 
    address public constant USER2 = address(2);
    uint256 public constant GOAL_AMOUNT = 5 ether;
    uint256 public constant GOAL_AMOUNT2 = 7 ether;
    
    function setUp() external {
        DeployCampaignFactory deployer = new DeployCampaignFactory();
        (factory) = deployer.deployCampaignFactory();
    }

    function testFactoryDeploysContract() public {
        vm.startPrank(USER);
        factory.createDonation(GOAL_AMOUNT);
        Campaign[] memory campaigns = factory.getCampaignContracts();

        vm.stopPrank();
        assertEq(campaigns.length, 1);
    }

    // Testing the mappings
    function testFactoryRecentCampaignInfo() public {
        vm.startPrank(USER);
        factory.createDonation(GOAL_AMOUNT);
        Campaign expectedCampaign = factory.getRecentCampaign();
        address expectedOwner = address(USER);
        uint256 expectedGoalAmount = GOAL_AMOUNT;

        (address actualOwner, address actualCampaignAddress, uint256 actualGoalAmount) = factory.getRecentCamapaignInfo();
        vm.stopPrank();

        assertEq(address(expectedCampaign), actualCampaignAddress);
        assertEq(expectedGoalAmount, actualGoalAmount);
        assertEq(expectedOwner, actualOwner);
    }
    
    function testFactoryCampaignInfoByOwner() public {
        vm.startPrank(USER2);
        factory.createDonation(GOAL_AMOUNT2);
        vm.stopPrank();

        vm.startPrank(USER);
        factory.createDonation(GOAL_AMOUNT);

        Campaign[] memory campaignContracts = factory.getCampaignContracts();
        Campaign expectedContract = campaignContracts[0];
        address expectedOwner = address(USER2);
        uint256 expectedGoalAmount = GOAL_AMOUNT2;
        
        (address actualContract, uint256 actualGoalAmount) = factory.getCampaignInfoByOwner(address(USER2)); 
        address actualOwner = Campaign(actualContract).getOwner();
        vm.stopPrank();

        assertEq(expectedOwner, actualOwner);
        assertEq(expectedGoalAmount, actualGoalAmount);
        assertEq(address(expectedContract), actualContract);
    }

    function testFactoryOwnersArray() public {
        vm.startPrank(USER);
        factory.createDonation(GOAL_AMOUNT);
        vm.stopPrank();

        vm.startPrank(USER2);
        factory.createDonation(GOAL_AMOUNT2);
        
        address expectedOwner1 = USER;
        address expectedOwner2 = USER2;
        
        address[] memory ownersArray = factory.getOwners();
        vm.stopPrank();

        assertEq(expectedOwner1, ownersArray[0]);
        assertEq(expectedOwner2, ownersArray[1]);
    }

    function testDonationRevertsOnInvalidGoalAmount() public {
        vm.expectRevert();
        vm.prank(USER);
        factory.createDonation(0);
    }
}