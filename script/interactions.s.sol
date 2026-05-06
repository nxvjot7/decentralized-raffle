//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {
    VRFCoordinatorV2_5Mock
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

import {NetworkConfig, CodeConstants} from "./NetworkConfig.s.sol";
import {LinkToken} from "../test/mocks/Linktoken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        NetworkConfig netConfig = new NetworkConfig();
        address vrfCoordinator = netConfig.getConfig()._vrfCoordinator;
        address account = netConfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        // console.log("CREATING SUBSCRIPTION ON CHAIN ID", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        // console.log("Your subscription ID is :", subId);
        // console.log("Please update your subscription id in your HelperConfig.s.sol");

        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        NetworkConfig netConfig = new NetworkConfig();
        address vrfCoordinator = netConfig.getConfig()._vrfCoordinator;
        uint256 subscriptionId = netConfig.getConfig().subscriptionId;
        address linktoken = netConfig.getConfig().link;
        address account = netConfig.getConfig().account;
        fundSubscription(vrfCoordinator, subscriptionId, linktoken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linktoken, address account)
        public
    {
        // console.log("Funding Subscription", subscriptionId);
        // console.log("Using VrfCoordinator", vrfCoordinator);
        // console.log("On ChainId", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linktoken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        NetworkConfig netConfig = new NetworkConfig();
        uint256 subId = netConfig.getConfig().subscriptionId;
        address vrfCoordinator = netConfig.getConfig()._vrfCoordinator;
        address account = netConfig.getConfig().account;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(address contractToAddVrf, address vrfCoordinator, uint256 subId, address account) public {
        // console.log("adding consumer contract:", contractToAddVrf);
        // console.log("To vrfCoordinator: ", vrfCoordinator);
        // console.log("On ChainId: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddVrf);
        vm.stopBroadcast();
    }

    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
