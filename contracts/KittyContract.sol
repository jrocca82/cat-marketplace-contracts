// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Kitty is IERC721, Ownable {
    /** @dev Counts the number of tokens minted */
    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter;
    Counters.Counter private gen0Counter;

    uint16 maxGen0 = 1000;

    string public constant nameOfToken = "Cryp-Jo Kitties";
    string public constant symbolOfToken = "CJK";

    //Map tokenId to owner
    mapping(uint256 => address) tokenOwner;

    //Map owner to number of tokens owned
    mapping(address => uint16) tokensOwned;

    //Events
    event Birth(address owner, uint256 tokenId, uint256 momId, uint256 dadId, uint256 genes);

    struct KittyData {
        uint256 genes;
        uint64 birthTime;
        uint32 momId;
        uint32 dadId;
        uint16 generation;
    }

    //Map tokenId to Kitty struct
    mapping(uint256 => KittyData) kitties;

    constructor() IERC721() {}

    // SUPPORTING FUNCTIONS
    function increasedTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return tokensOwned[owner];
    }

    function totalSupply() external view returns (uint256 total) {
        return tokenCounter.current();
    }

    function name() pure public returns (string memory tokenName) {
        return nameOfToken;
    }

    function symbol() pure public returns (string memory tokenSymbol) {
        return symbolOfToken;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(tokenId >=0 && tokenId <= tokenCounter.current(), "Token does not exist or has not been minted");
        return tokenOwner[tokenId];
    }

    function transfer(address to, uint256 tokenId) external {
        require(to != address(0), "Cannot send to zero address");
        require(to != address(this), "Cannot send to contract address");
        require(tokenOwner[tokenId] == msg.sender, "You do not own this token");

        _transfer(msg.sender, to, tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        tokensOwned[_to]++;
        tokenOwner[_tokenId] = _to;

        if(_from != address(0)){
            tokensOwned[_from]--;
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function createKitty(
        uint256 _genes,
        uint256 _momId,
        uint256 _dadId,
        uint256 _generation,
        address _owner
    ) internal returns (uint256 tokenId){
        uint256 kittyId = increasedTokenId();

        //create new Kitty and add to kitties mapping
        KittyData storage _kitty = kitties[kittyId];
        _kitty.genes = _genes;
        _kitty.birthTime = uint64(block.timestamp);
        _kitty.momId = uint32(_momId);
        _kitty.dadId = uint32(_dadId);
        _kitty.generation = uint16(_generation);

        emit Birth(_owner, kittyId, _momId, _dadId, _genes);

        _transfer(address(0), _owner, kittyId);

        return kittyId;
    }

    function createKittyGen0(uint256 genes) public onlyOwner {
        require(gen0Counter.current() < maxGen0, "No more gen 0 cats left");

        gen0Counter.increment();

        createKitty(genes, 0, 0, 0, msg.sender);
    }

    function getKittyData(uint256 _tokenId) external view returns (
        uint256 genes,
        uint256 birthTime,
        uint256 momId,
        uint256 dadId,
        uint256 generation,
        address owner
    ) {
       KittyData storage kitty = kitties[_tokenId];

       genes = uint256(kitty.genes);
       birthTime = uint256(kitty.birthTime);
       momId = uint256(kitty.momId);
       dadId = uint256(kitty.dadId);
       generation = uint256(kitty.generation);
       owner = tokenOwner[_tokenId];
    }
}