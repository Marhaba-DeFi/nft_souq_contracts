// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library LibEIP712Storage {
    bytes32 constant EIP_712_STORAGE_POSITION = keccak256("diamond.standard.EIP712.storage");

    struct EIP712Storage {
        bytes32 _CACHED_DOMAIN_SEPARATOR;
        uint256 _CACHED_CHAIN_ID;
        address _CACHED_THIS;
        bytes32 _HASHED_NAME;
        bytes32 _HASHED_VERSION;
        bytes32 _TYPE_HASH;
    }

    function eip712torage() internal pure returns (EIP712Storage storage es) {
        bytes32 position = EIP_712_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
