//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Campaign {
    error Campaign__CampaignNotOpen();
    error Campaign__NotOwner();
    error Campaign__AmountMustBeMoreThanZero();
    error Campaign__NoDonationsYet();
    error Campaign__CampaignStillOpen();

    enum CampaignState {
        OPEN,
        CLOSE
    }

    address private immutable i_owner;
    address[] private s_donors;
    mapping(address => uint256) private s_addressToAmountDonated;
    uint256 private immutable i_goalAmount;
    uint256 private s_currentAmount;
    uint256 private s_finalAmount;
    CampaignState private s_campaignState;

    event CampaignOpened(address campaignOwner, uint256 goalAmount);
    event DonationReceived(
        address mostRecentDonor,
        uint256 mostRecentDonationAmount
    );
    event CampaignClosed(uint256 finalAmount);
    event CampaignWillBeClosedAfterTransfer();
    event GoalAmountNotReached(uint256 goalAmount, uint256 currentAmount);

    constructor(address owner, uint256 goalAmount) {
        i_owner = owner;
        i_goalAmount = goalAmount;
        s_currentAmount = 0;
        s_campaignState = CampaignState.OPEN;
        s_finalAmount = 0;
        emit CampaignOpened(i_owner, i_goalAmount);
    }

    function donate() public payable {
        if (msg.value <= 0) {
            revert Campaign__AmountMustBeMoreThanZero();
        }
        if (s_campaignState != CampaignState.OPEN) {
            revert Campaign__CampaignNotOpen();
        }
        s_currentAmount += msg.value;
        s_addressToAmountDonated[msg.sender] += msg.value;
        s_donors.push(msg.sender);
        emit DonationReceived(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Campaign__NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        if (s_currentAmount <= 0) {
            revert Campaign__NoDonationsYet();
        }
        if (s_currentAmount < i_goalAmount) {
            emit GoalAmountNotReached(i_goalAmount, s_currentAmount);
            emit CampaignWillBeClosedAfterTransfer();
        }

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
        s_finalAmount = s_currentAmount;
        s_currentAmount = 0;
        closeCampaign();
        emit CampaignClosed(s_finalAmount);
    }

    function closeCampaign() public onlyOwner {
        if (s_campaignState == CampaignState.CLOSE) {
            return;
        }
        s_campaignState = CampaignState.CLOSE;
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getGoalAmount() external view returns (uint256) {
        return i_goalAmount;
    }

    function getCurrentAmount() external view returns (uint256) {
        return s_currentAmount;
    }

    function getCampaignState() external view returns (CampaignState) {
        return s_campaignState;
    }

    function getDonationAmount(address donor) external view returns (uint256) {
        uint256 amount = s_addressToAmountDonated[donor];
        if (amount == 0) {
            revert Campaign__NoDonationsYet();
        }
        return amount;
    }

    function getFinalAmount() external view returns (uint256) {
        if (s_campaignState == CampaignState.OPEN) {
            revert Campaign__CampaignStillOpen();
        }
        return s_finalAmount;
    }

    function getRecentDonor() external view returns (address) {
        if (s_donors.length == 0) revert Campaign__NoDonationsYet();
        return s_donors[s_donors.length - 1];
    }

    function getRecentDonationAmount() external view returns (uint256) {
        if (s_currentAmount == 0) {
            revert Campaign__NoDonationsYet();
        }
        return s_addressToAmountDonated[s_donors[s_donors.length - 1]];
    }

    function getAllDonors() external view returns (address[] memory) {
        if (s_donors.length == 0) revert Campaign__NoDonationsYet();
        return s_donors;
    }
}
