// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IMarket.sol';
import './interfaces/Iutils.sol';

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Counters} from '@openzeppelin/contracts/utils/Counters.sol';

contract Market is IMarket {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _auctionIdTracker;

    address private _mediaContract;
    address private _adminAddress;

    // To store commission amount of admin
    uint256 private _adminPoints;
    // To storre commission percentage for each mint
    uint8 private _adminCommissionPercentage;

    // tokenID => (bidderAddress => BidAmount)
    mapping(uint256 => mapping(address => uint256)) private tokenBids;

    // Mapping from token to mapping from bidder to bid
    mapping(uint256 => mapping(address => Iutils.Bid)) private _tokenBidders;

    // Mapping from token to the current ask for the token
    mapping(uint256 => Iutils.Ask) private _tokenAsks;

    // userAddress => its Redeem points
    mapping(address => uint256) private userRedeemPoints;

    // tokenID => List of Transactions
    mapping(uint256 => string[]) private tokenTransactionHistory;

    // tokenID => creator's Royalty Percentage
    mapping(uint256 => uint8) private tokenRoyaltyPercentage;

    // tokenID => { collaboratorsAddresses[] , percentages[] }
    mapping(uint256 => Collaborators) private tokenCollaborators;

    // tokenID => all Bidders
    mapping(uint256 => address[]) private tokenBidders;

    // The minimum percentage difference between the last bid amount and the current bid.
    uint8 public minBidIncrementPercentage = 5;

    modifier onlyMediaCaller() {
        require(msg.sender == _mediaContract, 'Market: Unauthorized Access!');
        _;
    }

    uint256 constant EXPO = 1e18;

    uint256 constant BASE = 100 * EXPO;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer = 15 * 60; // extend 15 minutes after every bid made in last 15 minutes

    // New Code -----------

    struct NewBid {
        uint256 _amount;
        uint256 _bidAmount;
    }

    // tokenID => owner => bidder => Bid Struct
    mapping(uint256 => mapping(address => mapping(address => NewBid))) private _newTokenBids;

    // tokenID => owner => all bidders
    mapping(uint256 => mapping(address => address[])) private newTokenBidders;

    /**
     * @notice This method is used to Set Media Contract's Address
     *
     * @param _mediaContractAddress Address of the Media Contract to set
     */
    function configureMedia(address _mediaContractAddress) external {
        // TODO: Only Owner Modifier
        require(_mediaContractAddress != address(0), 'Market: Invalid Media Contract Address!');
        require(_mediaContract == address(0), 'Market: Media Contract Alredy Configured!');

        _mediaContract = _mediaContractAddress;
    }

    /**
     * @dev See {IMarket}
     */
    function setCollaborators(uint256 _tokenID, Collaborators calldata _collaborators)
        external
        override
        onlyMediaCaller
    {
        tokenCollaborators[_tokenID] = _collaborators;
    }

    /**
     * @dev See {IMarket}
     */
    function setRoyaltyPoints(uint256 _tokenID, uint8 _royaltyPoints) external override onlyMediaCaller {
        tokenRoyaltyPercentage[_tokenID] = _royaltyPoints;
    }

    /**
     * @dev See {IMarket}
     */
    function setBid(
        uint256 _tokenID,
        address _bidder,
        Iutils.Bid calldata _bid,
        address _owner,
        address _creator
    ) external override onlyMediaCaller returns (bool) {
        require(_bid._amount != 0, "Market: You Can't Bid With 0 Amount!");
        require(_bid._bidAmount != 0, "Market: You Can't Bid For 0 Tokens");
        require(!(_bid._bidAmount < 0), "Market: You Can't Bid For Negative Tokens");
        require(_bid._currency != address(0), 'Market: bid currency cannot be 0 address');
        require(_bid._recipient != address(0), 'Market: bid recipient cannot be 0 address');
        require(_tokenAsks[_tokenID]._currency != address(0), 'Market: Token is not open for Sale');
        require(
            _bid._amount >= _tokenAsks[_tokenID]._reserveAmount,
            'Market: Bid Cannot be placed below the min Amount'
        );
        require(_bid._currency == _tokenAsks[_tokenID]._currency, 'Market: Incorrect payment Method');

        IERC20 token = IERC20(_tokenAsks[_tokenID]._currency);

        // fetch existing bid, if there is any
        require(
            token.allowance(_bid._bidder, address(this)) >= _bid._amount,
            'Market: Please Approve Tokens Before You Bid'
        );
        Iutils.Bid storage existingBid = _tokenBidders[_tokenID][_bidder];

        if (_tokenAsks[_tokenID].askType == Iutils.AskTypes.FIXED) {
            require(
                _bid._amount <= _tokenAsks[_tokenID]._askAmount,
                'Market: You Cannot Pay more then Max Asked Amount '
            );
            // If there is an existing bid, refund it before continuing
            if (existingBid._amount > 0) {
                removeBid(_tokenID, _bid._bidder);
            }
            _handleIncomingBid(_bid._amount, _tokenAsks[_tokenID]._currency, _bid._bidder);

            // Set New Bid for the Token
            _tokenBidders[_tokenID][_bid._bidder] = Iutils.Bid(
                _bid._bidAmount,
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
                _tokenAsks[_tokenID]._currency != address(0) &&
                _bid._currency == _tokenAsks[_tokenID]._currency &&
                _bid._amount >= _tokenAsks[_tokenID]._askAmount
            ) {
                // Finalize Exchange
                divideMoney(_tokenID, _owner, _bidder, _bid._amount, _creator);
            }
        } else {
            _handleAuction(_tokenID, _bid);
        }
        return true;
    }

    function _handleAuction(uint256 _tokenID, Iutils.Bid calldata _bid) internal {
        IERC20 token = IERC20(_tokenAsks[_tokenID]._currency);

        // fetch existing bid, if there is any
        require(
            token.allowance(_bid._bidder, address(this)) >= _bid._amount,
            'Market: Please Approve Tokens Before You Bid'
        );
        // Manage if the Bid is of Auction Type
        address lastBidder = _tokenAsks[_tokenID]._bidder;
        require(
            _tokenAsks[_tokenID]._firstBidTime == 0 ||
                block.timestamp < _tokenAsks[_tokenID]._firstBidTime.add(_tokenAsks[_tokenID]._duration),
            'Market: Auction expired'
        );

        require(
            _bid._amount >=
                _tokenAsks[_tokenID]._highestBid.add(
                    _tokenAsks[_tokenID]._highestBid.mul(minBidIncrementPercentage * BASE).div(100)
                ),
            'Market: Must send more than last bid by minBidIncrementPercentage amount'
        );
        if (_tokenAsks[_tokenID]._firstBidTime == 0) {
            // If this is the first valid bid, we should set the starting time now.
            _tokenAsks[_tokenID]._firstBidTime = block.timestamp;
            // Set New Bid for the Token
        } else if (lastBidder != address(0)) {
            // If it's not, then we should refund the last bidder
            delete _tokenBidders[_tokenID][lastBidder];
            token.safeTransfer(lastBidder, _tokenAsks[_tokenID]._highestBid);
            _tokenAsks[_tokenID]._highestBid = _bid._amount;
            _tokenAsks[_tokenID]._bidder = _bid._bidder;
        }
        _handleIncomingBid(_bid._amount, _tokenAsks[_tokenID]._currency, _bid._bidder);

        // create new Bid
        _tokenBidders[_tokenID][_bid._bidder] = Iutils.Bid(
            _bid._bidAmount,
            _bid._amount,
            _bid._currency,
            _bid._bidder,
            _bid._recipient,
            _bid.askType
        );

        emit BidCreated(_tokenID, _bid);

        bool extended = false;

        // at this point we know that the timestamp is less than start + duration (since the auction would be over, otherwise)
        // we want to know by how much the timestamp is less than start + duration
        // if the difference is less than the timeBuffer, increase the duration by the timeBuffer
        uint256 auctionDuration = _tokenAsks[_tokenID]._firstBidTime.add(_tokenAsks[_tokenID]._duration);
        if (auctionDuration.sub(block.timestamp) < timeBuffer) {
            uint256 oldDuration = _tokenAsks[_tokenID]._duration;
            uint256 _firstBidTime = _tokenAsks[_tokenID]._firstBidTime;
            _tokenAsks[_tokenID]._duration = oldDuration.add(
                timeBuffer.sub(_firstBidTime.add(oldDuration).sub(block.timestamp))
            );
            extended = true;
        }
    }

    function _handleIncomingBid(
        uint256 _amount,
        address _currency,
        address _bidder
    ) internal {
        // We must check the balance that was actually transferred to the auction,
        // as some tokens impose a transfer fee and would not actually transfer the
        // full amount to the market, resulting in potentally locked funds
        IERC20 token = IERC20(_currency);
        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(_bidder, address(this), _amount);
        uint256 afterBalance = token.balanceOf(address(this));
        require(beforeBalance.add(_amount) == afterBalance, 'Token transfer call did not transfer expected amount');
    }

    // /**
    //  * @notice Sets the ask on a particular media. If the ask cannot be evenly split into the media's
    //  * bid shares, this reverts.
    //  */
    function setAsk(uint256 _tokenID, Iutils.Ask memory ask) public override onlyMediaCaller {
        if (ask.askType == Iutils.AskTypes.FIXED) {
            require(ask._reserveAmount == ask._askAmount, 'Amount observe and Asked Need to be same for Fixed Sale');
        }

        _tokenAsks[_tokenID] = ask;
        emit AskCreated(_tokenID, ask);
    }

    function removeBid(uint256 _tokenID, address _bidder) public override onlyMediaCaller {
        Iutils.Bid storage bid = _tokenBidders[_tokenID][_bidder];
        uint256 bidAmount = bid._amount;
        address bidCurrency = bid._currency;

        require(bid._bidder == _bidder, 'Market: Only bidder can remove the bid');
        require(bid._amount > 0, 'Market: cannot remove bid amount of 0');

        IERC20 token = IERC20(bidCurrency);
        emit BidRemoved(_tokenID, bid);
        delete _tokenBidders[_tokenID][_bidder];
        token.safeTransfer(bid._bidder, bidAmount);
    }

    /**
     * @dev See {IMarket}
     */
    function setAdminAddress(address _newAdminAddress) external override onlyMediaCaller returns (bool) {
        require(_newAdminAddress != address(0), 'Market: Invalid Admin Address!');
        require(_adminAddress == address(0), 'Market: Admin Already Configured!');

        _adminAddress = _newAdminAddress;
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function getAdminAddress() external view override onlyMediaCaller returns (address) {
        return _adminAddress;
    }

    /**
     * @dev See {IMarket}
     */
    function setCommissionPercentage(uint8 _commissionPercentage) external override onlyMediaCaller returns (bool) {
        _adminCommissionPercentage = _commissionPercentage;
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function getCommissionPercentage() external view override onlyMediaCaller returns (uint8) {
        return _adminCommissionPercentage;
    }

    function endAuction(
        uint256 _tokenID,
        address _owner,
        address _creator
    ) external override onlyMediaCaller returns (bool) {
        require(uint256(_tokenAsks[_tokenID]._firstBidTime) != 0, "Market.Auction hasn't begun");
        require(
            block.timestamp >= _tokenAsks[_tokenID]._firstBidTime.add(_tokenAsks[_tokenID]._duration),
            "Auction hasn't completed"
        );
        // address(0) for _bidder is only need when sale type is of type Auction
        divideMoney(_tokenID, _owner, address(0), _tokenAsks[_tokenID]._highestBid, _creator);
    }

    /**
     * @notice Cancel an auction.
     * @dev Transfers the NFT back to the auction creator and emits an AuctionCanceled event
     */
    function cancelAuction(uint256 _tokenID) external override onlyMediaCaller {
        require(uint256(_tokenAsks[_tokenID]._firstBidTime) == 0, "Can't cancel an auction once it's begun");
        delete _tokenAsks[_tokenID];
    }

    /**
     * @dev See {IMarket}
     */
    function divideMoney(
        uint256 _tokenID,
        address _owner,
        address _bidder,
        uint256 _amountToDistribute,
        address _creator
    ) internal returns (bool) {
        require(_amountToDistribute > 0, "Market: Amount To Divide Can't Be 0!");

        Iutils.Ask memory _ask = _tokenAsks[_tokenID];
        IERC20 token = IERC20(_ask._currency);

        // first send admin cut
        uint256 adminCommission = _amountToDistribute.mul(_adminCommissionPercentage * EXPO).div(BASE);
        uint256 _amount = _amountToDistribute - adminCommission;

        token.transfer(_adminAddress, adminCommission);

        // fetch owners added royality points
        uint256 collabPercentage = tokenRoyaltyPercentage[_tokenID];
        uint256 royaltyPoints = _amount.mul(collabPercentage * EXPO).div(BASE);

        // royaltyPoints represents amount going to divide among Collaborators
        token.transfer(_owner, _amount.sub(royaltyPoints));

        // Collaboratoes will only receive share when creator have set some royalty and sale is occuring for the first time
        Collaborators storage tokenColab = tokenCollaborators[_tokenID];
        uint256 totalAmountTransferred = 0;

        if (tokenColab._receiveCollabShare == false) {
            for (uint256 index = 0; index < tokenColab._collaborators.length; index++) {
                // Individual Collaborator's share Amount

                uint256 amountToTransfer = royaltyPoints.mul(tokenColab._percentages[index] * EXPO).div(BASE);
                // transfer Individual Collaborator's share Amount
                token.transfer(tokenColab._collaborators[index], amountToTransfer);
                // Total Amount Transferred
                totalAmountTransferred = totalAmountTransferred.add(amountToTransfer);
            }
            // after transfering to collabs, remaining would be sent to creator
            // update collaborators got the shares
            tokenColab._receiveCollabShare = true;
        }

        token.transfer(_creator, royaltyPoints.sub(totalAmountTransferred));
        totalAmountTransferred = totalAmountTransferred.add(royaltyPoints.sub(totalAmountTransferred));

        totalAmountTransferred = totalAmountTransferred.add(_amount.sub(royaltyPoints));
        // Check for Transfer amount error
        require(totalAmountTransferred == _amount, 'Market: Amount Transfer Value Error!');
        delete _tokenBidders[_tokenID][_bidder];
        delete _tokenAsks[_tokenID];

        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function addAdminCommission(uint256 _amount) external override onlyMediaCaller returns (bool) {
        _adminPoints = _adminPoints.add(_amount);
        return true;
    }
}
