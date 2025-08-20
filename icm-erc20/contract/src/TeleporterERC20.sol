// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITeleporterReceiver.sol";
import "./interfaces/ITeleporterMessenger.sol";

/**
 * Teleporter対応のERC20トークン
 * Burn&Mint方式でクロスチェーントークン転送を実装
 */
contract TeleporterERC20 is ERC20, Ownable, ITeleporterReceiver {
    ITeleporterMessenger public immutable teleporterMessenger;

    // 他のチェーンのトークンコントラクトアドレス
    mapping(bytes32 => address) public remoteTokenAddresses;

    // イベント
    event TokensSent(
        bytes32 indexed destinationChainID,
        address indexed to,
        uint256 amount
    );
    event TokensReceived(
        bytes32 indexed originChainID,
        address indexed from,
        uint256 amount
    );
    event RemoteAddressSet(
        bytes32 indexed chainID,
        address indexed remoteAddress
    );

    modifier onlyTeleporter() {
        require(
            msg.sender == address(teleporterMessenger),
            "TeleporterERC20: unauthorized"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _teleporterMessenger
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(
            _teleporterMessenger != address(0),
            "TeleporterERC20: zero address"
        );
        teleporterMessenger = ITeleporterMessenger(_teleporterMessenger);
    }

    /**
     * 誰でもmintできる
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * リモートチェーンのトークンアドレスを設定
     */
    function setRemoteTokenAddress(
        bytes32 chainID,
        address remoteAddress
    ) external onlyOwner {
        require(remoteAddress != address(0), "TeleporterERC20: zero address");
        remoteTokenAddresses[chainID] = remoteAddress;
        emit RemoteAddressSet(chainID, remoteAddress);
    }

    /**
     * トークンを他のチェーンに送信
     */
    function sendTokens(
        bytes32 destinationChainID,
        address destinationAddress,
        uint256 amount
    ) external {
        require(
            remoteTokenAddresses[destinationChainID] != address(0),
            "TeleporterERC20: remote not set"
        );
        require(amount > 0, "TeleporterERC20: zero amount");

        // トークンをburn
        _burn(msg.sender, amount);

        // メッセージをエンコード
        bytes memory message = abi.encode(destinationAddress, amount);

        // Teleporterでメッセージを送信
        teleporterMessenger.sendCrossChainMessage(
            ITeleporterMessenger.TeleporterMessageInput({
                destinationBlockchainID: destinationChainID,
                destinationAddress: remoteTokenAddresses[destinationChainID],
                feeInfo: ITeleporterMessenger.TeleporterFeeInfo({
                    feeTokenAddress: address(0),
                    amount: 0
                }),
                requiredGasLimit: 200000,
                allowedRelayerAddresses: new address[](0),
                message: message
            })
        );

        emit TokensSent(destinationChainID, destinationAddress, amount);
    }

    /**
     * Teleporterからメッセージを受信
     */
    function receiveTeleporterMessage(
        bytes32 teleporterMessageID,
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external onlyTeleporter {
        // 送信元が登録されたリモートトークンアドレスか確認
        require(
            originSenderAddress == remoteTokenAddresses[originChainID],
            "TeleporterERC20: unauthorized sender"
        );

        // メッセージをデコード
        (address recipient, uint256 amount) = abi.decode(
            message,
            (address, uint256)
        );

        // トークンをmint
        _mint(recipient, amount);

        emit TokensReceived(originChainID, recipient, amount);
    }
}
