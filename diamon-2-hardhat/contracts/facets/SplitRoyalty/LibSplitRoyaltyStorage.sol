// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
library LibSplitRoyaltyStorage {
    bytes32 constant SPLIT_ROYALTY_STORAGE_POSITION = keccak256("diamond.standard.SplitRoyalty.storage");

    struct RoyaltyInfo {
        address[] receiver;
        uint96[] royaltyFraction;
    }
    struct SplitRoyaltyStorage {        
        RoyaltyInfo _defaultRoyaltyInfo;
        mapping(uint256 => RoyaltyInfo) _tokenRoyaltyInfo;
    }

    function splitRoyaltyStorage() internal pure returns (SplitRoyaltyStorage storage es) {
        bytes32 position = SPLIT_ROYALTY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
} 
