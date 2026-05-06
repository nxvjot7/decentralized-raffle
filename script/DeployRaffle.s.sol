//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {NetworkConfig} from "./NetworkConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployRaffle();
    }

    function deployRaffle() public returns (Raffle, NetworkConfig) {
        NetworkConfig config = new NetworkConfig();
        NetworkConfig.NetworkConfigData memory configs = config.getConfig();

        if (configs.subscriptionId == 0) {
            CreateSubscription createsubs = new CreateSubscription();
            (configs.subscriptionId, configs._vrfCoordinator) =
                createsubs.createSubscription(configs._vrfCoordinator, configs.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                configs._vrfCoordinator, configs.subscriptionId, configs.link, configs.account
            );
        }

        vm.startBroadcast(configs.account);
        Raffle raffle = new Raffle(
            configs.entrancefee,
            configs.interval,
            configs._vrfCoordinator,
            configs.gasLane,
            configs.subscriptionId,
            configs.callGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), configs._vrfCoordinator, configs.subscriptionId, configs.account);

        return (raffle, config);
    }
}
