// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./interfaces/ISafeToken.sol";
import "./interfaces/ISafeVault.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./Wallets.sol";
import "./Owned.sol";

/// @title  SafeToken
/// @author crypt0grapher
/// @notice This contract is used as a token for the SafeYields protocol
contract SafeToken is ISafeToken, Owned, Wallets, Proxied, Pausable, ReentrancyGuard {
    // @notice ERC20 token data
    string public constant name = "Safe Yields Token";
    string public constant symbol = "SAFE";
    string public constant version = "1";
    uint8 public constant decimals = 6;

    /// @notice Total supply of the token, the ratio of totalSupply of the vault by the totalSupply of the Safe Token defines the price of the token
    uint256 public totalSupply;

    /// @notice Whitelisted addresses for transfers, contains protocol contracts and selected partners
    /// @dev if not included into the list, transfer is prohibited
    mapping(address => bool) public whitelist;

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
        require(_msgSender() == _getOwner(), "SafeToken:not-authorized");
        _;
    }

    /* ============ Changing State Functions ============ */

    /// @dev this one is called by the proxy
    function initialize(address _usdToken, address _safeVault, address[WALLETS] memory _wallets, uint256[WALLETS] memory _taxDistributionOnMintAndBurn, uint256 _buyTaxPercent, uint256 _sellTaxPercent) public proxied {
        whitelist[_msgSender()] = true;
        safeVault = ISafeVault(_safeVault);
        usd = IERC20(_usdToken);
        _setWallets(_wallets);
        taxDistributionOnMintAndBurn = _taxDistributionOnMintAndBurn;
        BUY_TAX_PERCENT = _buyTaxPercent;
        SELL_TAX_PERCENT = _sellTaxPercent;
        usd.approve(address(safeVault), type(uint256).max);
    }

    constructor(address _usdToken, address _safeVault, address[WALLETS] memory _wallets, uint256[WALLETS] memory _taxDistributionOnMintAndBurn, uint256 _buyTaxPercent, uint256 _sellTaxPercent )  {
        initialize(_usdToken, _safeVault, _wallets, _taxDistributionOnMintAndBurn, _buyTaxPercent, _sellTaxPercent);
    }

    function transfer(address dst, uint256 amt) external returns (bool) {
        return transferFrom(_msgSender(), dst, amt);
    }

    function getWallets() external view returns (address[WALLETS] memory) {
        return wallets;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) public nonReentrant returns (bool) {
        address sender = _msgSender();
        address admin = _getOwner();
        require(!paused(), "SafeToken:paused");
        require(whitelist[src] == true || whitelist[dst] == true || admin == sender, "SafeToken: transfer-prohibited");
        require(balanceOf[src] >= amt, "SafeToken:insufficient-balance");
        require(dst != address(0) && src != address(0), "SafeToken:zero-address");
        if (src != sender && sender != admin) {
            require(allowance[src][sender] >= amt, "SafeToken:insufficient-allowance");
            allowance[src][sender] -= amt;
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
        // that's for compatibility, usually if the transfer fails, it reverts but that's not the obligation of ERC20
        require(success, "SafeToken:transfer-failed");
        // distributing to wallets (if any, currently it's treasury and management)
        // it's not 100% in total, although could be the case
        uint256 paid = _distribute(usd, usdTax, taxDistributionOnMintAndBurn);
        safeVault.deposit(usdToSwapForSafe + usdTax - paid);
        return safeTokensToBuy;
    }

    function buyExactAmountOfSafe(uint256 _safeTokensToBuy) public nonReentrant {
        uint256 usdPriceOfTokensToBuy = _safeTokensToBuy * price() / 1e6;
        uint256 usdTax = usdPriceOfTokensToBuy * BUY_TAX_PERCENT / HUNDRED_PERCENT;
        uint256 usdToSpend = usdPriceOfTokensToBuy + usdTax;
        _mint(_msgSender(), _safeTokensToBuy);
        bool success = usd.transferFrom(_msgSender(), address(this), usdToSpend);
        require(success, "SafeToken:transfer-failed");
        uint256 paid = _distribute(usd, usdTax, taxDistributionOnMintAndBurn);
        if (usdToSpend - paid > 0) {
            safeVault.deposit(usdToSpend - paid);
        }
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
        uint256 usdTax = _usdToPayToUser * SELL_TAX_PERCENT / HUNDRED_PERCENT;
        uint256 usdPriceWithTax = _usdToPayToUser + usdTax;
        uint256 safeTokensToBurn = (usdPriceWithTax * 1e6) / price();
        _burn(_msgSender(), safeTokensToBurn);
        safeVault.withdraw(_msgSender(), _usdToPayToUser);
        safeVault.withdraw(address(this), usdTax);
        uint256 paid = _distribute(usd, usdTax, taxDistributionOnMintAndBurn);
        if (usdTax - paid > 0)
            safeVault.deposit(usdTax - paid);
    }

    function approve(address usr, uint256 amt) external returns (bool) {
        allowance[_msgSender()][usr] = amt;
        emit Approval(_msgSender(), usr, amt);
        return true;
    }

    function whitelistAdd(address guy) external auth {
        whitelist[guy] = true;
    }

    function whiteListRemove(address guy) external auth {
        whitelist[guy] = false;
    }

    function pause() external auth {
        _pause();
    }

    function unpause() external auth {
        _unpause();
    }

    /* ============ View Functions ============ */

    /// @dev this is intentional that not deposited() is used, because the total amount of USD in the vault is used to calculate the price
    function getUsdReserves() public view returns (uint256) {
        return safeVault.totalSupply();
    }

    /// @dev the key is the price is usd reserves, so not only user deposits from safe purchase, but also injections from the NFT purchase and treasury if needed
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
        if (_getOwner() != sender && usr != sender && allowance[usr][sender] != type(uint256).max) {
            require(allowance[usr][sender] >= amount, "SafeToken:insufficient-allowance");
            allowance[usr][sender] -= amount;
        }
        balanceOf[usr] -= amount;
        totalSupply -= amount;
        emit Transfer(usr, address(0), amount);
    }

}
