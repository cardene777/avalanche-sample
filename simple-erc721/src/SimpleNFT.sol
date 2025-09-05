// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * OpenZeppelinのERC721を継承したシンプルなNFTコントラクト
 * 誰でもmintできるパブリックなNFT
 **/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SimpleNFT is ERC721, Ownable {
    uint256 private _nextTokenId;
    
    // NFTのベースURI（メタデータの保存先）
    string private _baseTokenURI;
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * 誰でもNFTをmintできる関数
     * @param to NFTを受け取るアドレス
     * @return tokenId 発行されたNFTのID
     */
    function mint(address to) public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }
    
    /**
     * 複数のNFTを一度にmint
     * @param to NFTを受け取るアドレス
     * @param amount mint数
     */
    function mintBatch(address to, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= 20, "Cannot mint more than 20 at once");
        
        for (uint256 i = 0; i < amount; i++) {
            mint(to);
        }
    }
    
    /**
     * ベースURIを設定（オーナーのみ）
     * @param baseTokenURI 新しいベースURI
     */
    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * トークンURIを返す
     * @param tokenId トークンID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string.concat(baseURI, Strings.toString(tokenId))
            : "";
    }
    
    /**
     * ベースURIを返す
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * 現在の総供給量を返す
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId;
    }
}