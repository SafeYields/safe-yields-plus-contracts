// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./interfaces/ISafeToken.sol";
import "./interfaces/ISafeNFT.sol";
import "./interfaces/ISafeVault.sol";
import "./Wallets.sol";
import "hardhat/console.sol";

/// @title  Safe NFT
/// @author crypt0grapher
/// @notice Safe Yields NFT token based on ERC1155 standard, id [0..3] represents one of the 4 tiers
contract SafeNFT is ISafeNFT, Wallets, ERC1155PresetMinterPauser, ERC1155Supply, Proxied, ReentrancyGuard {

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
    uint256 public referralShareForNFTPurchase;

    // @dev Presale status, if true, only whitelisted addresses can mint
    bool public presale;

    uint256 public currentDistributionId;
    // @dev distributionId => distribution amount in USD
    mapping(uint256 => uint256) public distributionOfProfit;
    // @dev mapping of distributions to amount to distributed by tiers (not necessarily claimed)
    mapping(uint256 => uint256[TIERS]) public distributionByTier;
    // @dev helper mapping of distributions to the the current erc1155 total supply snapshot on the moment of the distribution (per each tier)
    mapping(uint256 => uint256[TIERS]) public distributionTotalSupplySnapshot;
    // @dev distributionId => tier => account => alreadyDistributedAmount
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public alreadyDistributedAmount;
    // @dev distributionId => tier => amount
    mapping(uint256 => uint256[TIERS]) public alreadyDistributedAmountByTier;


    /* ============ Modifiers ============ */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have admin role");
        _;
    }

    /* ============ External and Public State Changing Functions ============ */

    function initialize(string memory _uri, uint256[TIERS] memory _price, uint256[TIERS] memory _maxSupply, ISafeToken _safeToken, uint256[WALLETS] memory _priceDistributionOnMint, uint256 _referralShareForNFTPurchase, uint256[WALLETS] memory _profitDistribution) public proxied {
        _setURI(_uri);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        price = _price;
        maxSupply = _maxSupply;
        safeToken = _safeToken;
        priceDistributionOnMint = _priceDistributionOnMint;
        referralShareForNFTPurchase = _referralShareForNFTPurchase;
        profitDistribution = _profitDistribution;
        _setWallets(safeToken.getWallets());
        safeVault = safeToken.safeVault();
        usd = safeToken.usd();
        usd.approve(address(safeToken), type(uint256).max);
        usd.approve(address(safeVault), type(uint256).max);
        safeToken.approve(address(safeToken), type(uint256).max);
        currentDistributionId = 0;
    }

    constructor(string memory _uri, uint256[TIERS] memory _price, uint256[TIERS] memory _maxSupply, ISafeToken _safeToken, uint256[WALLETS] memory _priceDistributionOnMint, uint256 _referralShareForNFTPurchase, uint256[WALLETS] memory _profitDistribution) ERC1155PresetMinterPauser(_uri) {
        initialize(_uri, _price, _maxSupply, _safeToken, _priceDistributionOnMint, _referralShareForNFTPurchase, _profitDistribution);
    }

    function togglePresale() public onlyAdmin {
        presale = !presale;
        emit TogglePresale(presale);
    }


    function buy(Tiers _tier, uint256 _amount, address _referral) public nonReentrant {
        console.log("buying NFT");
        require(_amount > 0, "ERC1155PresetMinterPauser: amount must be greater than 0");
        ///todo check on totalsupply per tier
        require(price[uint256(_tier)] > 0, "ERC1155PresetMinterPauser: tier price must be greater than 0");
        bool referralExists = _referral != address(0);
        require(!referralExists || referralExists && _referral != _msgSender(), "Referral must be different from sender");
        uint256 id = uint256(_tier);
        uint256 usdPrice = price[uint256(_tier)] * _amount;
        console.log("transferring usdPrice", usdPrice);
        usd.transferFrom(_msgSender(), address(this), usdPrice);

        //during presale the shares are distributed in USD, then in SAFE
        if (!presale) {
            uint256 toSellForSafe = _getTotalShare(usdPrice, priceDistributionOnMint, referralExists ? referralShareForNFTPurchase : 0);
            console.log("transferring toSellForSafe", toSellForSafe);
            uint256 safeAmount = safeToken.buySafeForExactAmountOfUSD(toSellForSafe);
            console.log("safeAmount returned from ", safeAmount);
            uint256 amountDistributed = _distribute(safeToken, safeAmount, priceDistributionOnMint);
            console.log("transferred to protocol wallets", amountDistributed);
            if (referralExists) {
                uint256 referralFee = _transferPercent(safeToken, safeAmount, _referral, referralShareForNFTPurchase);
                console.log("referral fee", referralFee);
                amountDistributed += referralFee;
            }
            console.log("total transferred to wallets", amountDistributed);
        }
        else {
            uint256 toSendToReferral = referralExists ? _transferPercent(usd, usdPrice, _referral, referralShareForNFTPurchase) : 0;
            uint256 toSendToTreasury = !referralExists ? _transferPercent(usd, usdPrice, wallets[uint256(WalletsUsed.Treasury)], referralShareForNFTPurchase) : 0;
            uint256 amountDistributed = _distribute(usd, usdPrice, priceDistributionOnMint);
        }
        uint256 balance = usd.balanceOf(address(this));
        if (balance > 0) {
            safeVault.deposit(balance);
        }
        _mint(_msgSender(), id, _amount, "");
    }

    function distributeProfit(uint256 _amountUSD) public nonReentrant {
        console.log("transferring usdPrice", _amountUSD);
        usd.transferFrom(_msgSender(), address(this), _amountUSD);
        uint256 rewards = _amountUSD / 2;
        uint256 toSellForSafe = _getTotalShare(_amountUSD - rewards, profitDistribution, 0);
        console.log("transferring toSellForSafe", toSellForSafe);
        uint256 safeAmount = safeToken.buySafeForExactAmountOfUSD(toSellForSafe);
        console.log("safeAmount returned from ", safeAmount);
        uint256 amountDistributed = _distribute(safeToken, safeAmount, profitDistribution);
        currentDistributionId++;
        distributionOfProfit[currentDistributionId] = amountDistributed;
        uint256 totalSupplyAllTiers = getTotalSupplyAllTiers();
        for (uint256 i = 0; i < TIERS; i++) {
            uint256 supply = totalSupply(i);
            distributionTotalSupplySnapshot[currentDistributionId][i] = supply;
            distributionByTier[currentDistributionId][i] = rewards * supply / totalSupplyAllTiers;
        }
        uint256 balance = usd.balanceOf(address(this));
        if (balance > 0) {
            safeVault.deposit(balance);
        }
    }

    function claimReward(Tiers _tier, uint256 _distributionId) public nonReentrant {
        address user = _msgSender();
        uint256 reward = getPendingRewards(user, _tier, _distributionId);
        usd.transfer(user, reward);
        alreadyDistributedAmount[_distributionId][uint256(_tier)][user] += reward;
    }

    function claimRewardsTotal() public nonReentrant {
        for (uint256 tier = 0; tier < TIERS; tier++)
            for (uint256 distributionId = 0; distributionId <= currentDistributionId; distributionId++)
                claimReward(Tiers(tier), distributionId);
    }


    /* ============ External and Public View Functions ============ */
    function getBalanceTable(address _user) public view returns (uint256[] memory) {
        uint256[] memory priceTable = new uint256[](TIERS);
        for (uint256 i = 0; i < TIERS; i++) {
            priceTable[i] = balanceOf(_user, i);
        }
        return priceTable;
    }


    function getMyBalanceTable() public view returns (uint256[] memory) {
        address user = _msgSender();
        return getBalanceTable(user);
    }

    function getPriceTable() public view returns (uint256[] memory) {
        uint256[] memory priceTable = new uint256[](TIERS);
        for (uint256 i = 0; i < TIERS; i++) {
            priceTable[i] = price[i];
        }
        return priceTable;
    }

    function getFairPriceTable() public view returns (uint256[] memory) {
        uint256[] memory priceTable = new uint256[](TIERS);
        for (uint256 i = 0; i < TIERS; i++) {
            priceTable[i] = getFairPrice(Tiers(i));
        }
        return priceTable;
    }

    function getPrice(Tiers _tier) public view returns (uint256) {
        return price[uint256(_tier)];
    }

    function getFairPrice(Tiers _tier) public view returns (uint256) {
        return price[uint256(_tier)] + distributionByTier[currentDistributionId][uint256(_tier)] / (totalSupply(uint256(_tier)) == 0 ? 1 : totalSupply(uint256(_tier)));
    }

    function getTotalSupplyAllTiers() public view returns (uint256) {
        uint256 totalSupply_ = 0;
        for (uint256 i = 0; i < TIERS; i++) {
            totalSupply_ += totalSupply(i);
        }
        return totalSupply_;
    }


    function getMyPendingRewardsTotal() public view returns (uint256) {
        address user = _msgSender();
        uint256 rewards = 0;
        for (uint256 tier = 0; tier < TIERS; tier++)
            for (uint256 distributionId = 0; distributionId <= currentDistributionId; distributionId++)
                rewards += getPendingRewards(user, Tiers(tier), distributionId);
        return rewards;
    }

    function getPendingRewards(address _user, Tiers _tier, uint256 _distributionId) public view returns (uint256) {
        uint256 tier = uint256(_tier);
        uint256 rewardsForTier = distributionByTier[currentDistributionId][tier];
        // user's rewards is the % of the total rewards for the tier
        uint256 rewardsForBalance = totalSupply(tier) == 0 ? 0 : rewardsForTier * balanceOf(_user, tier) / totalSupply(tier);
        return rewardsForBalance - alreadyDistributedAmount[_distributionId][tier][_user];
    }

    function getUnclaimedRewards() public view returns (uint256) {
        uint undistributed = 0;
        for (uint256 i = 0; i < TIERS; i++)
            for (uint256 distributionId = 0; distributionId <= currentDistributionId; distributionId++)
                undistributed += distributionByTier[distributionId][i] - alreadyDistributedAmountByTier[distributionId][i];
        return undistributed;

    }

    function getTreasuryCost() public view returns (uint256) {
        return usd.balanceOf(wallets[uint256(WalletsUsed.Treasury)]) + safeToken.balanceOf(wallets[uint256(WalletsUsed.Treasury)]) * safeToken.price() / 1e6;
    }

    function getMyShareOfTreasury() public view returns (uint256) {
        address user = _msgSender();
        uint treasuryShare = 0;
        for (uint256 tier = 0; tier < TIERS; tier++)
            treasuryShare += balanceOf(user, tier) * price[tier];
        uint256 treasuryCost = getTreasuryCost();
        return (treasuryCost == 0) ? 0 : treasuryShare / treasuryCost;
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
