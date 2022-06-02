// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC721FactoryStorage {
  bytes32 constant ERC_721_FACTORY_STORAGE_POSITION = keccak256(
    "diamond.standard.ERC721Factory.storage"
  );

  struct ERC721FactoryStorage {
    mapping(uint256 => address) nftToOwners;
    mapping(uint256 => address) nftToCreators;
    // Optional mapping for token URIs
    mapping (uint256 => string) _tokenURIs;
    string _name;
    string _symbol;
    // Base URI
    string _baseURI;
  }



  function erc721FactoryStorage() internal pure returns (ERC721FactoryStorage storage es) {
    bytes32 position = ERC_721_FACTORY_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}
