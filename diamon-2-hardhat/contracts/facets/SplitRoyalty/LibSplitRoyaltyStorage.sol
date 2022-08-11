// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC721FactoryStorage {
    bytes32 constant SPLIT_ROYALTY_STORAGE_POSITION = keccak256("diamond.standard.SplitRoyalty.storage");

	struct SplitRoyaltyStorage {
		struct RoyaltyInfo {
			address[] receiver;
			uint96[] royaltyFraction;
    	}
        mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;
    }

    function splitRoyaltyStorage() internal pure returns (SplitRoyaltyStorage storage es) {
        bytes32 position = SPLIT_ROYALTY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}