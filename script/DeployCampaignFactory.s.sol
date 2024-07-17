//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {CampaignFactory} from "src/CampaignFactory.sol";

contract DeployCampaignFactory is Script{
    function deployCampaignFactory() public returns(CampaignFactory) {
        vm.startBroadcast();
        CampaignFactory campaignFactory = new CampaignFactory();
        vm.stopBroadcast();
        return(campaignFactory);
    }

    function run() external returns (CampaignFactory){
        return deployCampaignFactory();
    }
}