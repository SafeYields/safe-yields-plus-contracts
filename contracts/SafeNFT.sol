// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol';
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./interfaces/ISafeToken.sol";

/// @title  Safe NFT
/// @author crypt0grapher
/// @notice This contract is responsible for $BUSD pool: mainly deposit/withdrawal and farms management
contract SafeNFT is ERC1155PresetMinterPauser, Proxied {

    enum Tiers {Tier1, Tier2, Tier3, Tier4}
    uint256 public constant TIERS = 4;
    uint256[TIERS] public tierPrice;
    ISafeToken public safeToken;

    /// @dev total wallets on the protocol, see Wallets enum
    uint256 public constant WALLETS = 4;

    // @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    uint256[WALLETS] public priceDistributionOnMint;

    uint256 constant HUNDRED_PERCENT = 10000;

    function initialize(string memory _uri, uint256[TIERS] memory _tierPrice, ISafeToken _safeToken, uint256[WALLETS] memory _priceDistributionOnMint) public proxied {
        _setURI(_uri);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        tierPrice = _tierPrice;
        safeToken = _safeToken;
    }

    constructor(string memory _uri, uint256[TIERS] memory _tierPrice, ISafeToken _safeToken, uint256[WALLETS] memory _priceDistributionOnMint) ERC1155PresetMinterPauser(_uri) {
        initialize(_uri, _tierPrice, _safeToken, _priceDistributionOnMint);
    }



    function buy(Tiers _tier, uint256 _amount) public {
        require(_amount > 0, "ERC1155PresetMinterPauser: amount must be greater than 0");
        require(tierPrice[uint256(_tier)] > 0, "ERC1155PresetMinterPauser: tier price must be greater than 0");
        uint256 id = uint256(_tier);
        uint256 price = tierPrice[uint256(_tier)] * _amount;
        IERC20 usd = safeToken.usd();
        address[WALLETS] memory wallets = safeToken.getWallets();

        IERC20(_msgSender()).transferFrom(_msgSender(), address(this), price);
        for (uint256 i = 0; i < WALLETS; i++) {
            uint256 taxAmount = price * priceDistributionOnMint[i] / HUNDRED_PERCENT;
            usd.transfer(wallets[i], taxAmount);
        }
        _mint(_msgSender(), id, _amount, "");
    }

}
