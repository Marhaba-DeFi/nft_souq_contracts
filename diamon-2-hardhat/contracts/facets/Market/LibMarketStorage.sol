// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

// import "../../interfaces/IMarket.sol";
// import "../../interfaces/Iutils.sol";

library LibMarketStorage {
  bytes32 constant MARKET_STORAGE_POSITION = keccak256(
    "diamond.standard.market.storage"
  );

  struct MarketStorage {
    //Counters.Counter _auctionIdTracker;

    mapping(address => bool) _approvedCurrency;

    //address _adminAddress;

    // To store commission percentage for each mint
    // uint8 _adminCommissionPercentage;

    // // tokenAddress - bidder - tokenID  = bidDetails
    // mapping(address => mapping(address => mapping(uint256 => Iutils.Bid))) _tokenBidders;

    // // tokenAddress - bidder - tokenID - tokenQuantity = askDetails
    // mapping(address => mapping(address => mapping(uint256 => Iutils.Ask))) _tokenAsks;

    // // tokenID => creator's Royalty Percentage
    // mapping(uint256 => uint8) _tokenRoyaltyPercentage;

    // // tokenID => { collaboratorsAddresses[] , percentages[] }
    // mapping(uint256 => IMarket.Collaborators) _tokenCollaborators;

    // mapping(address => bool) _approvedCurrency;

    // address[] public allApprovedCurrencies;

    // The minimum percentage difference between the last bid amount and the current bid.
    // uint8 _minBidIncrementPercentage;
    // uint256 _EXPO;
    // uint256 _BASE;
    // uint256 timeBuffer;


  }

  function marketStorage() internal pure returns (MarketStorage storage es) {
    bytes32 position = MARKET_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}