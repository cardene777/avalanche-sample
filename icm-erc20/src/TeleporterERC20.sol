// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ITeleporterReceiver} from "@avalabs/teleporter/ITeleporterReceiver.sol";
import {ITeleporterMessenger, TeleporterMessageInput, TeleporterFeeInfo} from "@avalabs/teleporter/ITeleporterMessenger.sol";

/**
 * @title TeleporterERC20
 * @dev Teleporter機能を持つERC20トークン
 * クロスチェーン転送が可能で、誰でもmintできる仕様
 */
contract TeleporterERC20 is ERC20, Ownable, ITeleporterReceiver {
    ITeleporterMessenger public teleporterMessenger;

    // チェーンごとのトークンアドレスマッピング
    // mapping(bytes32 => address) public remoteTokenAddresses;

    // イベント
    event TokensSent(
        bytes32 indexed destinationChainID,
        address indexed destinationAddress,
        address indexed recipient,
        uint256 amount
    );

    event TokensReceived(
        bytes32 indexed originChainID,
        address indexed from,
        uint256 amount
    );

    // event RemoteAddressSet(
    //     bytes32 indexed chainID,
    //     address indexed remoteAddress
    // );

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

    function setTeleporterMessenger(
        address _teleporterMessenger
    ) external onlyOwner {
        require(
            _teleporterMessenger != address(0),
            "TeleporterERC20: zero address"
        );
        teleporterMessenger = ITeleporterMessenger(_teleporterMessenger);
    }

    /**
     * @dev 誰でもトークンをmintできる
     * @param to 受信者アドレス
     * @param amount mint量
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // /**
    //  * @dev リモートチェーンのトークンアドレスを設定
    //  * @param chainID チェーンID
    //  * @param remoteAddress トークンアドレス
    //  */
    // function setRemoteTokenAddress(
    //     bytes32 chainID,
    //     address remoteAddress
    // ) external onlyOwner {
    //     require(remoteAddress != address(0), "TeleporterERC20: zero address");
    //     remoteTokenAddresses[chainID] = remoteAddress;
    //     emit RemoteAddressSet(chainID, remoteAddress);
    // }

    /**
     * @dev トークンを他のチェーンに送信
     * @param destinationChainID 送信先チェーンID
     * @param destinationAddress 受信者アドレス
     * @param recipient 受取人アドレス
     * @param amount 転送量
     */
    function sendTokens(
        bytes32 destinationChainID,
        address destinationAddress,
        address recipient,
        uint256 amount
    ) external {
        // require(
        //     remoteTokenAddresses[destinationChainID] != address(0),
        //     "TeleporterERC20: remote not set"
        // );
        require(amount > 0, "TeleporterERC20: zero amount");

        // トークンをburn
        _burn(msg.sender, amount);

        // メッセージをエンコード
        bytes memory message = abi.encode(recipient, amount);

        // Teleporterでメッセージを送信
        teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: destinationChainID,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({
                    feeTokenAddress: address(0),
                    amount: 0
                }),
                requiredGasLimit: 500000,
                allowedRelayerAddresses: new address[](0),
                message: message
            })
        );

        emit TokensSent(
            destinationChainID,
            destinationAddress,
            recipient,
            amount
        );
    }

    /**
     * @dev Teleporterからメッセージを受信
     * @param originChainID ソースチェーンID
     * @param 送信元アドレス
     * @param message メッセージペイロード
     */
    function receiveTeleporterMessage(
        bytes32 originChainID,
        address,
        bytes calldata message
    ) external onlyTeleporter {
        // 送信元が登録されたリモートトークンアドレスか確認
        // require(
        //     originSenderAddress == remoteTokenAddresses[originChainID],
        //     "TeleporterERC20: unauthorized sender"
        // );

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
