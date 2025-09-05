// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * SimpleNFTコントラクトのテスト
 **/

import {Test, console} from "forge-std/Test.sol";
import {SimpleNFT} from "../src/SimpleNFT.sol";

contract SimpleNFTTest is Test {
    SimpleNFT public nft;
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    string constant NAME = "Simple NFT";
    string constant SYMBOL = "SNFT";
    string constant BASE_URI = "https://api.example.com/metadata/";

    function setUp() public {
        nft = new SimpleNFT(NAME, SYMBOL, BASE_URI);
    }

    /**
     * コンストラクタのテスト
     */
    function test_Constructor() public view {
        assertEq(nft.name(), NAME);
        assertEq(nft.symbol(), SYMBOL);
        assertEq(nft.owner(), owner);
        assertEq(nft.totalSupply(), 0);
    }

    /**
     * mint関数の成功パターン
     */
    function test_Mint_Success() public {
        uint256 tokenId = nft.mint(user1);

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.balanceOf(user1), 1);
    }

    /**
     * 複数回mint
     */
    function test_MultipleMints() public {
        uint256 tokenId1 = nft.mint(user1);
        uint256 tokenId2 = nft.mint(user2);
        uint256 tokenId3 = nft.mint(user1);

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(tokenId3, 2);

        assertEq(nft.balanceOf(user1), 2);
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.totalSupply(), 3);
    }

    /**
     * mintBatch関数の成功パターン
     */
    function test_MintBatch_Success() public {
        uint256 amount = 5;
        nft.mintBatch(user1, amount);

        assertEq(nft.balanceOf(user1), amount);
        assertEq(nft.totalSupply(), amount);

        // 各トークンの所有者確認
        for (uint256 i = 0; i < amount; i++) {
            assertEq(nft.ownerOf(i), user1);
        }
    }

    /**
     * mintBatch関数の失敗パターン - 0個mint
     */
    function test_MintBatch_RevertWhenZeroAmount() public {
        vm.expectRevert("Amount must be greater than 0");
        nft.mintBatch(user1, 0);
    }

    /**
     * mintBatch関数の失敗パターン - 20個超過
     */
    function test_MintBatch_RevertWhenExceedLimit() public {
        vm.expectRevert("Cannot mint more than 20 at once");
        nft.mintBatch(user1, 21);
    }

    /**
     * setBaseURI関数の成功パターン（オーナーのみ）
     */
    function test_SetBaseURI_Success() public {
        string memory newBaseURI = "https://new-api.example.com/metadata/";

        nft.setBaseURI(newBaseURI);

        // mint後にtokenURIを確認
        uint256 tokenId = nft.mint(user1);
        assertEq(nft.tokenURI(tokenId), string.concat(newBaseURI, "0"));
    }

    /**
     * setBaseURI関数の失敗パターン - 非オーナー
     */
    function test_SetBaseURI_RevertWhenNotOwner() public {
        string memory newBaseURI = "https://new-api.example.com/metadata/";

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                user1
            )
        );
        nft.setBaseURI(newBaseURI);
    }

    /**
     * tokenURI関数のテスト
     */
    function test_TokenURI() public {
        uint256 tokenId = nft.mint(user1);
        string memory expectedURI = string.concat(BASE_URI, "0");

        assertEq(nft.tokenURI(tokenId), expectedURI);
    }

    /**
     * tokenURI関数の失敗パターン - 存在しないトークン
     */
    function test_TokenURI_RevertWhenTokenNotExist() public {
        vm.expectRevert(
            abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 999)
        );
        nft.tokenURI(999);
    }

    /**
     * 転送機能のテスト
     */
    function test_Transfer() public {
        uint256 tokenId = nft.mint(user1);

        // user1からuser2へ転送
        vm.prank(user1);
        nft.transferFrom(user1, user2, tokenId);

        assertEq(nft.ownerOf(tokenId), user2);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);
    }

    /**
     * 承認機能のテスト
     */
    function test_Approve() public {
        uint256 tokenId = nft.mint(user1);

        // user1がuser2を承認
        vm.prank(user1);
        nft.approve(user2, tokenId);

        assertEq(nft.getApproved(tokenId), user2);

        // user2が転送実行
        vm.prank(user2);
        nft.transferFrom(user1, user2, tokenId);

        assertEq(nft.ownerOf(tokenId), user2);
    }
}
