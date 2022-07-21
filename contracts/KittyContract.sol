// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Kitty is IERC721, Ownable {
    /** @dev Counts the number of tokens minted */
    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter;
    Counters.Counter private gen0Counter;

    bytes4 internal constant magic_data = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    uint16 maxGen0 = 1000;

    string public constant nameOfToken = "Cryp-Jo Kitties";
    string public constant symbolOfToken = "CJK";

    //Map tokenId to owner
    mapping(uint256 => address) public tokenOwner;

    //Map owner to number of tokens owned
    mapping(address => uint16) tokensOwned;

    //Map tokenId to approved addresses
    mapping(uint256 => address) public approvedAddress;

    //Map token owner address to operator address to approval status (for approving entire token collection)
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //Interface IDs
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    //Events
    event Birth(address owner, uint256 tokenId, uint256 momId, uint256 dadId, uint256 genes);

    struct KittyData {
        uint256 genes;
        uint64 birthTime;
        uint32 momId;
        uint32 dadId;
        uint16 generation;
    }

    modifier approvedOrOwner(address _from, address _to, uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender 
                || approvedAddress[_tokenId] == msg.sender
                || _operatorApprovals[_from][msg.sender] == true, 
                "You are not authorized to transfer this token");
        require(_from == msg.sender, "Trying to transfer from the wrong address");
        require(_to != address(0), "Cannot transfer to zero address");
        _;
    }

    //Map tokenId to Kitty struct
    mapping(uint256 => KittyData) kitties;

    constructor() IERC721() {}

    // SUPPORTING FUNCTIONS
    function increasedTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    function supportsERC721 (bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == _INTERFACE_ID_ERC721 || interfaceId == _INTERFACE_ID_ERC165);
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

    function ownerOf(uint256 tokenId) public view returns (address owner) {
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

    function approve(address _approved,uint256  _tokenId) external {
        require(_approved != address(0), "Cannot approve address 0");
        require(ownerOf(_tokenId) == msg.sender, "You do not own this token");
        require(_approved != msg.sender, "Already approved as token owner");
        require(approvedAddress[_tokenId] != _approved, "Already approved");
        require(_tokenId <= tokenCounter.current(), "This token does not exist");
        approvedAddress[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0), "Cannot assign address zero as operator");
        require(_operator != msg.sender, "Token owner does not need approval");
        bool approvalStatus = _approved;
        _operatorApprovals[msg.sender][_operator] = approvalStatus;
    }
    
    //Get approved addresses for a token
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokenId <= tokenCounter.current(), "This token does not exist");
        return approvedAddress[_tokenId];
    }

    //get status of whether an operator is approved for the tokens of owner address
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public approvedOrOwner(_from, _to, _tokenId){
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public approvedOrOwner(from, to, tokenId){
        require (from != address(0), "Cannot send from zero address");
        require (to != address(0), "Cannot send to zero address");
        require (tokenId <= tokenCounter.current(), "Token does not exist");

        bytes4 returnData = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "");

        if (isContract(to)) {
            require(returnData == magic_data, "Does not support ERC721");
        }

        _transfer(from, to, tokenId);
    }

    function isContract(address _addr) internal view returns (bool _isContract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}