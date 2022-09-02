// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library LibMediaStorage {
  bytes32 constant MEDIA_STORAGE_POSITION = keccak256(
    "diamond.standard.media.storage"
  );

  struct Collaborators {
      address[] collaborators;
      uint96[] collabFraction;
  }

  struct MediaStorage {

    address diamondAddress;
    
    // Crypto Currency address => allowed or not as a payment method
    mapping(address => bool) _approvedCurrency;

    // To store commission percentage for each mint
    uint96 _adminCommissionPercentage;

    // nftContract => tokenID => { collaboratorsAddresses[] , percentages[] }
    mapping(address => mapping(uint256 => Collaborators)) tokenCollaborators;

    address _adminAddress;

    // tokenID => creator's Royalty Percentage
    // mapping(uint256 => uint8) _tokenRoyaltyPercentage;

    // address[] public allApprovedCurrencies;
  }

  function mediaStorage() internal pure returns (MediaStorage storage es) {
    bytes32 position = MEDIA_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}