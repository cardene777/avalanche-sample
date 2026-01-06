// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

// NOTE: @ava-labs/icm-contracts must be installed
// Import will work after: npm install @ava-labs/icm-contracts
// For now, we'll define the interface inline as a placeholder
interface ITeleporterMessenger {
    struct TeleporterMessageInput {
        bytes32 destinationBlockchainID;
        address destinationAddress;
        TeleporterFeeInfo feeInfo;
        uint256 requiredGasLimit;
        address[] allowedRelayerAddresses;
        bytes message;
    }

    struct TeleporterFeeInfo {
        address feeTokenAddress;
        uint256 amount;
    }

    function sendCrossChainMessage(TeleporterMessageInput calldata messageInput)
        external
        returns (uint256 messageID);
}

/**
 * @title PaymentRegistry
 * @dev Records payments on Dispatch chain and sends cross-chain messages to Echo
 * @notice This contract tracks payment settlements and notifies ContentAccessManager on Echo chain
 */
contract PaymentRegistry is Ownable {
    // Teleporter Messenger instance
    ITeleporterMessenger public immutable teleporterMessenger;

    // Echo chain configuration
    bytes32 public immutable echoChainID;
    address public immutable contentAccessManagerOnEcho;

    // Payment struct
    struct Payment {
        address buyer;
        bytes32 contentId;
        uint256 amount;
        bytes32 paymentTxHash;
        uint256 timestamp;
        bool settled;
    }

    // Mapping: buyer => contentId => Payment
    mapping(address => mapping(bytes32 => Payment)) public payments;

    // Events
    event PaymentSettled(
        address indexed buyer,
        bytes32 indexed contentId,
        uint256 amount,
        bytes32 paymentTxHash,
        uint256 timestamp
    );

    event CrossChainMessageSent(
        address indexed buyer,
        bytes32 indexed contentId,
        uint256 teleporterMessageID
    );

    constructor(
        address _teleporterMessenger,
        bytes32 _echoChainID,
        address _contentAccessManagerOnEcho
    ) Ownable(msg.sender) {
        require(_teleporterMessenger != address(0), "Invalid teleporter address");
        require(_contentAccessManagerOnEcho != address(0), "Invalid content manager address");

        teleporterMessenger = ITeleporterMessenger(_teleporterMessenger);
        echoChainID = _echoChainID;
        contentAccessManagerOnEcho = _contentAccessManagerOnEcho;
    }

    /**
     * @notice Settle a payment and send cross-chain message to grant access on Echo
     * @param buyer Address of the buyer
     * @param contentId Content identifier (keccak256 hash)
     * @param amount Payment amount
     * @param paymentTxHash Transaction hash of the ERC-3009 transfer
     */
    function settlePayment(
        address buyer,
        bytes32 contentId,
        uint256 amount,
        bytes32 paymentTxHash
    ) external onlyOwner {
        require(buyer != address(0), "Invalid buyer address");
        require(amount > 0, "Amount must be greater than 0");
        require(!payments[buyer][contentId].settled, "Payment already settled");

        // Record payment
        payments[buyer][contentId] = Payment({
            buyer: buyer,
            contentId: contentId,
            amount: amount,
            paymentTxHash: paymentTxHash,
            timestamp: block.timestamp,
            settled: true
        });

        emit PaymentSettled(buyer, contentId, amount, paymentTxHash, block.timestamp);

        // Send cross-chain message to Echo
        _sendCrossChainMessage(buyer, contentId, amount, paymentTxHash);
    }

    /**
     * @dev Internal function to send cross-chain message via Teleporter
     * @param buyer Address of the buyer
     * @param contentId Content identifier
     * @param amount Payment amount
     * @param paymentTxHash Transaction hash
     */
    function _sendCrossChainMessage(
        address buyer,
        bytes32 contentId,
        uint256 amount,
        bytes32 paymentTxHash
    ) internal {
        // Encode message payload
        bytes memory messageData = abi.encode(
            buyer,
            contentId,
            amount,
            paymentTxHash,
            block.timestamp
        );

        // Prepare Teleporter message
        ITeleporterMessenger.TeleporterMessageInput memory messageInput = ITeleporterMessenger
            .TeleporterMessageInput({
                destinationBlockchainID: echoChainID,
                destinationAddress: contentAccessManagerOnEcho,
                feeInfo: ITeleporterMessenger.TeleporterFeeInfo({
                    feeTokenAddress: address(0), // No fee for testnet
                    amount: 0
                }),
                requiredGasLimit: 200000, // Gas limit for receiver execution
                allowedRelayerAddresses: new address[](0), // Allow any relayer
                message: messageData
            });

        // Send message
        uint256 messageID = teleporterMessenger.sendCrossChainMessage(messageInput);

        emit CrossChainMessageSent(buyer, contentId, messageID);
    }

    /**
     * @notice Check if a payment has been settled
     * @param buyer Address of the buyer
     * @param contentId Content identifier
     * @return True if payment is settled
     */
    function isPaymentSettled(address buyer, bytes32 contentId)
        external
        view
        returns (bool)
    {
        return payments[buyer][contentId].settled;
    }

    /**
     * @notice Get payment details
     * @param buyer Address of the buyer
     * @param contentId Content identifier
     * @return Payment struct
     */
    function getPayment(address buyer, bytes32 contentId)
        external
        view
        returns (Payment memory)
    {
        return payments[buyer][contentId];
    }
}
