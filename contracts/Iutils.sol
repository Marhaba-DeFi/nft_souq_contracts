// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Iutils {
    enum AskTypes {
        AUCTION,
        FIXED
    }
    struct Bid {
        // Amount of the currency being bid
        uint256 _bidAmount;
        // Amount of the tokens being bid
        uint256 _amount;
        // Address to the ERC20 token being used to bid
        address _currency;
        // Address of the bidder
        address _bidder;
        // Address of the recipient
        address _recipient;
    }
    struct Ask {
        uint256 _reserveAmount;
        // Amount of the currency being asked
        uint256 _askAmount;
        // Amount of the tokens being asked
        uint256 _amount;
        // Address to the ERC20 token being asked
        address _currency;
        // Type of ask
        AskTypes askType;
    }
}
