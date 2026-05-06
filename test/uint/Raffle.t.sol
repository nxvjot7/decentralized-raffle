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

contract UintRaffletest is CodeConstants, Test {
    Raffle public raffle;
    NetworkConfig public networkConfig;
    address public immutable PLAYER = makeAddr("player");
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
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    modifier enterRaffle() {
        vm.prank(PLAYER);
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
    //SCRIPT DEPLOYMENT TEST
    ////////////////////////////////////////////////////////////////////////////

    function testScriptIsDeployingRafflAndNetConfig() public view {
        assert(address(raffle) != address(0));
        assert(address(networkConfig) != address(0));
    }

    ////////////////////////////////////////////////////////////////////////////
    //TEST enterRaffle() WORKING CORRECTLY
    ////////////////////////////////////////////////////////////////////////////

    function testSinglePlayerCanEnterRaffle() public enterRaffle {
        //ARRANGE & ACT - MODIFIER

        //ASSERT
        assertEq(raffle.getPlayer(0), address(PLAYER));
    }

    function testMutliplePlayerCanEnterRaffle() public enterRaffle {
        //ARRANGE
        uint128 noOfPlayers = 9;

        //ACT
        for (uint128 i = 1; i < noOfPlayers; i++) {
            address newPlayer = address(uint160(i)); //creating newPlayer
            hoax(newPlayer, 1 ether); //Giving that player funds, and making next call from his address
            raffle.enterRaffle{value: entrancefee}();
        }

        //ASSERT
        assertEq(raffle.getNoofPlayer(), 9); //1 player from midfier 8 from loop total = 9 players
    }

    function testItEmitsWhenPlayerEnterRaffle() public {
        //ARRANGE
        vm.prank(PLAYER);

        //ACT / ASSERT
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entrancefee}();
    }

    function testItRevertsPlayerifNotEnoughFunds() public {
        // ARRANGE
        vm.prank(PLAYER);
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.raffle__NotEnoughEthEntered.selector, entrancefee - 1, entrancefee)
        );
        //ACT / ASSERT
        raffle.enterRaffle{value: entrancefee - 1}();
    }

    function testItRevertsMultiplePlayerifNotEnoughFunds() public {
        // ARRANGE
        uint128 noOfPlayers = 9;

        //ACT / ASSERT
        for (uint128 i = 1; i < noOfPlayers; i++) {
            address newPlayer = address(uint160(i)); //creating newPlayer
            hoax(newPlayer, 1 ether); //Giving that player funds, and making next call from his address
            vm.expectRevert(
                abi.encodeWithSelector(Raffle.raffle__NotEnoughEthEntered.selector, entrancefee - 1, entrancefee)
            );
            raffle.enterRaffle{value: entrancefee - 1}();
        }
    }

    function testEnterRaffleRevertIfRaffleStateIsNotOpen() public enterRaffle skipTime {
        //ARRANGE - MODIFIER

        //ACT / ASSERT
        raffle.performUpkeep("");

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.CalculatingTheWinner.selector); //no abi encode cuz no Parameters
        raffle.enterRaffle{value: entrancefee}();
    }

    ////////////////////////////////////////////////////////////////////////////
    //TEST checkUpKeep() WORKING CORRECTLY
    ////////////////////////////////////////////////////////////////////////////

    function testCheckUpKeepFailsIfTimeNotPassed() public enterRaffle {
        //RAFFLE ENTERED, AMOUNT > 0, PLAYERS > 0
        //all condtions are true expect time one, if we call it now it should fail

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testCheckUpKeepFailsIfZeroPlayers() public skipTime {
        //RAFFLE NotENTERED, AMOUNT < 0, PLAYERS < 0
        //all condtions are false expect the time one, if we call it now it should fail

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public enterRaffle skipTime {
        raffle.performUpkeep(""); //This line changes the Raffle state from 'Open' to 'Calculating', because all conditions are met
        // (or 'FreezedFindingWinner'). Because it is now calculating, upkeep should no longer be needed.

        (bool upkeepNeeded,) = raffle.checkUpkeep(""); //storing output of checkUpKeep in upKeepNeeded, it will be false cuz performKeepup() closed rafffle

        assert(!upkeepNeeded); // is upkeepNeeded is not true? if its not true then pass.
    }

    ////////////////////////////////////////////////////////////////////////////
    //TEST performUpkeep() WORKING CORRECTLY
    ////////////////////////////////////////////////////////////////////////////

    function testPerformUpKeepRevertsIfTimeNotPassed() public enterRaffle {
        //RAFFLE ENTERED, AMOUNT > 0, PLAYERS > 0
        //all condtions are true expect time one, if we call it now it should fail

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.raffle_UpKeepNotNeeded.selector,
                address(raffle).balance,
                raffle.getNoofPlayer(),
                uint256(raffle.getRaffleState())
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertsIfNoPlayer() public skipTime {
        //RAFFLE NOT_ENTERED, AMOUNT < 0, PLAYERS < 0
        //all condtions are false expect time one, if we call it now it should fail
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.raffle_UpKeepNotNeeded.selector,
                address(raffle).balance,
                raffle.getNoofPlayer(),
                uint256(raffle.getRaffleState())
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpKeepChangesState() public enterRaffle skipTime {
        //ACT
        raffle.performUpkeep("");

        //ASSERT
        assertEq(
            uint256(raffle.getRaffleState()), //using typecast cuz assertEq don't know what a enum is
            uint256(Raffle.RaffleState.FreezedFindingWinner)
        );
    }

    function testPerformKeepUpEmitsRequestId() public enterRaffle skipTime skipFork {
        //ARRANGE
        vm.recordLogs(); //record all the logs of events being fired after this

        //ACT
        raffle.performUpkeep(""); //calling performUpkeep - this gives 2 emits, 1st is of VRFCoordinatorV2Mock, 2nd is inside PerformUpKeep
        Vm.Log[] memory entries = vm.getRecordedLogs(); //storing Emitted event logs inside entries
        bytes32 requestId = entries[1].topics[1]; //entries index 1 because the index 0 is of VRFCoordinatorV2Mock's Emit, And topic 0 index is of signature hash so 1st one was what we needed acoording to index

        //assert
        assertEq(uint256(requestId), 1); //Since a bytes32 is just a hex string, casting it to a uint256 allows you to check if it's empty. If it's 0, the VRF request failed. But in this case it'll 1 thats what our mock gives
    }
    ////////////////////////////////////////////////////////////////////////////
    //TEST performUpkeep() WORKING CORRECTLY
    ////////////////////////////////////////////////////////////////////////////

    function testFullFillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomRequestId)
        public
        enterRaffle
        skipTime
        skipFork
    {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector); //this is how it should revert
        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle)); //calling fullfillRandomWords Directly without requesting for randomwords. it should revert
    }

    function testFullFillRandomWordsPicksWinnerResetAndSendsMoney() public enterRaffle skipTime skipFork {
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1); //In the real world, randomness is unpredictable. In a test environment using a Mock, randomness is "fake." so thats why we were able to know who would win

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            // casting to 'uint160' is safe because i is a small loop counter (1,2,3...)
            // forge-lint: disable-next-line(unsafe-typecast)
            address newPlayer = address(uint160(i)); // creating new player from i (1,2,3)
            hoax(newPlayer, 1 ether); //giving them funds
            raffle.enterRaffle{value: entrancefee}(); //making entry of 3 players in raffle
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp(); //storing the time that is now before declaring winner in startingTimeStamp
        uint256 winnerStartingBalance = expectedWinner.balance; //balance of player(1) before winning

        vm.recordLogs(); //telling to record all events
        raffle.performUpkeep(""); //calling performupKeep to request RandomWord

        Vm.Log[] memory entries = vm.getRecordedLogs(); //storing all emited events inside array
        bytes32 requestId = entries[1].topics[1]; //accessing entry at index 1, and topic at index 1  (topic index 0 is signature hash)
        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle)); //now calling fullfillrandomword to access that randomword and declare the winner

        address recentWinner = raffle.getRecentWinner(); //storing live raffle's winner
        Raffle.RaffleState raffleState = raffle.getRaffleState(); //getting raffle state, (it should be open as winner is declared)
        uint256 winnerBalance = recentWinner.balance; // storing winner's balance after win
        uint256 endingTimeStamp = raffle.getLastTimeStamp(); //storing the time that is now after declaring winner in startingTimeStamp
        uint256 prize = entrancefee * (additionalEntrants + 1); //prize equals to 3 player we entered through loop + 1 that we made enter through modifier

        assert(expectedWinner == recentWinner); //checking if expected winner is same as the winenr
        assert(uint160(raffleState) == 0); // checking if raffle is open after player won
        assert(winnerBalance == winnerStartingBalance + prize); // checking if (winner's old balance + raffle's balance) is equals to winner's new balance
        assert(endingTimeStamp > startingTimeStamp); // checking if ending timestamp is greater than starting timestamp
    }
}

