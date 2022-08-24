// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../ERC1155Factory/ERC1155FactoryFacet.sol";
import "../ERC721Factory/ERC721FactoryFacet.sol";
import "./LibMediaStorage.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../EIP712/EIP712Facet.sol";
import "../Market/MarketFacet.sol";

contract MediaFacet {
    AppStorage internal s;

    function mediaFacetInit(
        address _diamondAddress
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(
            ms.diamondAddress == address(0),
            "ALREADY_INITIALIZED"
        );

        require(_diamondAddress != address(0), "Media: Invalid Address!");

        require(msg.sender == ds.contractOwner, "Must own the contract.");

        ms.diamondAddress = _diamondAddress;
        s._mediaContract = _diamondAddress;
    }

    function mintTokenMedia(
        address _to,
        uint256 _id,
        string memory _contractType,
        uint256 _copies,
        string memory _uri,
        bool tokenRoyalty,
        address[] calldata _royaltyReceivers,
        uint96[] calldata _tokenRoyaltyInBips
    ) external returns (uint256)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        bool _isFungible = keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155"))) ? true : false;

        // if token supply is 1 means we need to mint ERC 721 otherwise ERC 1155
        // TODO: add tokenRoyalty to mint function when it is added to token contract 
        if (_isFungible) {
            ERC1155FactoryFacet(ms.diamondAddress).mint(
                _id,
                _to,
                _copies,
				_uri,
                _royaltyReceivers,
                _tokenRoyaltyInBips  
            );
        } else {
            ERC721FactoryFacet(ms.diamondAddress).mint(
                _id,
                _to, 
                _uri,
                _royaltyReceivers,
                _tokenRoyaltyInBips 
            );
        }
        return _id;
    }

    //SetCollaborators() to set collaborators in marketplace contract
    //TODO: research on how to set the collaborators for 1155. 

	function setCollaboratorsMedia (
		address _nftAddress, 
		uint256 _tokenID, 
		address[] calldata _collaborators,  
		uint96[] calldata _collabFraction
		) 
		public 
	{
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        if(_nftAddress == ms.diamondAddress){
        require(ERC721FactoryFacet(_nftAddress).ownerOf(_tokenID) == msg.sender , "Only token owner could call this function");
        MarketFacet(ms.diamondAddress).setCollaborators(
            _nftAddress,
            _tokenID,
            _collaborators,
            _collabFraction
        );
        } else {
            require(IERC721(_nftAddress).ownerOf(_tokenID) == msg.sender , "Only token owner could call this function");
            MarketFacet(ms.diamondAddress).setCollaborators(
            _nftAddress,
            _tokenID,
            _collaborators,
            _collabFraction
            );
        }
    }

    function getCollaboratorsMedia(
        address _nftAddress,
        uint256 _tokenID
    ) public view returns (LibMarketStorage.Collaborators memory) 
	{
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return(MarketFacet(ms.diamondAddress).getCollaborators(
            _nftAddress,
            _tokenID
        ));
    }

    function setApprovedCryptoMedia (
        address _currencyAddress, 
		bool approving
    ) 
    public 
	{
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        require(msg.sender == MarketFacet(ms.diamondAddress).getAdminAddress() , "Media: Caller is not the admin of market place contract");
        MarketFacet(ms.diamondAddress).setApprovedCrypto(
            _currencyAddress, 
            approving
        );
    }

    function getApprovedCryptoMedia (
        address _currencyAddress
	) view public returns(bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return(MarketFacet(ms.diamondAddress).getApprovedCrypto(_currencyAddress));
    }

    //Authorise marketplace contract for all NFT tokens and ERC20 tokens

    function approveMarketForAllMedia () public 
	{
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        ERC1155FactoryFacet(ms.diamondAddress).setApprovalForAll(ms.diamondAddress, true);
    }

    function getAdminCommissionPercentageMedia() external view returns (uint96) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return MarketFacet(ms.diamondAddress).getCommissionPercentage();
    }


//TODO: Check whether we need upper thershold for comission percentage 
    function setCommissionPercentageMedia(uint96 _newCommissionPercentage)
        external
        returns (bool)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        require(
            msg.sender == MarketFacet(ms.diamondAddress).getAdminAddress(),
            "Media: Only Admin Can Set Commission Percentage!"
        );
        require(
            _newCommissionPercentage > 0,
            "Media: Invalid Commission Percentage"
        );
        require(
            _newCommissionPercentage <= 10000,
            "Media: Commission Percentage Must Be Less Than 100!"
        );

        MarketFacet(ms.diamondAddress).setCommissionPercentage(
            _newCommissionPercentage
        );
        return true;
    }

    function istokenIdExistMedia(
        uint256 _tokenID,
        string memory _contractType
    ) external view returns (bool)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))){
            return(ERC721FactoryFacet(ms.diamondAddress)._tokenExists(_tokenID));
        } 
    }

    function burnTokenMedia(
        uint256 _tokenID,
        string memory _contractType,
        uint256 amount
    ) external
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))){
            ERC721FactoryFacet(ms.diamondAddress).burn(_tokenID);
        } 

        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155")))){
            ERC1155FactoryFacet(ms.diamondAddress).burn(msg.sender,_tokenID,amount);
        } 
    }

    //AcceptBid() 
	function acceptBidMedia(
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
    ) public 
	{
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
		MarketFacet(ms.diamondAddress).acceptBid(
			_contractType,
			_nftContAddress,
			_currencyAddress,
			_seller,
			_bidder,
			_tokenID,
			_bid,
            _copies,
			_bidderSig,
			_sellerSig
		);
	}

}