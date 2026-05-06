//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {
    VRFCoordinatorV2_5Mock
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/Linktoken.sol";

abstract contract CodeConstants {
    /*VRF MOCK VALUES */
    uint96 public mockBaseFee = 0.01 ether;
    uint96 public mockGasPriceLink = 1e9;
    /*LINK/ETH PRICE*/
    int256 public mockWeiPerUnitLink = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract NetworkConfig is Script, CodeConstants {
    error NetworkConfig___InvalidChainID();

    struct NetworkConfigData {
        uint256 entrancefee;
        uint256 interval;
        address _vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callGasLimit;
        address link;
        address account;
    }

    NetworkConfigData public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfigData) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfigData memory) {
        if (networkConfigs[chainId]._vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        } else {
            revert NetworkConfig___InvalidChainID();
        }
    }

    function getConfig() public returns (NetworkConfigData memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfigData memory) {
        return NetworkConfigData({
            entrancefee: 0.01 ether,
            interval: 30,
            _vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 35819423683220950811473524885463782305952242792943832055803666176626977802598,
            callGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x93DED83Ef34442c0b59BB5bFdeBF53fA1f3FAf21
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfigData memory) {
        if (localNetworkConfig._vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(mockBaseFee, mockGasPriceLink, mockWeiPerUnitLink);
        LinkToken linktoken = new LinkToken();

        vm.stopBroadcast();
        localNetworkConfig = NetworkConfigData({
            entrancefee: 0.01 ether,
            interval: 30,
            _vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callGasLimit: 500000,
            link: address(linktoken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
        return localNetworkConfig;
    }
}

// mockBaseFee = 0.01 ether;
//     uint96 public mockGasPriceLink = 1e9;
//     /*LINK/ETH PRICE*/
//     int256 public mockWeiPerUnitLink = 4e15;
