// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMedia} from "../../interfaces/IMedia.sol";

library LibMediaStorage {
  bytes32 constant MEDIA_STORAGE_POSITION = keccak256(
    "diamond.standard.media.storage"
  );

  struct MediaStorage {
    address _ERC1155Address;
    address _marketAddress;
    address _ERC721Address;

    uint256 _tokenCounter;

    // TokenHash => tokenID
    mapping(bytes32 => uint256) _tokenHashToTokenID;

    // tokenID => Owner
    mapping(uint256 => address) nftToOwners;

    // tokenID => Creator
    mapping(uint256 => address) nftToCreators;

    // tokenID => Token
    mapping(uint256 => IMedia.MediaInfo) tokenIDToToken;
  }

  function mediaStorage() internal pure returns (MediaStorage storage es) {
    bytes32 position = MEDIA_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}
