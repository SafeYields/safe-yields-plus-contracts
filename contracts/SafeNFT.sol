// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol';
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

/// @title  Safe NFT
/// @author crypt0grapher
/// @notice This contract is responsible for $BUSD pool: mainly deposit/withdrawal and farms management
contract SafeVault is ERC1155PresetMinterPauser, Proxied {

    enum Tiers {Tier1, Tier2, Tier3, Tier4}
    uint256[4] public tierPrice;

    function initialize(string memory uri, uint256[4] memory _tierPrice) public proxied {
        _setURI(uri_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        tierPrice = _tierPrice;
    }

    constructor(string memory uri, uint256[4] memory _tierPrice){
        initialize(uri, _tierPrice);
    }

    function mint(Tiers tier, uint256 _amount) {
        require(_amount > 0, "ERC1155PresetMinterPauser: amount must be greater than 0");
        require(tierPrice[uint256(tier)] > 0, "ERC1155PresetMinterPauser: tier price must be greater than 0");
        uint256 _id = uint256(tier);
        uint256 _price = tierPrice[uint256(tier)] * _amount;
        IERC20(_msgSender()).transferFrom(_msgSender(), address(this), _price);
        _mint(_msgSender(), _id, _amount, "");
    }
}
