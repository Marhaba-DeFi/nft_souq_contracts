// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155Factory/ERC1155FactoryFacet.sol";
import "../ERC721Factory/ERC721FactoryFacet.sol";
import "../../interfaces/IMedia.sol";
import "../../interfaces/IMarket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../libraries/LibDiamond.sol";
import "./LibMediaStorage.sol";

contract MediaFacet is IMedia {
    
    modifier whenTokenExist(uint256 _tokenID) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(
            ms.tokenIDToToken[_tokenID]._creator != address(0),
            "Media: The Token Doesn't Exist!"
        );
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    // modifier onlyApprovedOrOwner(address spender, uint256 _tokenID) {
    //     require(_isApprovedOrOwner(spender, _tokenID), 'Media: Only approved or owner');
    //     _;
    // }

    function mediaInit(
        address _diamondAddress
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(
            ms.diamondAddress == address(0),
            "ALREADY_INITIALIZED"
        );

        require(_diamondAddress != address(0), "Media: Invalid Address!");

        require(msg.sender == ds.contractOwner, "Must own the contract.");


        ms.diamondAddress = _diamondAddress;
    }

    function mintToken(MediaData memory data)
        external
        override
        returns (uint256)
    {

        require(
            data.collaborators.length == data.percentages.length,
            "Media: Collaborators Info is not correct"
        );
        bool _isFungible = data.totalSupply > 1 ? true : false;

        // verify sum of collaborators percentages needs to be less then or equals to 10
        uint256 sumOfCollabRoyalty = 0;
        for (uint256 index = 0; index < data.collaborators.length; index++) {
            sumOfCollabRoyalty = sumOfCollabRoyalty + (data.percentages[index]);
        }
        require(
            sumOfCollabRoyalty <= 10,
            "Media: Sum of Collaborators Percentages can be maximum 10"
        );

        // Calculate hash of the Token
        bytes32 tokenHash = keccak256(
            abi.encodePacked(data.uri, data.title, data.totalSupply)
        );
        
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        // Check if Token with same data exists
        require(
            ms._tokenHashToTokenID[tokenHash] == 0,
            "Media: Token With Same Data Already Exist!"
        );

        ms._tokenCounter++;

        // Store the hash
        ms._tokenHashToTokenID[tokenHash] = ms._tokenCounter;

        // if token supply is 1 means we need to mint ERC 721 otherwise ERC 1155
        if (_isFungible) {
            ERC1155FactoryFacet(ms.diamondAddress).mint(
                ms._tokenCounter,
                msg.sender,
                data.totalSupply
            );
        } else {
            ERC721FactoryFacet(ms.diamondAddress).mint(ms._tokenCounter, msg.sender);
            ms.nftToOwners[ms._tokenCounter] = msg.sender;
        }

        ms.nftToCreators[ms._tokenCounter] = msg.sender;

        MediaInfo memory newToken = MediaInfo(
            ms._tokenCounter,
            msg.sender,
            msg.sender,
            data.uri,
            data.title,
            _isFungible
        );

        // Hold token info
        ms.tokenIDToToken[ms._tokenCounter] = newToken;

        // add collabs, percentages and sum of percentage
        IMarket.Collaborators memory newTokenColab = IMarket.Collaborators(
            data.collaborators,
            data.percentages,
            sumOfCollabRoyalty == 0 ? true : false
        );

        // route to market contract
        IMarket(ms.diamondAddress).setCollaborators(ms._tokenCounter, newTokenColab);
        IMarket(ms.diamondAddress).setRoyaltyPoints(
            ms._tokenCounter,
            data.royaltyPoints
        );

        // Put token on sale as a token got minted
        Iutils.Ask memory _ask = Iutils.Ask(
            msg.sender,
            data._reserveAmount,
            data._askAmount,
            data.totalSupply,
            data.currencyAsked,
            data.askType,
            data._duration,
            0,
            address(0),
            0,
            block.timestamp
        );
        IMarket(ms.diamondAddress)._setAsk(ms._tokenCounter, _ask);

        // fire events
        emitMintEvents(_isFungible, data);

        return ms._tokenCounter;
    }

    function emitMintEvents(bool _isFungible, MediaData memory data) internal {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        emit MintToken(
            ms._tokenCounter,
            _isFungible,
            data.uri,
            data.title,
            data.totalSupply,
            data.royaltyPoints,
            data.collaborators,
            data.percentages
        );

        emit TokenCounter(ms._tokenCounter);
    }

    /**
     * @notice This method is used to Get Token of _tokenID
     *
     * @param _tokenID TokenID of the Token to get
     *
     * @return Token The Token
     */
    function getToken(uint256 _tokenID)
        external
        view
        override
        whenTokenExist(_tokenID)
        returns (MediaInfo memory)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return ms.tokenIDToToken[_tokenID];
    }

    function getTotalNumberOfTokens() external view returns (uint256) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return ms._tokenCounter;
    }

    function setBid(uint256 _tokenID, Iutils.Bid calldata bid)
        external
        override
        whenTokenExist(_tokenID)
        returns (bool)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        address _owner = ms.tokenIDToToken[_tokenID]._currentOwner;
        require(msg.sender == bid._bidder, "Media: Bidder must be msg sender");
        require(bid._bidder != address(0), "Media: bidder cannot be 0 address");
        require(_owner != msg.sender, "Media: The Token Owner Can't Bid!");

        MediaInfo memory token = ms.tokenIDToToken[_tokenID];
        if (token._isFungible) {
            require(
                ERC1155FactoryFacet(ms.diamondAddress).balanceOf(_owner, _tokenID) >=
                    bid._bidAmount,
                "Media: The Owner Does Not Have That Much Tokens!"
            );
        } else {
            require(bid._bidAmount == 1, "Media: Only 1 Token Is Available");
            require(
                ms.nftToOwners[_tokenID] == _owner,
                "Media: Invalid Owner Provided!"
            );
        }

        ifSoldTransfer(_tokenID, bid, _owner);

        return true;
    }

    function ifSoldTransfer(uint256 _tokenID, Iutils.Bid calldata bid, address _owner) internal {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        bool tokenSold = IMarket(ms.diamondAddress).setBid(
            _tokenID,
            msg.sender,
            bid,
            _owner,
            ms.nftToCreators[_tokenID]
        );
        if (tokenSold)
            _transfer(_tokenID, _owner, bid._recipient, bid._bidAmount);
    }

    /**
     * @notice see IMedia
     */
    function setAsk(uint256 _tokenID, Iutils.Ask memory ask) external override {
        require(
            msg.sender == ask._sender,
            "MEDIA: sender in ask tuple needs to be msg.sender"
        );
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        IMarket(ms.diamondAddress)._setAsk(_tokenID, ask);
    }


    function removeBid(uint256 _tokenID)
        external
        override
        whenTokenExist(_tokenID)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        IMarket(ms.diamondAddress).removeBid(_tokenID, msg.sender);
    }

    function endAuction(uint256 _tokenID)
        external
        override
        whenTokenExist(_tokenID)
        returns (bool)
    {
        // TODO this is done now below, check either token is of type auction or not
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        Iutils.Ask memory _ask = IMarket(ms.diamondAddress)._getTokenAsks(_tokenID);
        Iutils.Bid memory _bid = IMarket(ms.diamondAddress)._getTokenBid(_tokenID);
        require(
            _ask.askType == Iutils.AskTypes.AUCTION,
            "Media: Invalid Ask Type"
        );
        //this should be msg.sender, as NFT is already transfer from the owner to the bidder at the bid time.
        address _owner = ms.tokenIDToToken[_tokenID]._currentOwner;
        address _creator = ms.nftToCreators[_tokenID];
        IMarket(ms.diamondAddress).endAuction(_tokenID, _owner, _creator);

        _transfer(_tokenID, _owner, _bid._recipient, _bid._bidAmount);

        return true;
    }

    function acceptBid(uint256 _tokenID)
        external
        override
        whenTokenExist(_tokenID)
        returns (bool)
    {
        // TODO this is done now below, check either token is of type auction or not
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        Iutils.Ask memory _ask = IMarket(ms.diamondAddress)._getTokenAsks(_tokenID);
        Iutils.Bid memory _bid = IMarket(ms.diamondAddress)._getTokenBid(_tokenID);
        require(
            _ask.askType == Iutils.AskTypes.AUCTION,
            "Media: Invalid Ask Type"
        );
        address _owner = ms.tokenIDToToken[_tokenID]._currentOwner; //this should be msg.sender, as NFT is already transfer from the owner to the bidder at the bid time.
        require(msg.sender == _owner, "Media: Only Token Owner Can accept Bid");
        address _creator = ms.nftToCreators[_tokenID];
        IMarket(ms.diamondAddress).acceptBid(_tokenID, _owner, _creator);

        _transfer(_tokenID, _owner, _bid._recipient, _bid._bidAmount);

        return true;
    }

    function cancelAuction(uint256 _tokenID) external override returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(
            ms.tokenIDToToken[_tokenID]._currentOwner == msg.sender,
            "Can only be called by auction creator or curator"
        );
        IMarket(ms.diamondAddress)._cancelAuction(_tokenID);
        return true;
    }

    function setAdminAddress(address _adminAddress) external onlyOwner returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        IMarket(ms.diamondAddress)._setAdminAddress(_adminAddress);
        return true;
    }

    function addCurrency(address _tokenAddress) external returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(
            msg.sender == IMarket(ms.diamondAddress).getAdminAddress(),
            "Media: Only Admin Can add new tokens!"
        );
        return IMarket(ms.diamondAddress)._addCurrency(_tokenAddress);
    }

    function removeCurrency(address _tokenAddress) external returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(
            msg.sender == IMarket(ms.diamondAddress).getAdminAddress(),
            "Media: Only Admin Can remove tokens!"
        );
        return IMarket(ms.diamondAddress)._removeCurrency(_tokenAddress);
    }

    function getAdminCommissionPercentage() external view returns (uint256) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return IMarket(ms.diamondAddress).getCommissionPercentage();
    }

    function setCommissionPercentage(uint8 _newCommissionPercentage)
        external
        returns (bool)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        require(
            msg.sender == IMarket(ms.diamondAddress).getAdminAddress(),
            "Media: Only Admin Can Set Commission Percentage!"
        );
        require(
            _newCommissionPercentage > 0,
            "Media: Invalid Commission Percentage"
        );
        require(
            _newCommissionPercentage <= 100,
            "Media: Commission Percentage Must Be Less Than 100!"
        );

        IMarket(ms.diamondAddress)._setCommissionPercentage(
            _newCommissionPercentage
        );
        return true;
    }

    function setMinimumBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        returns (bool)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        require(
            msg.sender == IMarket(ms.diamondAddress).getAdminAddress(),
            "Media: Only Admin Can Set Minimum Bid Increment Percentage!"
        );
        require(
            _minBidIncrementPercentage > 0,
            "Media: Invalid bid Increment Percentage"
        );
        require(
            _minBidIncrementPercentage <= 50,
            "Media: bid Increment Percentage Must Be Less Than 50!"
        );

        IMarket(ms.diamondAddress)._setMinimumBidIncrementPercentage(
            _minBidIncrementPercentage
        );
        return true;
    }

    /**
     * @dev See {IMedia}
     */
    function transfer(
        uint256 _tokenID,
        address _recipient,
        uint256 _amount
    ) external override whenTokenExist(_tokenID) returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        MediaInfo memory mediainfo = ms.tokenIDToToken[_tokenID];
        if (mediainfo._isFungible) {
            require(
                ERC1155FactoryFacet(ms.diamondAddress).balanceOf(
                    msg.sender,
                    _tokenID
                ) >= _amount,
                "Media: You Don't have The Tokens!"
            );
        } else {
            require(
                ms.nftToOwners[_tokenID] == msg.sender,
                "Media: Only Owner Can Transfer!"
            );
        }

        _transfer(_tokenID, msg.sender, _recipient, _amount);
        return true;
    }

    function _transfer(
        uint256 _tokenID, 
        address _owner,
        address _recipient,
        uint256 _amount
    ) internal {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        if (ms.tokenIDToToken[_tokenID]._isFungible) {
            ERC1155FactoryFacet(ms.diamondAddress).transferFrom(
                _owner,
                _recipient,
                _tokenID,
                _amount
            );
        } else {
            ERC721FactoryFacet(ms.diamondAddress).transferFrom(
                _owner,
                _recipient,
                _tokenID
            );
            ms.nftToOwners[_tokenID] = _recipient;
        }
        ms.tokenIDToToken[_tokenID]._currentOwner = _recipient;
        emit Transfer(_tokenID, _owner, _recipient, _amount);
    }

    function getTokenAsks(uint256 _tokenId)
        external
        view
        returns (Iutils.Ask memory)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        return IMarket(ms.diamondAddress)._getTokenAsks(_tokenId);
    }

    function getTokenBid(uint256 _tokenId)
        external
        view
        returns (Iutils.Bid memory)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        return IMarket(ms.diamondAddress)._getTokenBid(_tokenId);
    }
}