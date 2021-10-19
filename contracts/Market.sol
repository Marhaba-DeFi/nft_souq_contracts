// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IMarket.sol';
// import './SafeMath.sol';
// import './IERC20.sol';
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
    mapping(uint256 => mapping(address => Bid)) private _tokenBidders;

    // bidderAddress => its Total Bid amount
    mapping(address => uint256) private userTotalBids;

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
        IMarket.Bid calldata _bid
    ) external override onlyMediaCaller returns (bool) {
        require(_bid._bidAmount != 0, "Market: You Can't Bid With 0 Amount!");
        require(_bid._amount != 0, "Market: You Can't Bid For 0 Tokens");
        require(!(_bid._amount < 0), "Market: You Can't Bid For Negative Tokens");
        require(_bid._currency != address(0), 'Market: bid currency cannot be 0 address');
        require(_bid._recipient != address(0), 'Market: bid recipient cannot be 0 address');

        // fetch existing bid, if there is any
        Bid storage existingBid = _tokenBidders[_tokenID][_bidder];

        // Minus the Previous bid, if any, else 0
        userTotalBids[_bidder] = userTotalBids[_bidder].sub(_tokenBidders[_tokenID][_bid._bidder]._bidAmount);

        // If there is an existing bid, refund it before continuing
        if (existingBid._amount > 0) {
            removeBid(_tokenID, _bid._bidder);
        }

        IERC20 token = IERC20(_bid._currency);
        // We must check the balance that was actually transferred to the market,
        // as some tokens impose a transfer fee and would not actually transfer the
        // full amount to the market, resulting in locked funds for refunds & bid acceptance
        uint256 beforeBalance = token.balanceOf(address(this));
        // TODO
        token.safeTransferFrom(_bidder, address(this), _bid._amount);
        uint256 afterBalance = token.balanceOf(address(this));

        // Set New Bid for the Token
        _tokenBidders[_tokenID][_bid._bidder] = Bid(
            afterBalance.sub(beforeBalance),
            _bid._amount,
            _bid._currency,
            _bid._bidder,
            _bid._recipient
        );

        // Add New bid
        userTotalBids[_bidder] = userTotalBids[_bidder].add(_bid._bidAmount);

        // Add Redeem points for the user
        userRedeemPoints[_bidder] = userRedeemPoints[_bidder].add(_bid._bidAmount);

        emit BidCreated(_tokenID, _bid);
        // Needs to be taken care of
        // // If a bid meets the criteria for an ask, automatically accept the bid.
        // // If no ask is set or the bid does not meet the requirements, ignore.
        // if (
        //     _tokenAsks[_tokenID].currency != address(0) &&
        //     _bid.currency == _tokenAsks[_tokenID].currency &&
        //     _bid.amount >= _tokenAsks[_tokenID].amount
        // ) {
        //     // Finalize exchange
        //     _finalizeNFTTransfer(_tokenID, _bid._bidder);
        // }
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function acceptBid(
        uint256 _tokenID,
        address _owner,
        address _bidder,
        uint256 _amount
    ) external override returns (bool) {
        require(
            _newTokenBids[_tokenID][_owner][_bidder]._bidAmount != 0,
            'Market: The Specified Bidder Has No bids For The Token!'
        );
        require(
            _newTokenBids[_tokenID][_owner][_bidder]._amount == _amount,
            'Market: The Bidder Has Not Bid For The Specified Amount Of Tokens!'
        );

        // Divide the points
        divideMoney(_tokenID, _owner, _newTokenBids[_tokenID][_owner][_bidder]._bidAmount);

        // Minus Bidder's Redeemable Points
        userRedeemPoints[_bidder] = userRedeemPoints[_bidder].sub(_newTokenBids[_tokenID][_owner][_bidder]._bidAmount);

        // Remove All The bids for the Token
        for (uint256 index; index < newTokenBidders[_tokenID][_owner].length; index++) {
            userTotalBids[newTokenBidders[_tokenID][_owner][index]] = userTotalBids[
                newTokenBidders[_tokenID][_owner][index]
            ].sub(_newTokenBids[_tokenID][_owner][newTokenBidders[_tokenID][_owner][index]]._bidAmount);
            delete _newTokenBids[_tokenID][_owner][newTokenBidders[_tokenID][_owner][index]];
        }

        // Remove All Bidders from the list
        delete newTokenBidders[_tokenID][_owner];

        emit AcceptBid(_tokenID, _owner, _amount, _bidder, _newTokenBids[_tokenID][_owner][_bidder]._bidAmount);

        return true;
    }

    function removeBid(uint256 _tokenID, address _bidder) public override onlyMediaCaller {
        Bid storage bid = _tokenBidders[_tokenID][_bidder];
        uint256 bidAmount = bid._amount;
        address bidCurrency = bid._currency;

        require(bid._bidder == _bidder, 'Market: Only bidder can remove the bid');
        require(bid._amount > 0, 'Market: cannot remove bid amount of 0');

        IERC20 token = IERC20(bidCurrency);
        userTotalBids[_bidder] = userTotalBids[_bidder].sub(_tokenBidders[_tokenID][bid._bidder]._bidAmount);
        emit BidRemoved(_tokenID, bid);
        delete _tokenBidders[_tokenID][_bidder];
        token.safeTransfer(bid._bidder, bidAmount);
    }

    /**
     * @dev See {IMarket}
     */
    function cancelBid(
        uint256 _tokenID,
        address _bidder,
        address _owner
    ) external override onlyMediaCaller returns (bool) {
        // require(
        //     userTotalBids[_bidder] != 0,
        //     "Market: You Have Not Set Any Bid Yet!"
        // );
        // require(
        //     tokenBids[_tokenID][_bidder] != 0,
        //     "Market: You Have Not Bid For This Token."
        // );

        // // Minus from User's Total Bids
        // userTotalBids[_bidder] = userTotalBids[_bidder].sub(
        //     tokenBids[_tokenID][_bidder]
        // );

        // // Delete the User's Bid
        // delete tokenBids[_tokenID][_bidder];

        // // Remove Bidder from Token's Bidders' list
        // removeBidder(_tokenID, _bidder);

        // emit CancelBid(_tokenID, _bidder);

        // return true;

        // New Code -------------------
        require(userTotalBids[_bidder] != 0, 'Market: You Have Not Set Any Bid Yet!');
        require(_newTokenBids[_tokenID][_owner][_bidder]._bidAmount != 0, 'Market: You Have Not Bid For This Token.');

        // Minus from Bidder's Total Bids
        userTotalBids[_bidder] = userTotalBids[_bidder].sub(_newTokenBids[_tokenID][_owner][_bidder]._bidAmount);

        // Delete the User's Bid
        delete _newTokenBids[_tokenID][_owner][_bidder];

        // Remove Bidder from Token's Bidders' list
        removeBidder(_tokenID, _bidder, _owner);

        emit CancelBid(_tokenID, _bidder);

        return true;
    }

    /**
     * @dev This internal method is used to remove the Bidder's address who has canceled bid from Bidders' list, for the Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to remove bidder of
     * @param _bidder Address of the Bidder to remove
     */
    function removeBidder(
        uint256 _tokenID,
        address _bidder,
        address _owner
    ) internal {
        for (uint256 index = 0; index < newTokenBidders[_tokenID][_owner].length; index++) {
            if (newTokenBidders[_tokenID][_owner][index] == _bidder) {
                newTokenBidders[_tokenID][_owner][index] = newTokenBidders[_tokenID][_owner][
                    newTokenBidders[_tokenID][_owner].length - 1
                ];
                newTokenBidders[_tokenID][_owner].pop();
                break;
            }
        }
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
        uint256 _amountToDivide
    ) public override returns (bool) {
        require(_amountToDivide > 0, "Market: Amount To Divide Can't Be 0!");

        // If no royalty points have been set, transfer the amount to the owner
        if (tokenRoyaltyPercentage[_tokenID] == 0) {
            userRedeemPoints[_owner] = userRedeemPoints[_owner].add(_amountToDivide);
            return true;
        }

        // Amount to divide among Collaborators
        uint256 royaltyPoints = _amountToDivide.mul(tokenRoyaltyPercentage[_tokenID]).div(100);

        Collaborators memory tokenColab = tokenCollaborators[_tokenID];

        uint256 amountToTransfer;
        uint256 totalAmountTransferred;

        for (uint256 index = 0; index < tokenColab._collaborators.length; index++) {
            // Individual Collaborator's share Amount
            amountToTransfer = royaltyPoints.mul(tokenColab._percentages[index]).div(100);

            // Total Amount Transferred
            totalAmountTransferred = totalAmountTransferred.add(amountToTransfer);

            // Add Collaborator's Redeem points
            userRedeemPoints[tokenColab._collaborators[index]] = userRedeemPoints[tokenColab._collaborators[index]].add(
                amountToTransfer
            );
        }

        // Add Remaining amount to Owner's redeem points
        userRedeemPoints[_owner] = userRedeemPoints[_owner].add(_amountToDivide.sub(royaltyPoints));

        totalAmountTransferred = totalAmountTransferred.add(_amountToDivide.sub(royaltyPoints));

        // Check for Transfer amount error
        require(totalAmountTransferred == _amountToDivide, 'Market: Amount Transfer Value Error!');

        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function addAdminCommission(uint256 _amount) external override onlyMediaCaller returns (bool) {
        _adminPoints = _adminPoints.add(_amount);
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function redeemPoints(address _userAddress, uint256 _amount) external override onlyMediaCaller returns (bool) {
        // Admin's points
        if (_userAddress == _adminAddress) {
            require(_adminPoints >= _amount, "Market: You Don't have that much points to redeem!");

            _adminPoints = _adminPoints.sub(_amount);
            payable(_adminAddress).transfer(_amount);
        } else {
            require(userRedeemPoints[_userAddress] >= _amount, "Market: You Don't Have That Much Points To Redeem!");
            require(
                (userRedeemPoints[_userAddress] - userTotalBids[_userAddress]) >= _amount,
                "Market: You Have Bids, You Can't Redeem That Much Points!"
            );

            payable(address(_userAddress)).transfer(_amount);
            userRedeemPoints[_userAddress] = userRedeemPoints[_userAddress].sub(_amount);
        }

        emit Redeem(_userAddress, _amount);
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function getUsersRedeemablePoints(address _userAddress) external view override onlyMediaCaller returns (uint256) {
        if (_userAddress == _adminAddress) {
            return _adminPoints;
        }
        return (userRedeemPoints[_userAddress] - userTotalBids[_userAddress]);
    }
}
