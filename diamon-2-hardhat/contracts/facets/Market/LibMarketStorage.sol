// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library LibMarketStorage {
  bytes32 constant MARKET_STORAGE_POSITION = keccak256(
    "diamond.standard.market.storage"
  );

  struct Collaborators {
      address[] collaborators;
      uint96[] collabFraction;
  }

  struct MarketStorage {
    
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

  function marketStorage() internal pure returns (MarketStorage storage es) {
    bytes32 position = MARKET_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}