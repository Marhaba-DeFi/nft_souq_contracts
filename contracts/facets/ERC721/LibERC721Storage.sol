// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC721Storage {
  bytes32 constant ERC_721_STORAGE_POSITION = keccak256(
    "diamond.standard.ERC721.storage"
  );

  struct ERC721Storage {
   // Token name
    string _name;
    // Token symbol
    string _symbol;
    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;
    // Mapping owner address to token count
    mapping(address => uint256) _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
  }

  function erc721Storage() internal pure returns (ERC721Storage storage es) {
    bytes32 position = ERC_721_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}