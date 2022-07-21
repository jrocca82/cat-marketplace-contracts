// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IMarketplace.sol";
import "./KittyContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KittyMarketplace is Ownable, IMarketPlace {
    using Counters for Counters.Counter;
    KittyContract private _kittyContract;
    address public kittyContractAddress;

    struct Offer {
        address payable seller;
        uint256 price;
        uint256 index;
        uint256 tokenId;
        bool active;
    }

    Offer[] offers;

    //Map tokenId to offers listing
    mapping(uint256 => Offer) tokenIdToOffers;

    constructor(KittyContract kittyContract) IMarketPlace() {
        require(address(kittyContract) != address(0));
        _kittyContract = kittyContract;
    }

    function setContract(address _kittyContractAddress) public onlyOwner{
        kittyContractAddress = _kittyContractAddress;
    }

    function getOffer(uint256 _tokenId) public view returns ( address seller, uint256 price, uint256 index, uint256 tokenId, bool active) {
        Offer memory offer = tokenIdToOffers[_tokenId];
        return(
            offer.seller,
            offer.price,
            offer.index,
            offer.tokenId,
            offer.active
        );
    }

    function getAllTokenOnSale() external view  returns(uint256[] memory _listOfOffers) {
        uint256 totalOffers = offers.length;

        if (totalOffers == 0) {
            uint256[] memory emptyArray = new uint256[](0);
            return emptyArray;
        }

        uint256[] memory result = new uint256[](totalOffers);
        uint256 offerId;

        for (offerId = 0; offerId <= totalOffers; offerId++) {
            if(offers[offerId].active == true){
                result[offerId] = offers[offerId].tokenId;
            }
        }
        return result;
    }

    function setOffer(uint256 _price, uint256 _tokenId) external {
        require(_kittyContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this token");
        require(tokenIdToOffers[_tokenId].active == false, "This token is already listed");

        _kittyContract.approve(address(this), _tokenId);

        Offer storage newOffer = tokenIdToOffers[_tokenId];

        newOffer.active = true;
        newOffer.index = offers.length;
        newOffer.price = _price;
        newOffer.seller = payable(msg.sender);
        newOffer.tokenId = _tokenId;

        offers.push(newOffer);

        emit MarketTransaction("Create offer", msg.sender, _tokenId);
    }

    function removeOffer(uint256 _tokenId) public {
        require(_kittyContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this token");

        Offer memory offer = tokenIdToOffers[_tokenId];
        delete offer;
        offers[tokenIdToOffers[_tokenId].index].active = false;

        emit MarketTransaction("Remove offer", msg.sender, _tokenId);
    }

    function buyItem(uint256 _tokenId) external payable {
        Offer memory offer = tokenIdToOffers[_tokenId];
        require(msg.value == offer.price, "Insufficient funds");
        require(tokenIdToOffers[_tokenId].active == true, "This sale is not active");

        delete offer;
        offers[tokenIdToOffers[_tokenId].index].active = false;

        //Transfer funds to seller
        offer.seller.transfer(msg.value);

        //Transfer token
        _kittyContract.safeTransferFrom(offer.seller, msg.sender, _tokenId);

        emit MarketTransaction("Buy", msg.sender, _tokenId);
    }
}