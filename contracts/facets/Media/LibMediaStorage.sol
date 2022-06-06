// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMedia} from "../../interfaces/IMedia.sol";

library LibMediaStorage {
  bytes32 constant MEDIA_STORAGE_POSITION = keccak256(
    "diamond.standard.media.storage"
  );

  struct MediaStorage {
    address diamondAddress;
    
    uint256 _tokenCounter;

    // TokenHash => tokenID
    mapping(bytes32 => uint256) _tokenHashToTokenID;

    // tokenAddress - owner - tokenID
    mapping(address => mapping(address => mapping(uint256 => address))) nftToOwners;

    // tokenAddress - owner - tokenID - tokenQuantity
    mapping(address => mapping(uint256 => address)) nftToCreators;

    // tokenAddress - owner - tokenID - tokenQuantity = MediaInfo
    mapping(address => mapping(address => mapping(uint256 => IMedia.MediaInfo))) tokenIDToToken;
  }

  function mediaStorage() internal pure returns (MediaStorage storage es) {
    bytes32 position = MEDIA_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}
