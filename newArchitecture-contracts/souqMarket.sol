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
        require(_verifyBidderOffer(_nftContAddress, _tokenID, _currencyAddress, _bid, _bidderSig, _bidder), "Bidders offer not verified");
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

//    function acceptBid(
//        string memory _contractType,
//        address _collection,
//        address _winner,
//        address _erc20Address,
//        address _owner,
//        address[] memory _rewardAccounts,
//        uint256 _bidAmount,
//        uint256[] memory _tokenIdAmount,
//        uint256[] memory _shares,
//        bytes memory _signatureOfBidder,
//        bytes memory _signedRewardAccounts
//    ) public {
//        require(_verify(_collection, _tokenIdAmount[0], _bidAmount, _signatureOfBidder, _winner), "The winner signature is not valid");
//        require (hasRole(SIGNER_ROLE,ECDSA.recover(keccak256(abi.encodePacked(_rewardAccounts)), _signedRewardAccounts)), "Reward accounts are not valid");
//        {
//            uint256 counter = _bidAmount;
//            ERC20 erc20 = ERC20(_erc20Address);
//            require(erc20.balanceOf(_winner) >= _bidAmount, "Not enough weth in the winner wallet");
//            for(uint256 i = 0; i< _shares.length ; i++ ){
//                require(counter >= _shares[i], "The shares are greater than bid amount");
//                counter = counter - _shares[i];
//                erc20.transferFrom(_winner, _rewardAccounts[i], _shares[i]);
//            }
//        }
//        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))) {
//            ERC721 erc721 = ERC721(_collection);
//            erc721.transferFrom(_owner,_winner, _tokenIdAmount[0]);
//        }
//        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155")))) {
//            ERC1155 erc1155 = ERC1155(_collection);
//            erc1155.safeTransferFrom(_owner,_winner, _tokenIdAmount[0], _tokenIdAmount[1], "");
//        }
//    }
}