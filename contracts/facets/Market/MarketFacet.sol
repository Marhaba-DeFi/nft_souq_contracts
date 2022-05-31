// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IMarket.sol";
import "../../interfaces/Iutils.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";
import "./LibMarketStorage.sol";

contract MarketFacet is IMarket {
    AppStorage internal s;
    
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    function marketInit(
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();

        require(
            ms._EXPO == 0 &&
            ms._BASE == 0 &&
            ms.timeBuffer == 0 &&
            ms._minBidIncrementPercentage == 0,
            "ALREADY_INITIALIZED"
        );

        require(msg.sender == ds.contractOwner, "Must own the contract.");

        ms._minBidIncrementPercentage = 5;
        ms._EXPO = 1e18;
        ms._BASE = 100 * ms._EXPO;
        ms.timeBuffer = 15 * 60;
    }
    
    modifier onlyMediaCaller() {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        require(msg.sender == s._mediaContract, "Market: Unauthorized Access!");
        _;
    }

    /**
     * @notice This method is used to Set Media Contract's Address
     *
     * @param _mediaContractAddress Address of the Media Contract to set
     */
    function configureMedia(address _mediaContractAddress) external {
        LibDiamond.enforceIsContractOwner();
        require(
            _mediaContractAddress != address(0),
            "Market: Invalid Media Contract Address!"
        );
        
        require(
            s._mediaContract == address(0),
            "Market: Media Contract Already Configured!"
        );

        s._mediaContract = _mediaContractAddress;
        emit MediaUpdated(_mediaContractAddress);
    }

    /**
     * @dev See {IMarket}
     */
    function setCollaborators(
        uint256 _tokenID,
        Collaborators calldata _collaborators
    ) external override onlyMediaCaller {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        ms._tokenCollaborators[_tokenID] = _collaborators;
    }

    /**
     * @dev See {IMarket}
     */
    function setRoyaltyPoints(uint256 _tokenID, uint8 _royaltyPoints)
        external
        override
        onlyMediaCaller
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        ms._tokenRoyaltyPercentage[_tokenID] = _royaltyPoints;
        emit RoyaltyUpdated(_tokenID, _royaltyPoints);
    }

    /**
     * @dev See {IMarket}
     */
    function setBid(
        uint256 _tokenID,
        address _tokenAddress,
        address _owner, 
        address _bidder,
        Iutils.Bid calldata _bid,
        address _creator
    ) external payable override onlyMediaCaller returns (bool) {
        require(_bid._amount != 0, "Market: You Can't Bid With 0 Amount!");
        require(_bid._quantity != 0, "Market: You Can't Bid For 0 Tokens");
        require(
            !(_bid._quantity < 0),
            "Market: You Can't Bid For Negative Tokens"
        );
        
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();

        require(
            _bid._recipient != address(0),
            "Market: bid recipient cannot be 0 address"
        );
        
        require(
            ms._tokenAsks[_tokenAddress][_owner][_tokenID]._sender != address(0),
            "Market: Token is not open for Sale"
        );

        require(_bid._quantity <= ms._tokenAsks[_tokenAddress][_owner][_tokenID]._amount, "Market: Invalid quantity value supplied");

        require(_bid._currency == ms._tokenAsks[_tokenAddress][_owner][_tokenID]._currency, "Market: Invalid Currency Supplied for bid");

        // TODO: improve with some functional check OR multi require
        if ( ms._tokenAsks[_tokenAddress][_owner][_tokenID]._currency != address(0)){
        require(
            _bid._amount >= ms._tokenAsks[_tokenAddress][_owner][_tokenID]._reserveAmount,
            "Market: Bid Cannot be placed below the min Amount"
        );
        }else{
            require(msg.value >= ms._tokenAsks[_tokenAddress][_owner][_tokenID]._reserveAmount,
            "Market: Bid Cannot be placed below the min Amount"
        );
        }

        _verifyIncomingTransfer(_tokenID, _tokenAddress, _owner, _bid);

        if (ms._tokenAsks[_tokenAddress][_owner][_tokenID].askType == Iutils.AskTypes.FIXED) {
            require(
                _bid._amount <= ms._tokenAsks[_tokenAddress][_owner][_tokenID]._askAmount,
                "Market: You Cannot Pay more then Max Asked Amount "
            );
            _handleIncomingBid(
                _bid._amount,
                ms._tokenAsks[_tokenAddress][_owner][_tokenID]._currency,
                _bid._bidder
            );

            // Set New Bid for the Token
            ms._tokenBidders[_tokenAddress][_bid._bidder][_tokenID] = Iutils.Bid(
                _bid._tokenAddress,
                _bid._owner,
                _bid._quantity,
                _bid._amount,
                _bid._currency,
                _bid._bidder,
                _bid._recipient,
                _bid.askType
            );

            emit BidCreated(_tokenID, _bid);
            // Needs to be taken care of
            // // If a bid meets the criteria for an ask, automatically accept the bid.
            // // If no ask is set or the bid does not meet the requirements, ignore.
            if (
                _bid._amount >= ms._tokenAsks[_tokenAddress][_owner][_tokenID]._askAmount
            ) {
                ms._tokenAsks[_tokenAddress][_owner][_tokenID]._amount -= _bid._quantity;
                // Finalize Exchange
                divideMoney(_tokenID, _tokenAddress, ms._tokenAsks[_tokenAddress][_owner][_tokenID]._currency, _owner, _bidder, _bid._amount, _creator);
            }
            return true;
        } else {
            return _handleAuction(_tokenID, _tokenAddress, _owner, _creator, _bid);
        }
    }

    function _verifyIncomingTransfer(uint256 _tokenID, address _tokenAddress ,address _owner, Iutils.Bid calldata _bid) internal {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();

        if (_bid._currency == address(0)) {
            require(msg.value >= _bid._amount, "Market: bid amount is less than expected amount");
        } else {
            IERC20 token = IERC20(ms._tokenAsks[_tokenAddress][_owner][_tokenID]._currency);
            // fetch existing bid, if there is any
            require(
                token.allowance(_bid._bidder, address(this)) >= _bid._amount,
                "Market: Please Approve Tokens Before You Bid"
            );
        }
    }

    function _handleAuction(uint256 _tokenID, address _tokenAddress ,address _owner, address _creator, Iutils.Bid calldata _bid)
        internal
    returns (bool){
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        // Manage if the Bid is of Auction Type

        Iutils.Ask storage askInfo = ms._tokenAsks[_tokenAddress][_owner][_tokenID];
        address lastBidder = askInfo._bidder;

        require(
            askInfo._firstBidTime == 0 ||
                block.timestamp <
                askInfo._firstBidTime +
                askInfo._duration,
            "Market: Auction expired"
        );

        require(
            _bid._amount >=
                askInfo._highestBid +
                    (askInfo._highestBid *
                        (ms._minBidIncrementPercentage * ms._EXPO)) /
                    (ms._BASE),
            "Market: Must send more than last bid by _minBidIncrementPercentage amount"
        );
        if (askInfo._firstBidTime == 0) {
            // If this is the first valid bid, we should set the starting time now.
            askInfo._firstBidTime = block.timestamp;
            // Set New Bid for the Token
        } else if (lastBidder != address(0)) {
            // If it's not, then we should refund the last bid amount
            uint256 bidAmountToReturn = ms._tokenBidders[_tokenAddress][lastBidder][_tokenID]._amount;
            delete ms._tokenBidders[_tokenAddress][lastBidder][_tokenID];

            // return bid to outbidder either its native or erc20
            transferNativeOrErc20(askInfo._currency, lastBidder, bidAmountToReturn);

        }
        askInfo._highestBid = _bid._amount;
        askInfo._bidder = _bid._bidder;
        _handleIncomingBid(
            _bid._amount,
            askInfo._currency,
            _bid._bidder
        );

        // create new Bid
        ms._tokenBidders[_tokenAddress][_bid._bidder][_tokenID] = Iutils.Bid(
            _bid._tokenAddress,
            _bid._owner,
            _bid._quantity,
            _bid._amount,
            _bid._currency,
            _bid._bidder,
            _bid._recipient,
            _bid.askType
        );

        emit BidCreated(_tokenID, _bid);

        // if the bid amount is >= askAmount accept the bid and close the auction
        // Note: askAmount is the maximum amount seller wanted to accept against its NFT

        if ( _bid._amount >= askInfo._askAmount ){

        address newOwner = askInfo._bidder;

        divideMoney(
            _tokenID,
            _tokenAddress,
            askInfo._currency,
            _owner,
            lastBidder,
            askInfo._highestBid,
            _creator
        );
        emit BidAccepted(_tokenID, newOwner);
        return true;
        }
        return false;
    }
    function _handleIncomingBid(
        uint256 _amount,
        address _currency,
        address _bidder
    ) internal {
        // We must check the balance that was actually transferred to the auction,
        // as some tokens impose a transfer fee and would not actually transfer the
        // full amount to the market, resulting in potentially locked funds
        if (_currency != address(0)){
        IERC20 token = IERC20(_currency);
        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(_bidder, address(this), _amount);
        uint256 afterBalance = token.balanceOf(address(this));
        require(
            beforeBalance + _amount == afterBalance,
            "Token transfer call did not transfer expected amount"
        );
        }
    }

    // /**
    //  * @notice Sets the ask on a particular media. If the ask cannot be evenly split into the media's
    //  * bid shares, this reverts.
    //  */
    function _setAsk(uint256 _tokenID, address _tokenAddress, address _owner, Iutils.Ask memory ask)
        public
        override
        onlyMediaCaller
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        Iutils.Ask storage _oldAsk = ms._tokenAsks[_tokenAddress][_owner][_tokenID];
        // make sure, currency is the one enable in contract

        if (ask._currency != address(0) )
        require( this.isTokenApproved(ask._currency), "Market: Token Not Approved");

        if (_oldAsk._sender != address(0)) {
            if (ask.askType == Iutils.AskTypes.AUCTION) {
                require(
                    _oldAsk._firstBidTime == 0,
                    "Market: Auction Started, Nothing can be modified"
                );
                require(
                    ask._reserveAmount < ask._askAmount,
                    "Market reserve amount error"
                );
            } else {
                require(
                    ask._reserveAmount == ask._askAmount,
                    "Amount observe and Asked Need to be same for Fixed Sale"
                );
            }

            require(
                _oldAsk._sender == ask._sender,
                "Market: sender should be token owner"
            );
            require(
                _oldAsk._firstBidTime == ask._firstBidTime,
                "Market: cannot change first bid time"
            );
            require(
                _oldAsk._bidder == ask._bidder,
                "Market: cannot change bidder"
            );
            require(
                _oldAsk._highestBid == ask._highestBid,
                "Market: cannot change highest bid"
            );

            Iutils.Ask memory _updatedAsk = Iutils.Ask(
                _oldAsk._tokenAddress,
                _oldAsk._sender,
                ask._reserveAmount,
                ask._askAmount,
                ask._amount,
                ask._currency,
                ask.askType,
                ask._duration,
                _oldAsk._firstBidTime,
                _oldAsk._bidder,
                _oldAsk._highestBid,
                block.timestamp
            );
            ms._tokenAsks[_tokenAddress][_owner][_tokenID] = _updatedAsk;
            emit AskUpdated(_tokenID, _updatedAsk);
        } else {

            // set bidder, firstBidTime and highest bid to default state
            ask._bidder = address(0);
            ask._firstBidTime = 0;
            ask._highestBid = 0;

            ms._tokenAsks[_tokenAddress][_owner][_tokenID] = ask;
            ms._tokenAsks[_tokenAddress][_owner][_tokenID]._createdAt = block.timestamp;
            emit AskUpdated(_tokenID, ask);
        }
    }

    function removeBid(uint256 _tokenID, address _tokenAddress, address _bidder)
        public
        override
        onlyMediaCaller
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        Iutils.Bid storage bid = ms._tokenBidders[_tokenAddress][_bidder][_tokenID];
        uint256 bidAmount = bid._amount;
        address bidCurrency = bid._currency;

        require(
            bid._bidder == _bidder,
            "Market: Only bidder can remove the bid"
        );
        require(bid._amount > 0, "Market: cannot remove bid amount of 0");
        transferNativeOrErc20(bidCurrency, bid._bidder, bidAmount);
        emit BidRemoved(_tokenID, bid);
        // line safeTransfer should be upper before delete??
        delete ms._tokenBidders[_tokenAddress][_bidder][_tokenID];
    }

    /**
     * @dev See {IMarket}
     */
    function _setAdminAddress(address _newAdminAddress)
        external
        override
        onlyMediaCaller
        returns (bool)
    {
        require(
            _newAdminAddress != address(0),
            "Market: Invalid Admin Address!"
        );

        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        
        require(
            ms._adminAddress == address(0),
            "Market: Admin Already Configured!"
        );

        ms._adminAddress = _newAdminAddress;
        emit AdminUpdated(ms._adminAddress);
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function _addCurrency(address _tokenAddress)
        external
        override
        onlyMediaCaller
        returns (bool)
    {
        require(_tokenAddress != address(0), "Market: Invalid Token Address!");
        require(
            !this.isTokenApproved(_tokenAddress),
            "Market: Token Already Configured!"
        );

        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();

        ms._approvedCurrency[_tokenAddress] = true;
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function _removeCurrency(address _tokenAddress)
        external
        override
        onlyMediaCaller
        returns (bool)
    {
        require(_tokenAddress != address(0), "Market: Invalid Token Address!");
        require(
            this.isTokenApproved(_tokenAddress),
            "Market: Token not found!"
        );

        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();

        ms._approvedCurrency[_tokenAddress] = false;
        return true;
    }

    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        if (ms._approvedCurrency[_tokenAddress] == true) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev See {IMarket}
     */
    function getAdminAddress()
        external
        view
        override
        onlyMediaCaller
        returns (address)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        return ms._adminAddress;
    }

    /**
     * @dev See {IMarket}
     */
    function _setCommissionPercentage(uint8 _commissionPercentage)
        external
        override
        onlyMediaCaller
        returns (bool)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        ms._adminCommissionPercentage = _commissionPercentage;
        emit CommissionUpdated(ms._adminCommissionPercentage);
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function _setMinimumBidIncrementPercentage(uint8 __minBidIncrementPercentage)
        external
        override
        onlyMediaCaller
        returns (bool)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        ms._minBidIncrementPercentage = __minBidIncrementPercentage;
        emit BidIncrementPercentageUpdated(ms._minBidIncrementPercentage);
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function getCommissionPercentage()
        external
        view
        override
        onlyMediaCaller
        returns (uint8)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        return ms._adminCommissionPercentage;
    }

    function endAuction(
        uint256 _tokenID,
        address _tokenAddress,
        address _owner,
        address _creator
    ) external override onlyMediaCaller returns (bool) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        require(
            uint256(ms._tokenAsks[_tokenAddress][_owner][_tokenID]._firstBidTime) != 0,
            "Market: Auction hasn't begun"
        );
        require(
            block.timestamp >=
                (ms._tokenAsks[_tokenAddress][_owner][_tokenID]._firstBidTime - ms._tokenAsks[_tokenAddress][_owner][_tokenID]._createdAt)
                    + ms._tokenAsks[_tokenAddress][_owner][_tokenID]._duration,
            "Market: Auction hasn't completed"
        );
        address bidder = ms._tokenAsks[_tokenAddress][_owner][_tokenID]._bidder;

        Iutils.Bid memory bidInfo = ms._tokenBidders[_tokenAddress][bidder][_tokenID];

        ms._tokenAsks[_tokenAddress][_owner][_tokenID]._amount -= bidInfo._quantity;

        // address(0) for _bidder is only need when sale type is of type Auction
        divideMoney(
            _tokenID,
            _tokenAddress,
            ms._tokenAsks[_tokenAddress][_owner][_tokenID]._currency,
            _owner,
            bidder,
            bidInfo._amount,
            _creator
        );
        emit BidAccepted(_tokenID, bidder);
        return true;
    }

    function acceptBid(
        uint256 _tokenID,
        address _tokenAddress,
        address _owner,
        address _creator
    ) external override onlyMediaCaller returns (bool) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        address bidder = ms._tokenAsks[_tokenAddress][_owner][_tokenID]._bidder;

        // retrieve bid info
        Iutils.Bid memory bidInfo = ms._tokenBidders[_tokenAddress][bidder][_tokenID];
        require(
            uint256(ms._tokenAsks[_tokenAddress][_owner][_tokenID]._firstBidTime) != 0,
            "Market.Auction hasn't begun"
        );
        require(uint256(ms._tokenAsks[_tokenAddress][_owner][_tokenID]._highestBid) != 0, "No Bid Found");
        require(address(bidInfo._bidder) != address(0), "Media: No Bid Found against token ask");

        ms._tokenAsks[_tokenAddress][_owner][_tokenID]._amount -= bidInfo._quantity;
        
        // address(0) for _bidder is only need when sale type is of type Auction
        divideMoney(
            _tokenID,
            _tokenAddress,
            ms._tokenAsks[_tokenAddress][_owner][_tokenID]._currency,
            _owner,
            bidInfo._bidder,
            bidInfo._amount, // make sure to pass amount from bid so that we avoid manupulation by asker
            _creator
        );
        emit BidAccepted(_tokenID, bidder);
        return true;
    }

    /**
     * @notice Cancel an auction.
     * @dev Transfers the NFT back to the auction creator and emits an AuctionCanceled event
     */
    function _cancelAuction(uint256 _tokenID, address _tokenAddress, address _owner) external override onlyMediaCaller {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        require(
            uint256(ms._tokenAsks[_tokenAddress][_owner][_tokenID]._firstBidTime) == 0,
            "Can't cancel an auction once it's begun"
        );
        delete ms._tokenAsks[_tokenAddress][_owner][_tokenID];
        emit AuctionCancelled(_tokenID);
    }

    /**
     * @dev See {IMarket}
     */
    function divideMoney(
        uint256 _tokenID,
        address _tokenAddress,
        address _currency,
        address _owner,
        address _bidder,
        uint256 _amountToDistribute,
        address _creator
    ) internal returns (bool) {
        require(
            _amountToDistribute > 0,
            "Market: Amount To Divide Can't Be 0!"
        );

        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        
        // first send admin cut
        uint256 adminCommission = (_amountToDistribute *
            (ms._adminCommissionPercentage * ms._EXPO)) / (ms._BASE);
        uint256 _amount = _amountToDistribute - adminCommission;

        transferNativeOrErc20(_currency, ms._adminAddress, adminCommission);
        // fetch owners added royalty points
        uint256 collabPercentage = ms._tokenRoyaltyPercentage[_tokenID];
        uint256 royaltyPoints = (_amount * (collabPercentage * ms._EXPO)) / (ms._BASE);

        // royaltyPoints represents amount going to divide among Collaborators
        transferNativeOrErc20(_currency, _owner, _amount - royaltyPoints);

        // Collaborators will only receive share when creator have set some royalty and sale is occurring for the first time
        Collaborators storage tokenCollab = ms._tokenCollaborators[_tokenID];
        uint256 totalAmountTransferred = 0;

        if (tokenCollab._receiveCollabShare == false) {
            for (
                uint256 index = 0;
                index < tokenCollab._collaborators.length;
                index++
            ) {
                // Individual Collaborator's share Amount

                uint256 amountToTransfer = (royaltyPoints *
                    (tokenCollab._percentages[index] * ms._EXPO)) / (ms._BASE);
                // transfer Individual Collaborator's share Amount
                transferNativeOrErc20(_currency, tokenCollab._collaborators[index], amountToTransfer);

                // Total Amount Transferred
                totalAmountTransferred =
                    totalAmountTransferred +
                    amountToTransfer;
            }
            // after transferring to collabs, remaining would be sent to creator
            // update collaborators got the shares
            tokenCollab._receiveCollabShare = true;
        }
        transferNativeOrErc20(_currency, _creator, royaltyPoints - totalAmountTransferred);

        totalAmountTransferred =
            totalAmountTransferred +
            (royaltyPoints - (totalAmountTransferred));

        totalAmountTransferred =
            totalAmountTransferred +
            (_amount - (royaltyPoints));
        // Check for Transfer amount error
        require(
            totalAmountTransferred == _amount,
            "Market: Amount Transfer Value Error!"
        );

        deleteBidderAndAsks(_tokenID, _tokenAddress, _bidder, _owner);

        return true;
    }

    function deleteBidderAndAsks(uint256 _tokenID, address _tokenAddress, address _bidder, address _owner) internal {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();

        delete ms._tokenBidders[_tokenAddress][_bidder][_tokenID];
        if (ms._tokenAsks[_tokenAddress][_owner][_tokenID]._amount == 0) {
        delete ms._tokenAsks[_tokenAddress][_owner][_tokenID];
        }
    }

    function _getTokenAsks(uint256 _tokenId, address _tokenAddress, address _owner)
        external
        view
        override
        returns (Iutils.Ask memory)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        return ms._tokenAsks[_tokenAddress][_owner][_tokenId];
    }

    function _getTokenBid(uint256 _tokenId, address _tokenAddress, address _owner)
        external
        view
        override
        returns (Iutils.Bid memory)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage.marketStorage();
        address bidder = ms._tokenAsks[_tokenAddress][_owner][_tokenId]._bidder;
        return ms._tokenBidders[_tokenAddress][bidder][_tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
    
        returns (bool)
    {
        return s._operatorApprovals[owner][operator];
    }

    function transferNativeOrErc20(address _currency, address _receiver, uint256 _amount) internal{
        require(_receiver != address(0), "Market: receipent is zero address");
        if ( _currency == address(0)){
            (bool success, ) = _receiver.call{value: _amount}("");
            require(success, "Address: unable to transfer native tokens, recipient may have reverted");
        }else{
            IERC20 token = IERC20(_currency);
            token.transfer(_receiver, _amount);
        }
    }
}
