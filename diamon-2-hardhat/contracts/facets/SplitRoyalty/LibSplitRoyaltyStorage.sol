// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISplitRoyalty} from "../../interfaces/ISplitRoyalty.sol";
 
library LibSplitRoyaltyStorage {
    bytes32 constant SPLIT_ROYALTY_STORAGE_POSITION = keccak256("diamond.standard.SplitRoyalty.storage");

	struct SplitRoyaltyStorage {
		ISplitRoyalty.RoyaltyInfo _defaultRoyaltyInfo;
        mapping(uint256 => ISplitRoyalty.RoyaltyInfo) _tokenRoyaltyInfo;
    }

    function splitRoyaltyStorage() internal pure returns (SplitRoyaltyStorage storage es) {
        bytes32 position = SPLIT_ROYALTY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}