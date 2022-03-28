// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import "../../interfaces/IMarket.sol";
import "../../interfaces/Iutils.sol";

library LibMarketStorage {
  bytes32 constant MARKET_STORAGE_POSITION = keccak256(
    "diamond.standard.market.storage"
  );

  struct MarketStorage {
    Counters.Counter _auctionIdTracker;

    address _adminAddress;

    // To store commission percentage for each mint
    uint8 _adminCommissionPercentage;

    // Mapping from token to mapping from bidder to bid
    mapping(uint256 => mapping(address => Iutils.Bid)) _tokenBidders;

    // Mapping from token to the current ask for the token
    mapping(uint256 => Iutils.Ask) _tokenAsks;

    // tokenID => creator's Royalty Percentage
    mapping(uint256 => uint8) tokenRoyaltyPercentage;

    // tokenID => { collaboratorsAddresses[] , percentages[] }
    mapping(uint256 => IMarket.Collaborators) tokenCollaborators;

    mapping(address => bool) approvedCurrency;

    // address[] public allApprovedCurrencies;

    // The minimum percentage difference between the last bid amount and the current bid.
    uint8 minBidIncrementPercentage;
    uint256 EXPO;
    uint256 BASE;
    uint256 timeBuffer;
  }

  function marketStorage() internal pure returns (MarketStorage storage es) {
    bytes32 position = MARKET_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}
