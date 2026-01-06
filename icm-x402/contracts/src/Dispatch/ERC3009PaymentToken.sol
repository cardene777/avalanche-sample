// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC3009PaymentToken
 * @dev ERC-20 token with ERC-3009 transferWithAuthorization for gasless payments
 * @notice This token allows users to authorize transfers via signatures without paying gas
 */
contract ERC3009PaymentToken is ERC20, Ownable {
    // EIP-712 domain separator
    bytes32 public DOMAIN_SEPARATOR;

    // ERC-3009 TransferWithAuthorization typehash
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );

    // Mapping to track used nonces
    mapping(address => mapping(bytes32 => bool)) public authorizationState;

    // Events
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        // Set EIP-712 domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // Mint initial supply to contract owner
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Execute a transfer with a signed authorization
     * @param from Payer's address (must have signed the authorization)
     * @param to Payee's address
     * @param value Amount to transfer
     * @param validAfter The time after which the authorization is valid
     * @param validBefore The time before which the authorization is valid
     * @param nonce Unique nonce to prevent replay attacks
     * @param v ECDSA signature v component
     * @param r ECDSA signature r component
     * @param s ECDSA signature s component
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp > validAfter, "Authorization not yet valid");
        require(block.timestamp < validBefore, "Authorization expired");
        require(!authorizationState[from][nonce], "Authorization already used");

        // Construct EIP-712 message hash
        bytes32 structHash = keccak256(
            abi.encode(
                TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
                from,
                to,
                value,
                validAfter,
                validBefore,
                nonce
            )
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        // Recover signer from signature
        address signer = ecrecover(messageHash, v, r, s);
        require(signer == from, "Invalid signature");
        require(signer != address(0), "Invalid signer");

        // Mark nonce as used
        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        // Execute transfer
        _transfer(from, to, value);
    }

    /**
     * @notice Mint new tokens (only owner)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Check if an authorization has been used
     * @param authorizer Address of the authorizer
     * @param nonce Nonce of the authorization
     * @return True if authorization has been used
     */
    function authorizationUsed(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return authorizationState[authorizer][nonce];
    }
}
