// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//Import your contract
import "./KittyContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * Market place to trade items (should **in theory** be used for any ERC721 token)
 * It needs an existing Item contract to interact with
 * Note: it does not inherit from the item contracts
 * Note: The contract needs to be an operator for everyone who is selling through this contract.
 */
interface IMarketPlace{

    event MarketTransaction(string TxType, address owner, uint256 tokenId);

    /**
    * Set the current Item Contract address and initialize the instance of ItemContract.
    * Requirement: Only the contract owner can call.
     */
    function setContract(address _itemContractAddress) external;

    /**
    * Get the details about a offer for _tokenId. Throws an error if there is no active offer for _tokenId.
     */
    function getOffer(uint256 _tokenId) external view returns ( address seller, uint256 price, uint256 index, uint256 tokenId, bool active);

    /**
    * Get all tokenId's that are currently for sale. Returns an empty arror if none exist.
     */
    function getAllTokenOnSale() external view  returns(uint256[] memory listOfOffers);

    /**
    * Creates a new offer for _tokenId for the price _price.
    * Emits the MarketTransaction event with txType "Create offer"
    * Requirement: Only the owner of _tokenId can create an offer.
    * Requirement: There can only be one active offer for a token at a time.
    * Requirement: Marketplace contract (this) needs to be an approved operator when the offer is created.
     */
    function setOffer(uint256 _price, uint256 _tokenId) external;

    /**
    * Removes an existing offer.
    * Emits the MarketTransaction event with txType "Remove offer"
    * Requirement: Only the seller of _tokenId can remove an offer.
     */
    function removeOffer(uint256 _tokenId) external;

    /**
    * Executes the purchase of _tokenId.
    * Sends the funds to the seller and transfers the token using transferFrom in ItemContract.
    * Emits the MarketTransaction event with txType "Buy".
    * Requirement: The msg.value needs to equal the price of _tokenId
    * Requirement: There must be an active offer for _tokenId
     */
    function buyItem(uint256 _tokenId) external payable;
}
