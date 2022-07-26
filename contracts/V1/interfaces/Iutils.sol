// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Iutils {
    enum AskTypes {
        AUCTION,
        FIXED
    }
    struct Bid {
        // Token Address on which user is putting bid
        address _tokenAddress;
        // Token Owner against user is putting bid
        address _owner;
        // quantity of the tokens being bid
        uint256 _quantity;
        // amount of ERC20 token being used to bid
        uint256 _bidPrice;
        // Address to the ERC20 token being used to bid
        address _currency;
        // Address of the bidder
        address _bidder;
        // Address of the recipient
        address _recipient;
        // Type of ask
        AskTypes askType;
    }
    struct Ask {
         // Token Address which user is putting on sale
        address _tokenAddress;
        //this is to check in Ask function if _sender is the token Owner
        address _sender;
        // min amount Asked
        uint256 _reservePrice;
        // max amount to buy at now
        uint256 _buyNowPrice;
        // quantity of the tokens being asked
        uint256 _askQuantity;
        // Address to the ERC20 token being asked
        address _currency;
        // Type of ask
        AskTypes askType;
        // following attribute used for managing auction ask
        // The length of time to run the auction for, after the first bid was made
        uint256 _duration;
        // The time of the first bid
        uint256 _firstBidTime;
        // The address of the current highest bidder
        address _bidder;
        // The current highest bid amount
        uint256 _highestBid;
        // created time
        uint256 _createdAt;
    }
}
