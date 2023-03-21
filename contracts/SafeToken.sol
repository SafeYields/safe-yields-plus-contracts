// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./interfaces/ISafeToken.sol";
import "./interfaces/ISafeVault.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./Wallets.sol";

/// @title  SafeToken
/// @author crypt0grapher
/// @notice This contract is used as a token
contract SafeToken is Wallets, ISafeToken, Proxied, Pausable, ReentrancyGuard {
    // @notice ERC20 token data
    string public constant name = "Safe Yields Token";
    string public constant symbol = "SAFE";
    string public constant version = "1";
    uint8 public constant decimals = 6;

    // @notice Total supply of the token
    uint256 public totalSupply;

    // @notice Blacklisted addresses
    mapping(address => bool) public blacklist;

    // @notice Admins list
    mapping(address => uint256) public admin;

    // @notice Balances of each user
    mapping(address => uint256) public balanceOf;

    // @notice Approved allowances
    mapping(address => mapping(address => uint256)) public allowance;

    // @notice Taxes, multiplied by 10000, (25 stands for 0.25%)
    uint256 public BUY_TAX_PERCENT;
    uint256 public SELL_TAX_PERCENT;

    // @notice core protocol addresses
    IERC20 public usd;
    ISafeVault public safeVault;

    // @notice tax distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    uint256[WALLETS] public taxDistributionOnMintAndBurn;

    /* ============ Modifiers ============ */

    modifier auth() {
        require(admin[_msgSender()] == 1, "SafeToken:not-authorized");
        _;
    }

    /* ============ Changing State Functions ============ */

    function initialize(address _usdToken, address _safeVault, address[WALLETS] memory _wallets, uint256[WALLETS] memory _taxDistributionOnMintAndBurn, uint256 _buyTaxPercent, uint256 _sellTaxPercent) public proxied {
        admin[_msgSender()] = 1;
        safeVault = ISafeVault(_safeVault);
        usd = IERC20(_usdToken);
        _setWallets(_wallets);
        taxDistributionOnMintAndBurn = _taxDistributionOnMintAndBurn;
        BUY_TAX_PERCENT = _buyTaxPercent;
        SELL_TAX_PERCENT = _sellTaxPercent;
        usd.approve(address(safeVault), type(uint256).max);
    }

    constructor(address _usdToken, address _safeVault, address[WALLETS] memory _wallets, uint256[WALLETS] memory _taxDistributionOnMintAndBurn, uint256 _buyTaxPercent, uint256 _sellTaxPercent)  {
        initialize(_usdToken, _safeVault, _wallets, _taxDistributionOnMintAndBurn, _buyTaxPercent, _sellTaxPercent);
    }

    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(_msgSender(), dst, wad);
    }

    function getWallets() external view returns (address[WALLETS] memory) {
        return wallets;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) public nonReentrant returns (bool) {
        require(!paused(), "SafeToken:paused");
        require(admin[src] == 1 || admin[dst] == 1, "SafeToken: transfer-prohibited");
        require(balanceOf[src] >= amt, "SafeToken:insufficient-balance");
        require(!blacklist[src] && !blacklist[dst], "SafeToken:blacklisted");
        require(dst != address(0) && src != address(0), "SafeToken:zero-address");
        if (src != _msgSender()) {
            require(allowance[src][_msgSender()] >= amt, "SafeToken:insufficient-allowance");
            allowance[src][_msgSender()] -= amt;
        }
        balanceOf[src] -= amt;
        balanceOf[dst] += amt;
        emit Transfer(src, dst, amt);
        return true;
    }


    function mint(address _user, uint256 _amount) external auth {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external auth {
        _burn(_user, _amount);
    }


    function buySafeForExactAmountOfUSD(uint256 _usdToSpend) public nonReentrant returns (uint256) {
        uint256 usdTax = _usdToSpend * BUY_TAX_PERCENT / HUNDRED_PERCENT;
        uint256 usdToSwapForSafe = _usdToSpend - usdTax;
        uint256 safeTokensToBuy = (usdToSwapForSafe * 1e6) / price();
        _mint(_msgSender(), safeTokensToBuy);
        bool success = usd.transferFrom(_msgSender(), address(this), _usdToSpend);
        require(success, "SafeToken:transfer-failed");
        uint256 paid = _distribute(usd, usdTax, taxDistributionOnMintAndBurn);
        safeVault.deposit(usdToSwapForSafe + usdTax - paid);
        return usdToSwapForSafe + usdTax;
    }

    function buyExactAmountOfSafe(uint256 _safeTokensToBuy) public nonReentrant {
        uint256 usdPriceOfTokensToBuy = _safeTokensToBuy * price() / 1e6;
        uint256 usdTax = usdPriceOfTokensToBuy * BUY_TAX_PERCENT / HUNDRED_PERCENT;
        uint256 usdToSpend = usdPriceOfTokensToBuy + usdTax;
        _mint(_msgSender(), _safeTokensToBuy);
        bool success = usd.transferFrom(_msgSender(), address(this), usdToSpend);
        require(success, "SafeToken:transfer-failed");
        uint256 paid = _distribute(usd, usdTax, taxDistributionOnMintAndBurn);
        // depositing the rest to the vault, this also saves gas for one SSTORE operation
        if (usdToSpend - paid > 0) {
            safeVault.deposit(usdToSpend - paid);
        }
    }

    function estimateBuyExactAmountOfSafe(uint256 _safeTokensToBuy) public {
    }

    function sellExactAmountOfSafe(uint256 _safeTokensToSell) public nonReentrant {
        uint256 usdPriceOfTokensToSell = _safeTokensToSell * price() / 1e6;
        uint256 usdTax = usdPriceOfTokensToSell * SELL_TAX_PERCENT / HUNDRED_PERCENT;
        uint256 usdToReturn = usdPriceOfTokensToSell - usdTax;
        _burn(_msgSender(), _safeTokensToSell);
        safeVault.withdraw(_msgSender(), usdToReturn);
        safeVault.withdraw(address(this), usdTax);
        uint256 paid = _distribute(usd, usdTax, taxDistributionOnMintAndBurn);
        if (usdTax - paid > 0) {
            safeVault.deposit(usdTax - paid);
        }
    }

    function sellSafeForExactAmountOfUSD(uint256 _usdToPayToUser) public nonReentrant {
        uint256 usdTax = _usdToPayToUser * SELL_TAX_PERCENT / (HUNDRED_PERCENT - SELL_TAX_PERCENT);
        uint256 usdPriceWithTax = _usdToPayToUser + usdTax;
        uint256 safeTokensToBurn = (usdPriceWithTax * 1e6) / price();
        _burn(_msgSender(), safeTokensToBurn);
        safeVault.withdraw(_msgSender(), _usdToPayToUser);
        safeVault.withdraw(address(this), usdTax);
        uint256 paid = _distribute(usd, usdTax, taxDistributionOnMintAndBurn);
        if (usdTax - paid > 0)
            safeVault.deposit(usdTax - paid);
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[_msgSender()][usr] = wad;
        emit Approval(_msgSender(), usr, wad);
        return true;
    }

    // @notice Grant access
    // @param guy admin to grant auth
    function rely(address guy) external auth {
        admin[guy] = 1;
    }

    // @notice Deny access
    // @param guy deny auth for
    function deny(address guy) external auth {
        admin[guy] = 0;
    }

    function pause() external auth {
        _pause();
    }

    function unpause() external auth {
        _unpause();
    }

    /* ============ View Functions ============ */

    function getUsdReserves() public view returns (uint256) {
        return safeVault.totalSupply();
    }

    function price() public view returns (uint256) {
        return (totalSupply == 0) ? 1e6 : getUsdReserves() * 1e6 / totalSupply;
    }

    /* ============ Internal Functions ============ */

    function _mint(address usr, uint256 amount) internal {
        balanceOf[usr] += amount;
        totalSupply += amount;
        emit Transfer(address(0), usr, amount);
    }

    function _burn(address usr, uint256 amount) internal {
        require(balanceOf[usr] >= amount, "SafeToken:insufficient-balance");
        address sender = _msgSender();
        if (admin[sender] == 0 && usr != _msgSender() && allowance[usr][sender] != type(uint256).max) {
            require(allowance[usr][_msgSender()] >= amount, "SafeToken:insufficient-allowance");
            allowance[usr][sender] -= amount;
        }
        balanceOf[usr] -= amount;
        totalSupply -= amount;
        emit Transfer(usr, address(0), amount);
    }

}
