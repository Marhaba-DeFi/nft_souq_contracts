// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SouqMarketPlace is EIP712{
    using SafeMath for uint256;
    address private _mediaContract;
    address public owner;

    struct Collaborators {
        address[] _collaborators;
        uint8[] _percentages;
        bool _receiveCollabShare;
    }

    constructor (string memory _name, string memory _version) EIP712 (_name, _version) {
        owner = msg.sender;
    }

    modifier mediaOrOwner() {
        require(msg.sender == owner || msg.sender == _mediaContract, "Not media nor owner");
        _;
    }

    modifier onlyOwner (){
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyMedia (){
        require(msg.sender == _mediaContract, "Not the media contract");
        _;
    }

    function configureMedia(address _mediaContractAddress) external onlyOwner {
        require(
            _mediaContractAddress != address(0),
            "ERC721Factory: Invalid Media Contract Address!"
        );
        // do not allow already configured!!!
        _mediaContract = _mediaContractAddress;
    }

    // nftContract => tokenID => creator's Royalty Percentage
    mapping(address => mapping(uint256 => uint8)) private tokenRoyaltyPercentage;

    // nftContract => tokenID => { collaboratorsAddresses[] , percentages[] }
    mapping(address => mapping(uint256 => Collaborators)) private tokenCollaborators;

    // Approved erc20 tokens only accessible by the admin of souq
    mapping(address => bool) private approvedCurrency;

    /**
     * @dev See {IMarket}
     */
    function setCollaborators(
        address _nftAddress,
        uint256 _tokenID,
        Collaborators calldata _collaborators
    ) external onlyMedia {
        tokenCollaborators[_nftAddress][_tokenID] = _collaborators;
    }

    // /**
    //  * @dev See {IMarket}
    //  */
    // function setRoyaltyPoints(address _nftAddress, uint256 _tokenID, uint8 _royaltyPoints)
    // external
    // override
    // onlyMediaCaller
    // {
    //     tokenRoyaltyPercentage[_nftAddress][_tokenID] = _royaltyPoints;
    //     emit RoyaltyUpdated(_tokenID, _royaltyPoints);
    // }

    function setApprovedCrypto(address _currencyAddress, bool approving) public onlyOwner {
        approvedCurrency[_currencyAddress] = approving;
    }

    function hashOffer(address nftContAddress, uint256 tokenID, address currencyAddress, uint256 bid ) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(keccak256("Bid(address nftContAddress,uint256 tokenID,address currencyAddress,uint256 bid)"),
            nftContAddress,
            tokenID,
            currencyAddress,
            bid
            )));
    }

    function _verifyBidderOffer(address _nftContAddress, uint256 _tokenID, address _currencyAddress, uint256 _bid, bytes memory _bidderSig, address _bidder) internal view returns (bool) {

        bytes32  _bidderOfferHash = hashOffer(_nftContAddress,_tokenID,_currencyAddress,_bid);
        return (ECDSA.recover(_bidderOfferHash, _bidderSig) == _bidder);
    }

    function _verifySellerOffer(address _nftContAddress, uint256 _tokenID, address _currencyAddress, uint256 _bid, bytes memory _sellerSig, address _seller) internal view returns (bool) {

        bytes32  _sellerOfferHash = hashOffer(_nftContAddress,_tokenID,_currencyAddress,_bid);
        return (ECDSA.recover(_sellerOfferHash, _sellerSig) == _seller);
    }

    function acceptBid(
        string memory _contractType,
        address _nftContAddress,
        address _currencyAddress,
        address _seller,
        address _bidder,
        uint256 _tokenID,
        uint256 _bid,
        uint256 _copies,
        bytes memory _bidderSig,
        bytes memory _sellerSig
    ) public mediaOrOwner {

        // Make sure the erc20 currency is approved by the admin
        require(approvedCurrency[_currencyAddress] == true, "Not an approved cryptocurrency for bidding");

        //Make sure the bidder signiture is valid
        require(_verifyBidderOffer(_nftContAddress, _tokenID, _currencyAddress, _bid, _bidderSig, _bidder), "Bidders offer not verified");

        //Make sure the seller signiture is valid
        require(_verifySellerOffer(_nftContAddress, _tokenID, _currencyAddress, _bid, _sellerSig, _seller), "Bidders offer not verified");

        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))) {
            ERC721 erc721 = ERC721(_nftContAddress);
            erc721.transferFrom(_seller,_bidder, _tokenID);
        }
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155")))) {
            ERC1155 erc1155 = ERC1155(_nftContAddress);
            erc1155.safeTransferFrom(_seller,_bidder, _tokenID, _copies, "");
        }
    }
}