//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Campaign {
    error Campaign__CampaignNotOpen();
    error Campaign__NotOwner();
    error Campaign__AmountMustBeMoreThanZero();

    enum CampaignState {
        OPEN,
        CLOSE
    }

    address private immutable i_owner;
    address[] private s_donors;
    mapping(address => uint256) private s_addressToAmountDonated;
    uint256 private immutable i_goalAmount;
    uint256 private s_currentAmount;
    CampaignState private s_campaignState;

    event CampaignOpened(address campaignOwner, uint256 goalAmount);
    event DonationReceived(address mostRecentDonor, uint256 mostRecentDonationAmount);
    event CampaignClosed(uint256 finalAmount);

    constructor (address owner, uint256 goalAmount ) {
        i_owner = owner;
        i_goalAmount = goalAmount;
        s_currentAmount = 0;
        s_campaignState = CampaignState.OPEN;
        emit CampaignOpened(i_owner, i_goalAmount);
    }

    function donate() public payable {
        if(msg.value <= 0) {
            revert Campaign__AmountMustBeMoreThanZero();
        }
        if(s_campaignState != CampaignState.OPEN) {
            revert Campaign__CampaignNotOpen();
        }
        s_currentAmount += msg.value;
        s_addressToAmountDonated[msg.sender] += msg.value;
        s_donors.push(msg.sender);
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdraw() public {
        if(msg.sender != i_owner) revert Campaign__NotOwner();

        address[] memory donors = s_donors;
        for(uint256 donorIndex = 0; donorIndex < donors.length; donorIndex++) {
            address donor = s_donors[donorIndex];
            s_addressToAmountDonated[donor] = 0;
        }
        s_donors = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
        s_campaignState = CampaignState.CLOSE;
        emit CampaignClosed(s_currentAmount);
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }
    
    function getGoalAmount() external view returns(uint256) {
        return i_goalAmount;
    }
}