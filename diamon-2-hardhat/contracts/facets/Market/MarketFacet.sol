// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/common/ERC2981.sol";


import "./LibMarketStorage.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../EIP712/EIP712Facet.sol";
import "../../../newArchitecture-contracts/ERC2981.sol";

contract MarketFacet is EIP712 {
    AppStorage internal s;

    modifier onlyMediaCaller() {
        require(msg.sender == s._mediaContract, "Market Place: Unauthorized Access!");
        _;
    }

    modifier mediaOrOwner() 
	{
         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.contractOwner || msg.sender == s._mediaContract, "Not media nor owner");
        _;
    }

    struct Collaborators {
      address[] collaborators;
      uint96[] collabFraction;
    }

    function marketFacetInit(
        string memory name_,
        string memory version_
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        eip712FacetInit(name_, version_);
        setAdminAddress(ds.contractOwner);
    }

//TODO: Check whether we need to configure admin address for market place contract or not
    function setAdminAddress(
		address adminAddress_
	) public mediaOrOwner {
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        es._adminAddress = adminAddress_;
    }

    function getAdminAddress(
	) view public returns(address) {
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        return(es._adminAddress);
    }

    function setApprovedCrypto(
		address _currencyAddress, 
		bool approving
	) public mediaOrOwner {
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        es._approvedCurrency[_currencyAddress] = approving;
    }

    function getApprovedCrypto(
        address _currencyAddress
	) view public returns(bool) {
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        return(es._approvedCurrency[_currencyAddress]);
    }

    function setCommissionPercentage(
        uint96 _commissionPercentage
    )external mediaOrOwner returns (bool) {
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        es._adminCommissionPercentage = _commissionPercentage;
        return true;
    }

    function getCommissionPercentage(
    ) external view mediaOrOwner returns (uint96) {
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        return es._adminCommissionPercentage;
    }

    function setCollaborators(
        address _nftAddress,
        uint256 _tokenID,
        address[] calldata _collaborators,  
        uint96[] calldata _collabFraction
    ) external mediaOrOwner 
	{
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        LibMarketStorage.Collaborators memory collabStruct ;

        //Collaborators memory collabStruct;
        collabStruct.collaborators = _collaborators;
        collabStruct.collabFraction = _collabFraction;
        es.tokenCollaborators[_nftAddress][_tokenID] = collabStruct;
    }

    function getCollaborators(
        address _nftAddress,
        uint256 _tokenID
    ) external view mediaOrOwner returns (LibMarketStorage.Collaborators memory) 
	{
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        LibMarketStorage.Collaborators memory collabStructReturn ;

        //Collaborators memory collabStructReturn;
        collabStructReturn.collaborators = es.tokenCollaborators[_nftAddress][_tokenID].collaborators;
        collabStructReturn.collabFraction = es.tokenCollaborators[_nftAddress][_tokenID].collabFraction;
        return(collabStructReturn);
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

    function adminFeeDeduction(
		address _currencyAddress, 
		address _payer,
		uint256 amount
	) internal returns (uint256) 
	{
        ERC20 erc20 = ERC20(_currencyAddress);
        // require(erc20.balanceOf(_payer) >= amount, "ERC20 in the payer address is not enough");
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        uint256 addminShare = amount * (es._adminCommissionPercentage/10000);
        erc20.transferFrom(_payer, es._adminAddress, addminShare);
        return addminShare;
    }

    function royalityFeeDeduction(
		address _currencyAddress,
        address _nftContAddress, 
		address _payer,
		uint256 amount,
        uint256 _tokenID
	) public returns (uint256) 
	{
        ERC2981 erc2981 = ERC2981(_nftContAddress);
        ERC20 erc20 = ERC20(_currencyAddress);
        (address[] memory royalityAddresses, uint256[] memory royalityFees) = erc2981.royaltyInfo(_tokenID, amount);
        uint256 royalityFeeAccumulator = 0;
        for(uint256 i = 0; i< royalityAddresses.length ; i++ ){
            erc20.transferFrom(_payer, royalityAddresses[i], royalityFees[i]);
            royalityFeeAccumulator = royalityFeeAccumulator + royalityFees[i];
        }
        return royalityFeeAccumulator;
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
        ERC20 erc20 = ERC20(_currencyAddress);
        require(erc20.balanceOf(_payer) >= amount, "ERC20 in the payer address is not enough");

        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        LibMarketStorage.Collaborators memory _collab ;

        uint256 remained = amount;
        //collaborators fee should be deducted from amount
       _collab = es.tokenCollaborators[_nftContAddress][_tokenID];
        for(uint256 i = 0; i< _collab.collaborators.length ; i++ ){
            uint256 collabShare = (amount * _collab.collabFraction[i]) / 10000;
            remained = amount - collabShare;
            erc20.transferFrom(_payer, _collab.collaborators[i], collabShare);
        }
        //the remained amount would be paided to the owner of nft
        erc20.transferFrom(_payer, _payee, remained);
        return true;
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
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        //Checking the erc20 currency is approved by the admin
        require(es._approvedCurrency[_currencyAddress] == true, "Not an approved cryptocurrency for bidding");

        //Checking the bidder signiture is valid
        require(_verifyBidderOffer(_nftContAddress, _tokenID, _copies,  _currencyAddress, _bid, _bidderSig, _bidder), "Bidders offer not verified");

        //Checking the seller signiture is valid
        require(_verifySellerOffer(_nftContAddress, _tokenID, _copies,  _currencyAddress, _bid, _sellerSig, _seller), "Bidders offer not verified");

        ERC20 erc20 = ERC20(_currencyAddress);
        require(erc20.balanceOf(_bidder) >= _bid, "ERC20 in the payer address is not enough");

        uint256 remained = _bid;
        //admin fee should be deducted from amount
        remained = remained - adminFeeDeduction(_currencyAddress, _bidder, _bid);

        //royalty fee should be deducted from amount
        remained = remained - royalityFeeDeduction(_currencyAddress, _nftContAddress, _bidder, remained, _tokenID);

        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))) {
            cryptoDistributor(_currencyAddress, _nftContAddress, _bidder, _seller, remained, _tokenID );
            ERC721 erc721 = ERC721(_nftContAddress);
            erc721.transferFrom(_seller,_bidder, _tokenID);
        }
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155")))) {
            cryptoDistributor(_currencyAddress, _nftContAddress, _bidder, _seller, remained, _tokenID );
            ERC1155 erc1155 = ERC1155(_nftContAddress);
            erc1155.safeTransferFrom(_seller,_bidder, _tokenID, _copies, "");
        }
    }
}







