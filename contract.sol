// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SFD is ERC1155, Ownable {
    constructor() ERC1155("") {}

    struct PayTokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    struct TokenInfo {
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 maxMintAmount;
        mapping (address => uint256) mintCount;
        mapping (address => bool) blacklist;
        bool mintAvaible;
        PayTokenInfo[] mintPrice;
    }

    mapping (uint256 => TokenInfo) public TokenList;
    using Strings for uint256;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmPF1t8fdT2kDAAYpitP7wSurFyNewAzxmCdZWoogE9q6V/";

    function mint(uint256 _id, uint256 _amount)
        public
    {
        address account = msg.sender;
        TokenInfo storage token = TokenList[_id]; // all info about token id.
        bool blacklisted = token.blacklist[account];
        bool mintAvaible = token.mintAvaible;
        uint256 totalSupply = token.totalSupply;
        uint256 maxSupply = token.maxSupply;
        uint256 maxMintAmount = token.maxMintAmount;
        PayTokenInfo[] storage mintPrice = token.mintPrice;



        require(blacklisted == false, "Already minted.");
        require(mintAvaible == true, "Mint paused.");
        require(_amount + totalSupply <= maxSupply, "Max supply reached");
        require(_amount <= maxMintAmount, "Bigger then maxMintAmount");

        for (uint256 l = 1; l <= _amount; l++) {
            for (uint256 i = 0; i < mintPrice.length; i++) {
                uint256 paybalance = mintPrice[i].paytoken.balanceOf(account);
                require(mintPrice[i].costvalue <= paybalance, "Not enough balance.");
                mintPrice[i].paytoken.transferFrom(account, address(this), mintPrice[i].costvalue);
            }
            _mint(account, _id, 1, "0x000");

            TokenList[_id].totalSupply++;   
        }
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return string(
            abi.encodePacked(
                currentBaseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }


    // owner functions
    
    function setMintPrice(uint256 _id, IERC20[] memory _paytokens, uint256[] memory _costvalues) public onlyOwner {
        
        for (uint256 i = 0; i < _paytokens.length; i++) {
            TokenList[_id].mintPrice[i].paytoken = _paytokens[i];
            TokenList[_id].mintPrice[i].costvalue = _costvalues[i];
        }
    }

    function setTokenInfo(uint256 _id, uint256 _maxSupply, uint256 _maxMintAmount, bool _mintAvaible) public onlyOwner {
        TokenList[_id].maxSupply = _maxSupply;
        TokenList[_id].maxMintAmount = _maxMintAmount;
        TokenList[_id].mintAvaible = _mintAvaible;
    }

}