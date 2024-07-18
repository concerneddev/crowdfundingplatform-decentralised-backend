//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Campaign.sol";

contract CampaignFactory {
    error CampaignFactory__InvalidGoalAmount();
    
    struct CampaignInfo {
        address campaignAddress;
        uint256 goalAmount;
    }
    mapping(address => CampaignInfo) public s_ownerToCampaigns;
    Campaign[] public s_campaigns;
    address[] public s_owners;

    event CampaignContractCreated(address campaignContract, address owner, uint256 goalAmount);

    function createDonation(uint256 goalAmount) external {
        if (goalAmount <= 0) {
            revert CampaignFactory__InvalidGoalAmount();
        }
        Campaign newCampaign = new Campaign(msg.sender, goalAmount);
        s_campaigns.push(newCampaign);
        CampaignInfo memory newCampaignInfo = CampaignInfo({
            campaignAddress: address(newCampaign),
            goalAmount: goalAmount
        });
        s_ownerToCampaigns[msg.sender] = newCampaignInfo;
        s_owners.push(msg.sender);

        emit CampaignContractCreated(newCampaignInfo.campaignAddress, msg.sender, newCampaignInfo.goalAmount);
    }

    // getter functions
    function getTotalCampaigns() external view returns(uint256) {
        return s_campaigns.length;
    }

    function getCampaignContracts() external view returns(Campaign[] memory){
        return s_campaigns;
    }

    function getRecentCampaign() external view returns(Campaign) {
        return s_campaigns[s_campaigns.length - 1];
    } 

    function getCampaignInfoByOwner(address owner) external view returns(address campaignAddress, uint256 goalAmount) {
        require(s_campaigns.length > 0, "No campaigns deployed yet!");
        CampaignInfo memory info = s_ownerToCampaigns[owner];
        return (info.campaignAddress, info.goalAmount);
    }

    function getRecentCamapaignInfo() external view returns(address owner, address campaignAddress, uint256 goalAmount) {
        require(s_campaigns.length > 0, "No campaigns deployed yet!");
        address campaignOwner = s_campaigns[s_campaigns.length - 1].getOwner();
        CampaignInfo memory info = s_ownerToCampaigns[campaignOwner];
        return (campaignOwner, info.campaignAddress, info.goalAmount);
    }

    function getOwners() external view returns(address[] memory) {
        return s_owners;
    }
}