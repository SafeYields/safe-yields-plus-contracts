// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./interfaces/ISafeToken.sol";
import "./interfaces/ISafeNFT.sol";
import "./interfaces/ISafeVault.sol";
import "./Wallets.sol";
import "hardhat/console.sol";

/// @title  Safe NFT
/// @author crypt0grapher
/// @notice Safe Yields NFT token based on ERC1155 standard, id [0..3] represents one of the 4 tiers
contract SafeNFT is ISafeNFT, Wallets, ERC1155PresetMinterPauser, ERC1155Supply, Proxied {

    uint256 public constant TIERS = 4;
    uint256[TIERS] public price;
    uint256[TIERS] public maxSupply;

    ISafeToken public safeToken;
    ISafeVault public safeVault;
    IERC20 public usd;
    string public constant name = "Safe Yields NFT";

    // @dev Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    uint256[WALLETS] public priceDistributionOnMint;
    uint256[WALLETS] public profitDistribution;

    function initialize(string memory _uri, uint256[TIERS] memory _price, uint256[TIERS] memory _maxSupply, ISafeToken _safeToken, uint256[WALLETS] memory _priceDistributionOnMint, uint256[WALLETS] memory _profitDistribution) public proxied {
        _setURI(_uri);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        price = _price;
        maxSupply = _maxSupply;
        safeToken = _safeToken;
        priceDistributionOnMint = _priceDistributionOnMint;
        profitDistribution = _profitDistribution;
        _setWallets(safeToken.getWallets());
        safeVault = safeToken.safeVault();
        usd = safeToken.usd();
        usd.approve(address(safeToken), type(uint256).max);
        usd.approve(address(safeVault), type(uint256).max);
        safeToken.approve(address(safeToken), type(uint256).max);
    }

    constructor(string memory _uri, uint256[TIERS] memory _price, uint256[TIERS] memory _maxSupply, ISafeToken _safeToken, uint256[WALLETS] memory _priceDistributionOnMint, uint256[WALLETS] memory _profitDistribution) ERC1155PresetMinterPauser(_uri) {
        initialize(_uri, _price, _maxSupply, _safeToken, _priceDistributionOnMint, _profitDistribution);
    }

    function buy(Tiers _tier, uint256 _amount) public {
        console.log("buying NFT");
        require(_amount > 0, "ERC1155PresetMinterPauser: amount must be greater than 0");
        ///todo check on totalsupply per tier
        require(price[uint256(_tier)] > 0, "ERC1155PresetMinterPauser: tier price must be greater than 0");
        uint256 id = uint256(_tier);
        uint256 usdPrice = price[uint256(_tier)] * _amount;
        console.log("transferring usdPrice", usdPrice);
        usd.transferFrom(_msgSender(), address(this), usdPrice);
        uint256 toSellForSafe = _getTotalShare(usdPrice, priceDistributionOnMint);
        console.log("transferring toSellForSafe", toSellForSafe);
        uint256 safeAmount = safeToken.buySafeForExactAmountOfUSD(toSellForSafe);
        console.log("safeAmount returned from ", safeAmount);
        uint256 amountDistributed = _distribute(safeToken, safeAmount, priceDistributionOnMint);
        uint256 balance = usd.balanceOf(address(this));
        if (balance > 0) {
            safeVault.deposit(balance);
        }
        _mint(_msgSender(), id, _amount, "");
    }

    function distributeRewards(uint256 _amountUSD) public {
        console.log("transferring usdPrice", _amountUSD);
        usd.transferFrom(_msgSender(), address(this), _amountUSD);
        uint256 rewards = _amountUSD / 2;
        uint256 toSellForSafe = _getTotalShare(_amountUSD - rewards, profitDistribution);
        console.log("transferring toSellForSafe", toSellForSafe);
        uint256 safeAmount = safeToken.buySafeForExactAmountOfUSD(toSellForSafe);
        console.log("safeAmount returned from ", safeAmount);
        uint256 amountDistributed = _distribute(safeToken, safeAmount, profitDistribution);

        ///todo agree on the distribution routine and implement it, is it by the amount of NFTs or by the amount of BUSD in the pool?

        uint256 balance = usd.balanceOf(address(this));
        if (balance > 0) {
            safeVault.deposit(balance);
        }
    }

    function claimReward() public {

    }

    function pendingRewards() external returns (uint256) {
        return 0;
    }

    function percentOfTreasury() external returns (uint256) {
        return 0;
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        require(totalSupply(ids[0]) <= maxSupply[ids[0]], "SafeNFT: max supply reached");
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155PresetMinterPauser, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155PresetMinterPauser, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
