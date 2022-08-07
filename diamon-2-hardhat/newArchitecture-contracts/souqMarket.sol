// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts@4.6.0/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts@4.6.0/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts@4.6.0/utils/math/SafeMath.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.6.0/token/common/ERC2981.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SouqMarketPlace is EIP712{
    using SafeMath for uint256;
    address private _mediaContract;
    address public owner;

    address private _adminAddress;

    // To store commission percentage for each mint
    uint8 private _adminCommissionPercentage;

    struct Collaborators {
        address[] collaborators;
        uint96[] collabFraction;
    }

    constructor (
		string memory _name, 
		string memory _version
	) EIP712 (_name, _version) {
        owner = msg.sender;
    }

    modifier mediaOrOwner() 
	{
        require(msg.sender == owner || msg.sender == _mediaContract, "Not media nor owner");
        _;
    }

    modifier onlyOwner ()
	{
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyMedia ()
	{
        require(msg.sender == _mediaContract, "Not the media contract");
        _;
    }

    function configureMedia(address _mediaContractAddress) external onlyOwner 
	{
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

    function setAdminAddress(address _newAdminAddress)
        external
        onlyOwner
        returns (bool)
    {
        require(
            _newAdminAddress != address(0),
            "Market: Invalid Admin Address!"
        );
        require(
            _adminAddress == address(0),
            "Market: Admin Already Configured!"
        );

        _adminAddress = _newAdminAddress;
        //emit AdminUpdated(_adminAddress);
        return true;
    }

    function getAdminAddress()
        external
        view
        onlyOwner
        returns (address)
    {
        return _adminAddress;
    }

    function setCommissionPercentage(uint8 _commissionPercentage)
        external
        mediaOrOwner
        returns (bool)
    {
        _adminCommissionPercentage = _commissionPercentage;
        // emit CommissionUpdated(_adminCommissionPercentage);
        return true;
    }

    function getCommissionPercentage()
        external
        view
        mediaOrOwner
        returns (uint8)
    {
        return _adminCommissionPercentage;
    }


    function setCollaborators(
        address _nftAddress,
        uint256 _tokenID,
        address[] calldata _collaborators,  
        uint96[] calldata _collabFraction
    ) external mediaOrOwner 
	{

        Collaborators memory collabStruct;
        collabStruct.collaborators = _collaborators;
        collabStruct.collabFraction = _collabFraction;

        tokenCollaborators[_nftAddress][_tokenID] = collabStruct;
    }

    function setApprovedCrypto(
		address _currencyAddress, 
		bool approving
	) public onlyOwner 
	{
        approvedCurrency[_currencyAddress] = approving;
    }

    function hashOffer(
		address nftContAddress, 
		uint256 tokenID, 
		uint256 copies, 
		address currencyAddress, 
		uint256 bid 
	) internal view returns (bytes32) 
	{
        return _hashTypedDataV4(keccak256(abi.encode(keccak256("Bid(address nftContAddress,uint256 tokenID,uint256 copies,address currencyAddress,uint256 bid)"),
            nftContAddress,
            tokenID,
            copies,
            currencyAddress,
            bid
            )));
    }

    function _verifyBidderOffer(
		address _nftContAddress, 
		uint256 _tokenID, 
		uint256 _copies, 
		address _currencyAddress, 
		uint256 _bid, 
		bytes memory _bidderSig, 
		address _bidder
	) internal view returns (bool) 
	{
        bytes32  _bidderOfferHash = hashOffer(_nftContAddress,_tokenID,_copies,_currencyAddress,_bid);
        return (ECDSA.recover(_bidderOfferHash, _bidderSig) == _bidder);
    }

    function _verifySellerOffer(
		address _nftContAddress, 
		uint256 _tokenID, 
		uint256 _copies, 
		address _currencyAddress, 
		uint256 _bid, 
		bytes memory _sellerSig, 
		address _seller
	) internal view returns (bool) 
	{
        bytes32  _sellerOfferHash = hashOffer(_nftContAddress,_tokenID,_copies,_currencyAddress,_bid);
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
    ) public mediaOrOwner 
	{
        // Make sure the erc20 currency is approved by the admin
        require(approvedCurrency[_currencyAddress] == true, "Not an approved cryptocurrency for bidding");

        //Make sure the bidder signiture is valid
        require(_verifyBidderOffer(_nftContAddress, _tokenID, _copies,  _currencyAddress, _bid, _bidderSig, _bidder), "Bidders offer not verified");

        //Make sure the seller signiture is valid
        require(_verifySellerOffer(_nftContAddress, _tokenID, _copies,  _currencyAddress, _bid, _sellerSig, _seller), "Bidders offer not verified");

        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))) {
            cryptoDistributor(_currencyAddress, _nftContAddress, _bidder, _seller, _bid, _tokenID );
            ERC721 erc721 = ERC721(_nftContAddress);
            erc721.transferFrom(_seller,_bidder, _tokenID);
        }
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155")))) {
            cryptoDistributor(_currencyAddress, _nftContAddress, _bidder, _seller, _bid, _tokenID );
            ERC1155 erc1155 = ERC1155(_nftContAddress);
            erc1155.safeTransferFrom(_seller,_bidder, _tokenID, _copies, "");
        }
    }

    function cryptoDistributor(
		address _currencyAddress, 
		address _nftContAddress, 
		address _payer, 
		address _payee, 
		uint256 amount, 
		uint256 _tokenID
	) internal returns (bool) 
	{       
        ERC2981 erc2981 = ERC2981(_nftContAddress);
        ERC20 erc20 = ERC20(_currencyAddress);
        require(erc20.balanceOf(_payer) >= amount, "ERC20 in the payer address is not enough");
        /** TODO: cut Admin fee */
        (address royalityAddress, uint256 royalityFee) = erc2981.royaltyInfo(_tokenID, amount);
        erc20.transferFrom(_payer, royalityAddress, royalityFee);
        uint256 remained = amount - royalityFee;

        Collaborators storage _collab = tokenCollaborators[_nftContAddress][_tokenID];

        for(uint256 i = 0; i< _collab.collaborators.length ; i++ ){
            uint256 collabShare = (remained * _collab.collabFraction[i]) / 10000;
            remained = remained - collabShare;
            erc20.transferFrom(_payer, _collab.collaborators[i], collabShare);
        }
        erc20.transferFrom(_payer, _payee, remained);
        return true;
    }
}