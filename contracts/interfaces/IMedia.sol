// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IMarket} from "./IMarket.sol";
import "./Iutils.sol";

interface IMedia {
    struct MediaInfo {
        uint256 _tokenID;
        address _creator;
        address _currentOwner;
        string _uri;
        string _title;
        bool _isFungible;
    }

    struct MediaData {
        string uri;
        string title;
        uint256 totalSupply;
        uint8 royaltyPoints;
        address[] collaborators;
        uint8[] percentages;
        Iutils.AskTypes askType;
        uint256 _askAmount;
        uint256 _reserveAmount;
        address currencyAsked;
        uint256 _duration;
    }

    event MintToken(
        uint256 _tokenCounter,
        bool isFungible,
        string uri,
        string title,
        uint256 totalSupply,
        uint8 royaltyPoints,
        address[] collaborators,
        uint8[] percentages
    );

     /**
     * @notice Set the ask on a piece of media
     */
    function setAsk(uint256 tokenId, Iutils.Ask calldata ask) external;

    event TokenCounter(uint256 _tokenCounter);

    event Transfer(
        uint256 _tokenID,
        address _owner,
        address _recipient,
        uint256 _amount
    );

    /**
     * @notice This method is used to Mint a new Token
     *
     * @return uint256 Token Id of the Minted Token
     */
    function mintToken(MediaData calldata data) external returns (uint256);

    function endAuction(uint256 _tokenID) external returns (bool);

    function acceptBid(uint256 _tokenID) external returns (bool);

    function cancelAuction(uint256 _tokenID) external returns (bool);

    /**
     * @notice This method is used to get details of the Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to get details of
     *
     * @return Token Structure of the Token
     */
    function getToken(uint256 _tokenID)
        external
        view
        returns (MediaInfo memory);

    /**
     * @notice This method is used to bid for the Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to Bid for
     *
     * @return bool Transaction status
     */
    function setBid(uint256 _tokenID, Iutils.Bid calldata bid)
        external
        payable
        returns (bool);

    function removeBid(uint256 tokenId) external;

    /**
     * @notice This method is used to Transfer Token
     *
     * @dev This method is used when Owner Wants to directly transfer Token
     *
     * @param _tokenID Token ID of the Token To Transfer
     * @param _recipient Receiver of the Token
     * @param _amount Number of Tokens To Transfer, In Case of ERC1155 Token
     *
     * @return bool Transaction status
     */
    function transfer(
        uint256 _tokenID,
        address _recipient,
        uint256 _amount
    ) external returns (bool);
}
