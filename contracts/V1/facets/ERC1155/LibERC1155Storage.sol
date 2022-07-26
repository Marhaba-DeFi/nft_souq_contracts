// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC1155Storage {
  bytes32 constant ERC_1155_STORAGE_POSITION = keccak256(
    "diamond.standard.ERC1155.storage"
  );

  struct ERC1155Storage {
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) _balances;
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string _uri;
  }

  function erc1155Storage() internal pure returns (ERC1155Storage storage es) {
    bytes32 position = ERC_1155_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}
