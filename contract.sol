// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DragonTest is Initializable, ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    string public baseExtension;
    uint256 public maxMintAmount;
    using Strings for uint256;

    mapping (uint256 => uint256) public tokenSupply;
    mapping (address => bool) public blacklisted;
    mapping (uint256 => uint256) public maxSupply;

    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    TokenInfo[] public AllowedCrypto;

    function initialize() initializer public {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        
        maxSupply[1] = 2000;
        maxMintAmount = 5;
        baseExtension = ".json";
    }

    function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmPF1t8fdT2kDAAYpitP7wSurFyNewAzxmCdZWoogE9q6V/";
    }

    function mint(uint256 _mintAmount, uint256 _pid) public payable whenNotPaused {
        require(_mintAmount > 0, "Mint amount minimum 5");

        uint256 mintTokenId = 1;
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        uint256 supply;
        supply = tokenSupply[mintTokenId];


        require(_mintAmount <= maxMintAmount, "Bigger then maxMintAmount");
        require(supply + _mintAmount <= maxSupply[mintTokenId], "Max supply reached!");
        require(blacklisted[msg.sender] != true, "Already minted a dragon.");

        if (msg.sender != owner()) {
            require(msg.value == cost * _mintAmount, "Not enough balance.");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            paytoken.transferFrom(msg.sender, address(this), cost);
            _mint(msg.sender, 1, 1, "0x000");
            tokenSupply[mintTokenId]++;
        }
        blacklisted[msg.sender] = true;

    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return string(
            abi.encodePacked(
                currentBaseURI,
                Strings.toString(_tokenId),
                baseExtension
            )
        );
    }

    //// Only owner functions.

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setmaxSupply(uint256 _tokenId, uint256 _maxSupply) public onlyOwner {
        maxSupply[_tokenId] = _maxSupply;
    }

    function withdraw(uint256 _pid) public payable onlyOwner {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }



}
