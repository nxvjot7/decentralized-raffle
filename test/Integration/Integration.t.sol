//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {NetworkConfig} from "script/NetworkConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";
import {
    VRFCoordinatorV2_5Mock
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/NetworkConfig.s.sol";

contract RaffleIntegrationtest is CodeConstants, Test {
    Raffle public raffle;
    NetworkConfig public networkConfig;
    address public player = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entrancefee;
    uint256 interval;
    address _vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callGasLimit;

    event RaffleEntered(address indexed player);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, networkConfig) = deployer.deployRaffle(); //deploying raffle and netConfig Using script

        NetworkConfig.NetworkConfigData memory configuration = networkConfig.getConfig();
        entrancefee = configuration.entrancefee;
        interval = configuration.interval;
        _vrfCoordinator = configuration._vrfCoordinator;
        gasLane = configuration.gasLane;
        subscriptionId = configuration.subscriptionId;
        callGasLimit = configuration.callGasLimit;
        vm.deal(player, STARTING_PLAYER_BALANCE);
    }

    modifier enterRaffle() {
        vm.prank(player);
        raffle.enterRaffle{value: entrancefee}();
        _;
    }

    modifier skipTime() {
        vm.warp(block.timestamp + interval + 1); // skipping time
        vm.roll(block.number + 1); //+1 block
        _;
    }

    modifier skipFork() {
        if (block.chainid == 11155111) {
            return;
        } else {
            _;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    //END TO END TEST
    ////////////////////////////////////////////////////////////////////////////

    function testEndToEndTest() public skipFork {
        //////////////////////////////////////////////////
        //                   ARRANGE
        ///////////////////////////////////////////////////
        vm.prank(player);
        raffle.enterRaffle{value: entrancefee}();

        uint160 noOfplayers = 7;

        for (uint160 i = 1; i < noOfplayers; i++) {
            address newplayer = address(uint160(i));
            hoax(newplayer, STARTING_PLAYER_BALANCE);
            raffle.enterRaffle{value: entrancefee}();
        }

        uint256[] memory startingBalances = new uint256[](noOfplayers); //telling it to store array slot for 7 playerS
        startingBalances[0] = player.balance; //slot 0 is reserved for player
        for (uint160 i = 1; i < noOfplayers; i++) {
            startingBalances[i] = address(i).balance;
        }
        uint256 prizepool = (entrancefee * noOfplayers);
        uint256 startingTime = raffle.getLastTimeStamp();

        vm.warp(block.timestamp + interval + 1); //skipping time
        vm.roll(block.number + 1); //+1 block

        //////////////////////////////////////////////////
        //                   ACT
        ///////////////////////////////////////////////////
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //////////////////////////////////////////////////
        //                   ASSERT
        ///////////////////////////////////////////////////
        uint256 endTime = raffle.getLastTimeStamp();
        address recentWinner = raffle.getRecentWinner();

        assert(recentWinner != address(0)); //checking if winnerAddress is not empty
        assertGt(endTime, startingTime); //checking if ending time is > StartintTime
        assertEq(0, raffle.getNoofPlayer()); //checking that, it made array empty After winner declaration
        assertEq(0, address(raffle).balance); //checking raffle balance is 0 After winner declaration
        assertEq(uint256(Raffle.RaffleState.Open), uint256(raffle.getRaffleState()));

        if (recentWinner == player) {
            assertEq(player.balance, STARTING_PLAYER_BALANCE + prizepool);
        } else {
            for (uint160 i = 1; i < noOfplayers; i++) {
                if (recentWinner == address(i)) {
                    assertEq(address(i).balance, startingBalances[i] + prizepool);
                }
            }
        }
    }

    function testItWorksAgainAfterCycleEnds() public skipFork {
        //////////////////////////////////////////////////
        //                   ARRANGE - 1
        ///////////////////////////////////////////////////
        vm.prank(player);
        raffle.enterRaffle{value: entrancefee}();

        uint160 noOfplayers = 7;

        for (uint160 i = 1; i < noOfplayers; i++) {
            address newplayer = address(uint160(i));
            hoax(newplayer, STARTING_PLAYER_BALANCE);
            raffle.enterRaffle{value: entrancefee}();
        }

        uint256[] memory startingBalances = new uint256[](noOfplayers); //telling it to store array slot for 7 playerS
        startingBalances[0] = player.balance; //slot 0 is reserved for player
        for (uint160 i = 1; /*adding balance of 6 other players from index 1 to 6 */ i < noOfplayers; i++) {
            startingBalances[i] = address(i).balance;
        }
        uint256 prizepool = (entrancefee * noOfplayers);
        uint256 startingTime = raffle.getLastTimeStamp();

        vm.warp(block.timestamp + interval + 1); //skipping time
        vm.roll(block.number + 1); //+1 block

        //////////////////////////////////////////////////
        //                   ACT - 1
        ///////////////////////////////////////////////////

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //////////////////////////////////////////////////
        //                   ASSERT - 1
        ///////////////////////////////////////////////////
        uint256 endTime = raffle.getLastTimeStamp();
        address recentWinner = raffle.getRecentWinner();

        assert(recentWinner != address(0)); //checking if winnerAddress is not empty
        assertGt(endTime, startingTime); //checking if ending time is > StartintTime
        assertEq(0, raffle.getNoofPlayer()); //checking that, it made array empty After winner declaration
        assertEq(0, address(raffle).balance); //checking raffle balance is 0 After winner declaration
        assertEq(uint256(Raffle.RaffleState.Open), uint256(raffle.getRaffleState()));

        if (recentWinner == player) {
            assertEq(player.balance, STARTING_PLAYER_BALANCE + prizepool);
        } else {
            for (uint160 i = 1; i < noOfplayers; i++) {
                if (recentWinner == address(i)) {
                    assertEq(address(i).balance, startingBalances[i] + prizepool);
                }
            }
        }

        /////////SECOND CYCLE BELOW - ROUND 2

        //////////////////////////////////////////////////
        //                   ARRANGE - 2
        ///////////////////////////////////////////////////
        vm.prank(player);
        raffle.enterRaffle{value: entrancefee}();

        uint160 noOfplayers2 = 15;

        for (uint160 i = 8; i < noOfplayers2; i++) {
            address newplayer = address(uint160(i));
            hoax(newplayer, STARTING_PLAYER_BALANCE);
            raffle.enterRaffle{value: entrancefee}();
        }

        uint256[] memory startingBalances2 = new uint256[](noOfplayers2); //telling it to store array slot for 7 playerS
        startingBalances2[0] = player.balance; //slot 0 is reserved for player
        for (uint160 i = 8; /*adding balance of 6 other players from index 1 to 6 */ i < noOfplayers2; i++) {
            startingBalances2[i] = address(i).balance;
        }
        uint256 prizepool2 = (entrancefee * noOfplayers2);
        uint256 startingTime2 = raffle.getLastTimeStamp();

        vm.warp(block.timestamp + interval + 1); //skipping time
        vm.roll(block.number + 1); //+1 block

        //////////////////////////////////////////////////
        //                   ACT 2
        ///////////////////////////////////////////////////

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries2 = vm.getRecordedLogs();
        bytes32 requestId2 = entries2[1].topics[1];

        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(uint256(requestId2), address(raffle));

        //////////////////////////////////////////////////
        //                   ASSERT 2
        ///////////////////////////////////////////////////
        uint256 endTime2 = raffle.getLastTimeStamp();
        address recentWinner2 = raffle.getRecentWinner();

        assert(recentWinner2 != address(0)); //checking if winnerAddress is not empty
        assertGt(endTime2, startingTime2); //checking if ending time is > StartintTime
        assertEq(0, raffle.getNoofPlayer()); //checking that, it made array empty After winner declaration
        assertEq(0, address(raffle).balance); //checking raffle balance is 0 After winner declaration
        assertEq(uint256(Raffle.RaffleState.Open), uint256(raffle.getRaffleState()));

        if (recentWinner2 == player) {
            assertEq(player.balance, STARTING_PLAYER_BALANCE + prizepool2);
        } else {
            for (uint160 i = 8; i < noOfplayers2; i++) {
                if (recentWinner == address(i)) {
                    assertEq(address(i).balance, startingBalances2[i] + prizepool2);
                }
            }
        }
    }
}
