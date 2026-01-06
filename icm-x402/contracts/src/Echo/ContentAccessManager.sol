// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

// NOTE: @ava-labs/icm-contracts must be installed
// Import will work after: npm install @ava-labs/icm-contracts
// For now, we'll define the interface inline as a placeholder
interface ITeleporterReceiver {
    function receiveTeleporterMessage(
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external;
}

/**
 * @title ContentAccessManager
 * @dev Manages content access permissions on Echo chain
 * @notice This contract is the single source of truth for access control (Constitutional Principle I)
 */
contract ContentAccessManager is ITeleporterReceiver, Ownable {
    // Teleporter Messenger address
    address public immutable teleporterMessenger;

    // Dispatch chain configuration
    bytes32 public immutable dispatchChainID;
    address public immutable paymentRegistryOnDispatch;

    // Access mapping: buyer => contentId => hasAccess
    mapping(address => mapping(bytes32 => bool)) public access;

    // Access grant details
    struct AccessGrant {
        address buyer;
        bytes32 contentId;
        uint256 amount;
        bytes32 paymentTxHash;
        uint256 grantedAt;
    }

    // Mapping to store access grant details
    mapping(address => mapping(bytes32 => AccessGrant)) public accessGrants;

    // Events
    event AccessGranted(
        address indexed buyer,
        bytes32 indexed contentId,
        uint256 amount,
        bytes32 paymentTxHash,
        uint256 grantedAt
    );

    constructor(
        address _teleporterMessenger,
        bytes32 _dispatchChainID,
        address _paymentRegistryOnDispatch
    ) Ownable(msg.sender) {
        require(_teleporterMessenger != address(0), "Invalid teleporter address");
        require(_paymentRegistryOnDispatch != address(0), "Invalid payment registry address");

        teleporterMessenger = _teleporterMessenger;
        dispatchChainID = _dispatchChainID;
        paymentRegistryOnDispatch = _paymentRegistryOnDispatch;
    }

    /**
     * @notice Receive cross-chain message from PaymentRegistry on Dispatch
     * @dev Implements ITeleporterReceiver interface
     * @param originChainID Chain ID where message originated
     * @param originSenderAddress Address of sender on origin chain
     * @param message Encoded payment data
     */
    function receiveTeleporterMessage(
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external override {
        // Security checks (Constitutional Principle VI)
        require(
            msg.sender == teleporterMessenger,
            "Only Teleporter can call this function"
        );
        require(
            originChainID == dispatchChainID,
            "Invalid origin chain ID"
        );
        require(
            originSenderAddress == paymentRegistryOnDispatch,
            "Invalid origin sender address"
        );

        // Decode message
        (
            address buyer,
            bytes32 contentId,
            uint256 amount,
            bytes32 paymentTxHash,
            uint256 timestamp
        ) = abi.decode(message, (address, bytes32, uint256, bytes32, uint256));

        // Validate decoded data
        require(buyer != address(0), "Invalid buyer address");
        require(amount > 0, "Invalid amount");

        // Grant access
        access[buyer][contentId] = true;

        // Store access grant details
        accessGrants[buyer][contentId] = AccessGrant({
            buyer: buyer,
            contentId: contentId,
            amount: amount,
            paymentTxHash: paymentTxHash,
            grantedAt: block.timestamp
        });

        emit AccessGranted(buyer, contentId, amount, paymentTxHash, block.timestamp);
    }

    /**
     * @notice Check if a buyer has access to content
     * @param buyer Address of the buyer
     * @param contentId Content identifier (keccak256 hash)
     * @return True if buyer has access
     */
    function hasAccess(address buyer, bytes32 contentId)
        external
        view
        returns (bool)
    {
        return access[buyer][contentId];
    }

    /**
     * @notice Get access grant details
     * @param buyer Address of the buyer
     * @param contentId Content identifier
     * @return AccessGrant struct
     */
    function getAccessGrant(address buyer, bytes32 contentId)
        external
        view
        returns (AccessGrant memory)
    {
        return accessGrants[buyer][contentId];
    }

    /**
     * @notice Emergency function to revoke access (owner only)
     * @dev Use with caution - this breaks the on-chain source of truth principle
     * @param buyer Address of the buyer
     * @param contentId Content identifier
     */
    function revokeAccess(address buyer, bytes32 contentId) external onlyOwner {
        access[buyer][contentId] = false;
    }

    /**
     * @notice Manually grant access (owner only, for testing/emergency)
     * @param buyer Address of the buyer
     * @param contentId Content identifier
     */
    function manualGrantAccess(address buyer, bytes32 contentId) external onlyOwner {
        require(buyer != address(0), "Invalid buyer address");
        access[buyer][contentId] = true;

        emit AccessGranted(buyer, contentId, 0, bytes32(0), block.timestamp);
    }
}
