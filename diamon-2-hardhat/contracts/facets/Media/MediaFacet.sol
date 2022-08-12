// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../ERC1155Factory/ERC1155FactoryFacet.sol";
import "../ERC721Factory/ERC721FactoryFacet.sol";
import "./LibMediaStorage.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../EIP712/EIP712Facet.sol";

contract MediaFacet {

    function mediaInit(
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
    }

    function mintToken(
        address _to,
        uint256 _id,
        string memory _contractType,
        address _tokenContract,
        uint256 _copies,
        string memory _uri,
        address _royaltyReceiver,
        uint96 _tokenRoyaltyInBips
    ) external returns (uint256)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        bool _isFungible = keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155"))) ? true : false;

        // if token supply is 1 means we need to mint ERC 721 otherwise ERC 1155
        if (_isFungible) {
            ERC1155FactoryFacet(ms.diamondAddress).mint(
                _to,
				_uri,
                _id,
                _copies,
                _royaltyReceiver,
                _tokenRoyaltyInBips
                
            );
        } else {
            SouqERC721(_tokenContract).safeMint(
                _to, 
                _uri, 
                _id,
                _royaltyReceiver,
                _tokenRoyaltyInBips
            );
        }

        return _id;
    }



}