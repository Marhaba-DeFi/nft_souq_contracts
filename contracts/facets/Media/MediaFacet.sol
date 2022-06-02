// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155Factory/ERC1155FactoryFacet.sol";
import "../ERC721Factory/ERC721FactoryFacet.sol";
import "../../interfaces/IMedia.sol";
import "../../interfaces/IMarket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../libraries/LibDiamond.sol";
import "./LibMediaStorage.sol";
import "../Market/LibMarketStorage.sol";

contract MediaFacet is IMedia {
    
    modifier whenTokenExist(uint256 _tokenID, address _tokenAddress) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(
            ms.nftToCreators[_tokenAddress][_tokenID] != address(0),
            "Media: The Token Doesn't Exist!"
        );
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function getCollabsInfo(uint256 tokenId) external view returns (IMarket.Collaborators memory ) {
        LibMarketStorage.MarketStorage storage marketStorage = LibMarketStorage.marketStorage();
        return marketStorage._tokenCollaborators[tokenId];
    }

    function getNftCreator(address _tokenAddress, uint256 _tokenID) external view returns (address){
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return ms.nftToCreators[_tokenAddress][_tokenID];
    }

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

    function mintToken(MintAndSaleTokenData memory data)
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
                data.totalSupply,
                data.uri
            );
        } else {
            ERC721FactoryFacet(ms.diamondAddress).mint(ms._tokenCounter, msg.sender, data.uri);
            
        }
        ms.nftToOwners[data._tokenAddress][msg.sender][ms._tokenCounter] = msg.sender;
        ms.nftToCreators[data._tokenAddress][ms._tokenCounter] = msg.sender;

        MediaInfo memory newToken = MediaInfo(
            ms._tokenCounter,
            data.uri,
            data.title,
            _isFungible
        );

        // Hold token info
        ms.tokenIDToToken[data._tokenAddress][msg.sender][ms._tokenCounter] = newToken;

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

        // Put token on sale asa token got minted
        Iutils.Ask memory _ask = Iutils.Ask(
            data._tokenAddress,
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
        IMarket(ms.diamondAddress)._setAsk(ms._tokenCounter, data._tokenAddress, msg.sender, _ask);

        emitMintEvents(_isFungible, data);

        return ms._tokenCounter;
    }


    function mintTokenWithoutSale(MintData memory data)
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
                data.totalSupply,
                data.uri
            );
        } else {
            ERC721FactoryFacet(ms.diamondAddress).mint(ms._tokenCounter, msg.sender, data.uri);
            
        }
        ms.nftToOwners[data._tokenAddress][msg.sender][ms._tokenCounter] = msg.sender;
        ms.nftToCreators[data._tokenAddress][ms._tokenCounter] = msg.sender;

        MediaInfo memory newToken = MediaInfo(
            ms._tokenCounter,
            data.uri,
            data.title,
            _isFungible
        );

        // Hold token info
        ms.tokenIDToToken[data._tokenAddress][msg.sender][ms._tokenCounter] = newToken;

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


        return ms._tokenCounter;
    }

    function emitMintEvents(bool _isFungible, MintAndSaleTokenData memory data) internal {
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
    function getToken(uint256 _tokenID, address _tokenAddress, address _owner)
        external
        view
        override
        whenTokenExist(_tokenID, _tokenAddress)
        returns (MediaInfo memory)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return ms.tokenIDToToken[_tokenAddress][_owner][_tokenID];
    }

    function getTotalNumberOfTokens() external view returns (uint256) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        return ms._tokenCounter;
    }

    function setBid(uint256 _tokenID, Iutils.Bid calldata _bid)
        external
        payable
        override
        whenTokenExist(_tokenID, _bid._tokenAddress)
        returns (bool)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        MediaInfo memory token = ms.tokenIDToToken[_bid._tokenAddress][_bid._owner][_tokenID];
        // address _actualOwner = token._currentOwner;
        require(msg.sender == _bid._bidder, "Media: Bidder must be msg sender");
        require(_bid._owner != msg.sender, "Media: The Token Owner Can't Bid!");
        // require( _actualOwner == _owner, "Media: Incorrect Owner address is Supplied");
        require(
                ms.nftToOwners[_bid._tokenAddress][_bid._owner][_tokenID] == _bid._owner,
                "Media: Invalid Owner Provided!"
            );
        if (token._isFungible) {
            require(
                ERC1155FactoryFacet(_bid._tokenAddress).balanceOf(_bid._owner, _tokenID) >=
                    _bid._quantity,
                "Media: The Owner Don't Not Have Enough Tokens!"
            );
        } else {
            require(_bid._quantity == 1, "Media: Only 1 Token Is Available");
            require(ERC721FactoryFacet(_bid._tokenAddress).balanceOf(_bid._owner) >= _bid._quantity, "Media: The Owner Don't Have Enough Tokens!");
        }
        address _creator = ms.nftToCreators[_bid._tokenAddress][_tokenID];
        ifSoldTransfer(_tokenID, _bid._tokenAddress, _bid._owner, _creator, _bid);

        return true;
    }

    /**
     * @notice see IMedia
     */
    function setAsk(uint256 _tokenID, Iutils.Ask memory _ask) external override {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        address _owner = msg.sender;

        // make sure asker is the owner of the token
        require(
            msg.sender == _ask._sender,
            "MEDIA: sender in ask tuple needs to be msg.sender"
        );

        require(
            msg.sender == ms.nftToOwners[_ask._tokenAddress][msg.sender][_tokenID],
            "MEDIA: sender needs to be the owner of the token"
        );


        IMarket(ms.diamondAddress)._setAsk(_tokenID, _ask._tokenAddress, _owner, _ask);
    }

    function ifSoldTransfer(uint256 _tokenID, address _tokenAddress, address _owner, address _creator, Iutils.Bid calldata bid) internal {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        bool tokenSold = IMarket(ms.diamondAddress).setBid{value: msg.value}(
            _tokenID,
            _tokenAddress,
            _owner,
            msg.sender,
            bid,
            _creator
        );
        if (tokenSold)
            _transfer(_tokenID, _tokenAddress, _owner, bid._recipient, bid._quantity);
    }

    function removeBid(uint256 _tokenID, address _tokenAddress)
        external
        override
        whenTokenExist(_tokenID, _tokenAddress)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        IMarket(ms.diamondAddress).removeBid(_tokenID, _tokenAddress, msg.sender);
    }

    function endAuction(uint256 _tokenID, address _tokenAddress)
        external
        override
        whenTokenExist(_tokenID, _tokenAddress)
        returns (bool)
    {
        address _owner = msg.sender;
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        Iutils.Ask memory _ask = IMarket(ms.diamondAddress)._getTokenAsks(_tokenID, _tokenAddress, _owner);
        Iutils.Bid memory _bid = IMarket(ms.diamondAddress)._getTokenBid(_tokenID, _tokenAddress, _owner);
        require(
            _ask.askType == Iutils.AskTypes.AUCTION,
            "Media: Invalid Ask Type"
        );
        //this should be msg.sender, as NFT is already transfer from the owner to the bidder at the bid time.
        address _creator = ms.nftToCreators[_tokenAddress][_tokenID];
        IMarket(ms.diamondAddress).endAuction(_tokenID, _tokenAddress, _owner, _creator);

        _transfer(_tokenID, _tokenAddress, _owner, _bid._recipient, _bid._quantity);

        return true;
    }

    function acceptBid(uint256 _tokenID, address _tokenAddress, address _owner)
        external
        override
        whenTokenExist(_tokenID, _tokenAddress)
        returns (bool)
    {
        // TODO this is done now below, check either token is of type auction or not
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        Iutils.Ask memory _ask = IMarket(ms.diamondAddress)._getTokenAsks(_tokenID, _tokenAddress, _owner);
        Iutils.Bid memory _bid = IMarket(ms.diamondAddress)._getTokenBid(_tokenID, _tokenAddress, _owner);
        require(
            _ask.askType == Iutils.AskTypes.AUCTION,
            "Media: Invalid Ask Type"
        );
        address _currentOwner =  ms.nftToOwners[_tokenAddress][_owner][_tokenID]; // ms.tokenIDToToken[_tokenAddress][_owner][_tokenID]._currentOwner; //this should be msg.sender, as NFT is already transfer from the owner to the bidder at the bid time.
        require(msg.sender == _currentOwner, "Media: Only Token Owner Can accept Bid");
        address _creator = ms.nftToCreators[_tokenAddress][_tokenID];
        IMarket(ms.diamondAddress).acceptBid(_tokenID, _tokenAddress, _owner, _creator);

        _transfer(_tokenID, _tokenAddress, _owner, _bid._recipient, _bid._quantity);

        return true;
    }

    function cancelAuction(uint256 _tokenID, address _tokenAddress, address _owner) external override returns (bool) {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        require(
            ms.nftToOwners[_tokenAddress][_owner][_tokenID] == msg.sender,
            "Can only be called by auction creator or curator"
        );
        IMarket(ms.diamondAddress)._cancelAuction(_tokenID, _tokenAddress, _owner);
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
            _newCommissionPercentage <= 100,
            "Media: Commission Percentage Must Be Less Than 100!"
        );

        IMarket(ms.diamondAddress)._setCommissionPercentage(
            _newCommissionPercentage
        );
        return true;
    }

    function setMinimumBidIncrementPercentage(uint8 __minBidIncrementPercentage)
        external
        returns (bool)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        require(
            msg.sender == IMarket(ms.diamondAddress).getAdminAddress(),
            "Media: Only Admin Can Set Minimum Bid Increment Percentage!"
        );
        require(
            __minBidIncrementPercentage > 0,
            "Media: Invalid bid Increment Percentage"
        );
        require(
            __minBidIncrementPercentage <= 50,
            "Media: bid Increment Percentage Must Be Less Than 50!"
        );

        IMarket(ms.diamondAddress)._setMinimumBidIncrementPercentage(
            __minBidIncrementPercentage
        );
        return true;
    }


    function _transfer(
        uint256 _tokenID,
        address _tokenAddress,
        address _owner,
        address _recipient,
        uint256 _amount
    ) internal {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();

        IMedia.MediaInfo memory tokenInfo = ms.tokenIDToToken[_tokenAddress][_owner][_tokenID];

        if (tokenInfo._isFungible) {
            require(
                ERC1155FactoryFacet(_tokenAddress).balanceOf(
                    _owner,
                    _tokenID
                ) >= _amount,
                "Media: You Don't have Enough Tokens!"
            );
            ERC1155FactoryFacet(_tokenAddress).transferFrom(
                _owner,
                _recipient,
                _tokenID,
                _amount
            );
        } else {
             require(
                ERC721Facet(_tokenAddress).balanceOf(
                    _owner
                ) >= _amount,
                "Media: You Don't have Enough Tokens!"
            );
            ERC721FactoryFacet(_tokenAddress).transferFrom(
                _owner,
                _recipient,
                _tokenID
            );
        }
        MediaInfo memory tokenInstance = MediaInfo(
            _tokenID,
            tokenInfo._uri,
            tokenInfo._title,
            tokenInfo._isFungible
        );
        ms.tokenIDToToken[_tokenAddress][_recipient][_tokenID] = tokenInstance;

        ms.nftToOwners[_tokenAddress][_recipient][_tokenID] = _recipient;
        emit Transfer(_tokenID, _owner, _recipient, _amount);
    }

    function getTokenDetails(uint256 _tokenId, address _tokenAddress, address _owner)
        external
        view
        returns (IMedia.MediaInfo memory)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        return ms.tokenIDToToken[_tokenAddress][_owner][_tokenId];
    }
    function getTokenAsks(uint256 _tokenId, address _tokenAddress, address _owner)
        external
        view
        returns (Iutils.Ask memory)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        return IMarket(ms.diamondAddress)._getTokenAsks(_tokenId, _tokenAddress, _owner);
    }

    function getTokenBid(uint256 _tokenId, address _tokenAddress, address _owner)
        external
        view
        returns (Iutils.Bid memory)
    {
        LibMediaStorage.MediaStorage storage ms = LibMediaStorage.mediaStorage();
        
        return IMarket(ms.diamondAddress)._getTokenBid(_tokenId, _tokenAddress, _owner);
    }
}