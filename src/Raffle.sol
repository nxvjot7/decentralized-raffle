// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions {checks, effects, interactions}

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;


import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/**
 * @title RAFFLE CONTRACT
 * @author nxvjot7
 * @notice This is for educational Purpose only
 * @dev Implements Chainlink-VRF2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /*error section */
    error raffle__NotEnoughEthEntered(uint256 sent, uint256 minimumRequired);
    error PickWinner__ItNeedsMoreTime(uint256 currenttime, uint256 willDeclareWinnerAtThisTime);
    error Transfer_failed();
    error NoPlayers();
    error CalculatingTheWinner();
    error raffle_UpKeepNotNeeded(uint256 contractBalance, uint256 noOfPlayers, uint256 raffleState);

    /*type declaration section */
    enum RaffleState {
        Open,
        FreezedFindingWinner
    }

    /*state variable section */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_INTERVAL;
    bytes32 private immutable I_KEYHASH;
    uint256 private immutable I_SUBSCRIPTION_ID;
    uint32 private immutable I_CALLGASLIMIT;
    address payable[] private sPlayers;
    address private sRecentWinner;
    uint256 private sLastTimeStamp;
    RaffleState private sRaffleState;

    /* event section */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed picked);
    event RequestRaffleWinner(uint256 indexed reuqestId);

    /* constructor section */
    constructor(
        uint256 entrancefee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        //passing _vrfCoordinator from our constructor to their constructor
        I_ENTRANCE_FEE = entrancefee;
        I_INTERVAL = interval;
        I_KEYHASH = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLGASLIMIT = callGasLimit;

        sLastTimeStamp = block.timestamp;
        sRaffleState = RaffleState.Open;
    }

    /* function section */

    function enterRaffle() public payable {
        //this is from where oneself can enter the lottery by buying the ticket
        if (msg.value < I_ENTRANCE_FEE) {
            ///checkec
            revert raffle__NotEnoughEthEntered(msg.value, I_ENTRANCE_FEE);
        }
        if (sRaffleState != RaffleState.Open) {
            revert CalculatingTheWinner();
        }
        sPlayers.push(payable(msg.sender)); //checked
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* nothing */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool hasTimePassed = (block.timestamp - sLastTimeStamp) >= I_INTERVAL;
        bool isOpen = sRaffleState == RaffleState.Open;
        bool thereArePlayers = sPlayers.length > 0;
        bool areThereFunds = address(this).balance > 0;
        upkeepNeeded = hasTimePassed && isOpen && thereArePlayers && areThereFunds;
        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    )
        external
    {
        //will announce winner

        (bool upKeepNeeded,) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert raffle_UpKeepNotNeeded(address(this).balance, sPlayers.length, uint256(sRaffleState));
        }

        // if ((block.timestamp - sLastTimeStamp) < I_INTERVAL) {
        //     revert PickWinner__ItNeedsMoreTime((block.timestamp - sLastTimeStamp), I_INTERVAL);
        // }

        sRaffleState = RaffleState.FreezedFindingWinner;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: I_KEYHASH,
            subId: I_SUBSCRIPTION_ID,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: I_CALLGASLIMIT,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256,
        /*requestId*/
        uint256[] calldata randomWords
    )
        internal
        override
    {
        if (sPlayers.length == 0) {
            revert NoPlayers();
        }
        uint256 indexOfWinner = randomWords[0] % sPlayers.length;
        address payable recentWinner = sPlayers[indexOfWinner];
        sRecentWinner = recentWinner;
        (bool success,) = sRecentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Transfer_failed();
        }
        sPlayers = new address payable[](0);
        sRaffleState = RaffleState.Open;
        sLastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
    }

    function getEntranceFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }

    //getter functions

    function getRaffleState() public view returns (RaffleState) {
        return sRaffleState;
    }

    function getPlayer(uint256 indexOfPlayer) public view returns (address) {
        return sPlayers[indexOfPlayer];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return sLastTimeStamp;
    }

    function getRecentWinner() public view returns (address) {
        return sRecentWinner;
    }

    function getNoofPlayer() public view returns (uint256) {
        return sPlayers.length;
    }
}
