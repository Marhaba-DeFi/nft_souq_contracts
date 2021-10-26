// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IMarket.sol';
import './interfaces/Iutils.sol';

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract Market is IMarket {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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
    mapping(uint256 => Iutils.Ask) public _tokenAsks;

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

    modifier onlyMediaCaller() {
        require(msg.sender == _mediaContract, 'Market: Unauthorized Access!');
        _;
    }

    // New Code -----------

    struct NewBid {
        uint256 _amount;
        uint256 _bidAmount;
    }

    // tokenID => owner => bidder => Bid Struct
    mapping(uint256 => mapping(address => mapping(address => NewBid))) private _newTokenBids;

    // tokenID => owner => all bidders
    mapping(uint256 => mapping(address => address[])) private newTokenBidders;

    // -------------------

    fallback() external {}

    receive() external payable {}

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
        require(_tokenAsks[_tokenID]._currency != address(0), 'Token is not open for Sale');
        require(_bid._amount >= _tokenAsks[_tokenID]._reserveAmount, 'Bid Cannot be placed below the min Amount');
        require(_bid._currency == _tokenAsks[_tokenID]._currency, 'Incorrect payment Method');
        require(
            IERC20(_bid._currency).allowance(_bid._bidder, address(this)) >= _bid._amount,
            'Please Approve Tokens Before You Bid'
        );

        // fetch existing bid, if there is any
        Iutils.Bid storage existingBid = _tokenBidders[_tokenID][_bidder];

        // If there is an existing bid, refund it before continuing
        if (existingBid._amount > 0) {
            removeBid(_tokenID, _bid._bidder);
        }

        IERC20 token = IERC20(_bid._currency);
        // We must check the balance that was actually transferred to the market,
        // as some tokens impose a transfer fee and would not actually transfer the
        // full amount to the market, resulting in locked funds for refunds & bid acceptance
        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(_bidder, address(this), _bid._amount);
        uint256 afterBalance = token.balanceOf(address(this));
        // Set New Bid for the Token
        _tokenBidders[_tokenID][_bid._bidder] = Iutils.Bid(
            _bid._bidAmount,
            afterBalance.sub(beforeBalance),
            _bid._currency,
            _bid._bidder,
            _bid._recipient
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
            divideMoney(_tokenID, _owner, _bid._amount, _creator);
        }
        return true;
    }

    // /**
    //  * @notice Sets the ask on a particular media. If the ask cannot be evenly split into the media's
    //  * bid shares, this reverts.
    //  */
    function setAsk(uint256 _tokenID, Iutils.Ask memory ask) public override onlyMediaCaller {
        // require(
        //     (ask.askType != Iutils.AskTypes.FIXED) && (ask._reserveAmount == ask._amount),
        //     'Amount observe and Asked Need to be same for Fixed Sale'
        // );
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

    // TODO: To be removed
    function getMarketBalance() external view returns (uint256) {
        return payable(this).balance;
    }

    /**
     * @dev See {IMarket}
     */
    function divideMoney(
        uint256 _tokenID,
        address _owner,
        uint256 _amount,
        address _creator
    ) public override returns (bool) {
        require(_amount > 0, "Market: Amount To Divide Can't Be 0!");

        Iutils.Ask memory _ask = _tokenAsks[_tokenID];
        IERC20 token = IERC20(_ask._currency);

        // fetch owners added royality points
        uint256 royaltyPoints = _amount.mul(tokenRoyaltyPercentage[_tokenID]).div(100);

        // royaltyPoints represents amount going to divide among Collaborators
        if (royaltyPoints == 0) {
            // send payment to current owner if creator does not set any royalty
            token.safeTransferFrom(address(this), _owner, _amount.sub(royaltyPoints));
            return true;
        }

        // Collaboratoes will only receive share when creator have set some royalty and sale is occuring for the first time
        Collaborators memory tokenColab = tokenCollaborators[_tokenID];
        uint256 totalAmountTransferred = 0;

        if (royaltyPoints != 0 && tokenColab._receiveCollabShare == true) {
            token.safeTransferFrom(address(this), _creator, royaltyPoints);
            token.safeTransferFrom(address(this), _owner, _amount.sub(royaltyPoints));
            return true;
        }

        if (tokenColab._receiveCollabShare == false) {
            for (uint256 index = 0; index < tokenColab._collaborators.length; index++) {
                // Individual Collaborator's share Amount
                uint256 amountToTransfer = royaltyPoints.mul(tokenColab._percentages[index]).div(100);
                // transfer Individual Collaborator's share Amount
                token.safeTransferFrom(address(this), tokenColab._collaborators[index], _amount);
                // Total Amount Transferred
                totalAmountTransferred = totalAmountTransferred.add(amountToTransfer);
            }
            // update collaborators got the shares
            tokenColab._receiveCollabShare = true;
        }

        totalAmountTransferred = totalAmountTransferred.add(_amount.sub(royaltyPoints));
        // Check for Transfer amount error
        require(totalAmountTransferred == _amount, 'Market: Amount Transfer Value Error!');
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
