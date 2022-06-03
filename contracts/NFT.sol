// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage, IERC2981{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    constructor(address marketplaceAddress) ERC721("NK", "FS") {
        contractAddress = marketplaceAddress;
    }

    function createToken(string memory tokenURI, address to, uint96 royalties) public returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _setTokenRoyalty(newTokenId, to, royalties);
        setApprovalForAll(contractAddress, true);
       
        return newTokenId;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual override returns(address, uint256){
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if(royalty.receiver == address(0)){
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / 10000;
        return (royalty.receiver, royaltyAmount);
    }

    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual{
        require(feeNumerator <= 10000, "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }
}