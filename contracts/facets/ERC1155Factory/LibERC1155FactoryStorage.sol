// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC1155FactoryStorage {
    bytes32 constant ERC_1155_FACTORY_STORAGE_POSITION = keccak256("diamond.standard.ERC1155Factory.storage");

    struct RoyaltyInfo {
        address[] receiver;
        uint96[] royaltyFraction;
    }

    struct ERC1155FactoryStorage {
        // tokenId => Owner
        mapping(uint256 => address) nftToOwners;
        // tokenID => Creator
        mapping(uint256 => address) nftToCreators;
        // token name
        string name;
        // token symbol
        string symbol;
        // Optional mapping for token URIs
        mapping(uint256 => string) _tokenURIs;
        // Base URI
        string _baseURI;
        mapping(uint256 => RoyaltyInfo) _tokenRoyaltyInfo;
    }

    function erc1155FactoryStorage() internal pure returns (ERC1155FactoryStorage storage es) {
        bytes32 position = ERC_1155_FACTORY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}