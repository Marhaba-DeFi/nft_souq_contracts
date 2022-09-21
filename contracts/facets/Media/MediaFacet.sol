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
    /**
     * @notice All collections minted under souq native contracts interact with MediaFacet.
     * @notice All souq native interactions with token contracts and marketplace contract is done via MediaFacet.
     */

    AppStorage internal s;

    function mediaFacetInit(address _diamondAddress) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(ms.diamondAddress == address(0), "ALREADY_INITIALIZED");

        require(_diamondAddress != address(0), "Media: Invalid Address!");

        require(msg.sender == ds.contractOwner, "Must own the contract.");

        ms.diamondAddress = _diamondAddress;
        s._mediaContract = _diamondAddress;
    }

    /**
     * @notice This function is used for minting new NFT under Souq native collection.
     * @param _id tokenId
     * @param _to address of the owner and creator of the NFT
     * @param _uri tokenURI
     * @param tokenRoyalty flag to determine if the author royalty was set.
     * @param _royaltyReceivers an array of address that will recieve royalty. Max upto 5.
     * @param _tokenRoyaltyInBips an array of royalty percentages. It should match the number of reciever addresses. Max upto 5.
     * @dev mintTokenMedia() for minting the tokens depending on the _contractType
     * @dev If tokenRoyalty is set to false, null values need to be passed for _royaltyReceivers and _tokenRoyaltyInBips.
     */
    function mintTokenMedia(
        address _to,
        uint256 _id,
        string memory _contractType,
        uint256 _copies,
        string memory _uri,
        bool tokenRoyalty,
        address[] calldata _royaltyReceivers,
        uint96[] calldata _tokenRoyaltyInBips
    ) external returns (uint256) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        bool _isFungible = keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155"))) ? true : false;

        // if token supply is 1 means we need to mint ERC 721 otherwise ERC 1155
        // TODO: add tokenRoyalty to mint function when it is added to token contract
        if (_isFungible) {
            ERC1155FactoryFacet(ms.diamondAddress).mint(_id, _to, _copies, _uri, tokenRoyalty, _royaltyReceivers, _tokenRoyaltyInBips);
        } else {
            ERC721FactoryFacet(ms.diamondAddress).mint(_id, _to, _uri, tokenRoyalty, _royaltyReceivers, _tokenRoyaltyInBips);
        }
        return _id;
    }

    /**
     * @notice set collaborators in marketplace contract
     * @dev collaborators are only set for ERC721 collections
     * @param _nftAddress Address of the collection
     * @param _tokenID Token Id
     * @param _collaborators Array of collaborators. Maximum length is 5.
     */
    function setCollaboratorsMedia(
        address _nftAddress,
        uint256 _tokenID,
        address[] calldata _collaborators,
        uint96[] calldata _collabFraction
    ) public {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(_collaborators.length <= 5, "Too many Collaborators");
        require(_collaborators.length > 0, "Collaborators not set");
        require(_collaborators.length == _collabFraction.length, "Mismatch of Collaborators and their share");

        if (_nftAddress == ms.diamondAddress) {
            require(ERC721FactoryFacet(_nftAddress).ownerOf(_tokenID) == msg.sender, "Only token owner could call this function");
            MarketFacet(ms.diamondAddress).setCollaborators(_nftAddress, _tokenID, _collaborators, _collabFraction);
        } else {
            require(IERC721(_nftAddress).ownerOf(_tokenID) == msg.sender, "Only token owner could call this function");
            MarketFacet(ms.diamondAddress).setCollaborators(_nftAddress, _tokenID, _collaborators, _collabFraction);
        }
    }

    /**
     * @dev View function to get collaborators Info
     */
    function getCollaboratorsMedia(address _nftAddress, uint256 _tokenID) public view returns (LibMarketStorage.Collaborators memory) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return (MarketFacet(ms.diamondAddress).getCollaborators(_nftAddress, _tokenID));
    }

    /**
     * @dev Approve crypto currency for the Souq marketPlace
     */
    function setApprovedCryptoMedia(address _currencyAddress, bool approving) public {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        require(msg.sender == MarketFacet(ms.diamondAddress).getAdminAddress(), "Media: Caller is not the admin of market place contract");
        MarketFacet(ms.diamondAddress).setApprovedCrypto(_currencyAddress, approving);
    }

    /**
     * @dev View approved crypto currency for the Souq marketPlace
     */
    function getApprovedCryptoMedia(address _currencyAddress) public view returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return (MarketFacet(ms.diamondAddress).getApprovedCrypto(_currencyAddress));
    }

    /**
     * @dev Authorise marketplace contract for all NFT tokens and ERC20 tokens
     */

    // function approveMarketForAllMedia () public
    // {
    //     LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
    //     ERC1155FactoryFacet(ms.diamondAddress).setApprovalForAll(ms.diamondAddress, true);
    // }

    /**
     * @dev Get the Platform fee
     */
    function getAdminCommissionPercentageMedia() external view returns (uint96) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return MarketFacet(ms.diamondAddress).getCommissionPercentage();
    }

    /**
     * @dev Set the Platform fee
     */

    function setCommissionPercentageMedia(uint96 _newCommissionPercentage) external returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        require(msg.sender == MarketFacet(ms.diamondAddress).getAdminAddress(), "Media: Only Admin Can Set Commission Percentage!");
        require(_newCommissionPercentage > 0, "Media: Invalid Commission Percentage");
        require(_newCommissionPercentage <= 500, "Media: Commission Percentage Must Be Less Than 5%!");

        MarketFacet(ms.diamondAddress).setCommissionPercentage(_newCommissionPercentage);
        return true;
    }

    /**
     * @dev Check if the token Id exists before minting the tokens
     */
    function istokenIdExistMedia(uint256 _tokenID, string memory _contractType) public view returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))) {
            return (ERC721FactoryFacet(ms.diamondAddress)._tokenExists(_tokenID));
        }
    }

    /**
     * @dev Burn token
     * @param amount copies of the token. 1 for ERC721.
     * @param _tokenID token id.
     * @param _contractType contract type
     */
    function burnTokenMedia(
        uint256 _tokenID,
        string memory _contractType,
        uint256 amount
    ) external {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))) {
            ERC721FactoryFacet(ms.diamondAddress).burn(_tokenID);
        }

        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155")))) {
            ERC1155FactoryFacet(ms.diamondAddress).burn(msg.sender, _tokenID, amount);
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
    ) public {
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
