// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./interfaces/ISafeToken.sol";
import "./interfaces/ISafeVault.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "hardhat/console.sol";

/// @title  SafeToken
/// @author crypt0grapher
/// @notice This contract is used as a token
contract SafeToken is ISafeToken, Proxied, Pausable {
    // @notice ERC20 token data
    string public constant name = "Safe Yields Token";
    string public constant symbol = "SAFE";
    string public constant version = "1";
    uint8 public constant decimals = 18;

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
    uint256 public constant BUY_TAX_PERCENT = 25;
    uint256 public constant SELL_TAX_PERCENT = 25;

    /// @dev total wallets on the protocol, see Wallets enum
    uint256 public constant WALLETS = 3;

    /// @notice protocol wallets for easy enumeration,
    /// @dev the order is extremely important once deployed, see configuration scripts
    // rewards distribution is the balance of SafeNFT,
    enum Wallets {
        LiquidityPool,
        InvestmentPool,
        Management
    }

    // @notice token wallets configuration
    address[WALLETS] wallets;

    // @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    uint256[WALLETS] public taxDistributionOnMintAndBurn;

    uint256 constant HUNDRED_PERCENT = 10000;

    // @notice core protocol addresses
    IERC20 public usd;
    ISafeVault public safeVault;

    /* ============ Modifiers ============ */

    modifier auth() {
        require(admin[_msgSender()] == 1, "SafeToken:not-authorized");
        _;
    }

    /* ============ Changing State Functions ============ */

    function initialize(address _usdToken, address _safeVault, address[WALLETS] memory _wallets, uint256[WALLETS] memory _taxDistributionOnMintAndBurn) public proxied {
        admin[_msgSender()] = 1;
        safeVault = ISafeVault(_safeVault);
        usd = IERC20(_usdToken);
        wallets = _wallets;
        taxDistributionOnMintAndBurn = _taxDistributionOnMintAndBurn;
        usd.approve(address(safeVault), type(uint256).max);
    }

    constructor(address _usdToken, address _safeVault, address[WALLETS] memory _wallets, uint256[WALLETS] memory _taxDistributionOnMintAndBurn)  {
        initialize(_usdToken, _safeVault, _wallets, _taxDistributionOnMintAndBurn);
    }

    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(_msgSender(), dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(!paused(), "SafeToken:paused");
        require(src == address(0) || dst == address(0), "SafeToken:transfer-prohibited");
        require(balanceOf[src] >= wad, "SafeToken:insufficient-balance");
        require(!blacklist[src] && !blacklist[dst], "SafeToken:blacklisted");
        if (src != _msgSender()) {
            require(allowance[src][_msgSender()] >= wad, "SafeToken:insufficient-allowance");
            allowance[src][_msgSender()] = sub(allowance[src][_msgSender()], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }


    function mint(address _user, uint256 _amount) external auth {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external auth {
        _burn(_user, _amount);
    }

    // for _usdToSpend amount buy safeTokensToBuy SAFE
    // _usdToSpend = usdToSwapForSafe + usdTax
    // usdTax = usdToSwapForSafe * buyTax
    // safeTokensToBuy = usdToSwapForSafe / price();
    function buySafeForExactAmountOfUSD(uint256 _usdToSpend) public {
        console.log("buySafeForExactAmountOfUSD, _usdToSpend: %s", _usdToSpend);
        console.log("_msgSender(): %s", _msgSender());
        console.log("usd: %s", address(usd));
        uint256 usdToSwapForSafe = _usdToSpend * (HUNDRED_PERCENT - BUY_TAX_PERCENT) / HUNDRED_PERCENT;
        uint256 usdTax = usdToSwapForSafe * BUY_TAX_PERCENT / HUNDRED_PERCENT;
        console.log("usdTax", usdTax);
        uint256 safeTokensToBuy = (usdToSwapForSafe * 1e18) / price();
        console.log("safeTokensToBuy", safeTokensToBuy);
        _mint(_msgSender(), safeTokensToBuy);
        usd.transferFrom(_msgSender(), address(this), _usdToSpend);
        safeVault.deposit(address(this), usdToSwapForSafe);
        for (uint256 i = 0; i < WALLETS; i++) {
            usd.transfer(wallets[i], usdTax * taxDistributionOnMintAndBurn[i] / HUNDRED_PERCENT);
        }
    }

    // Buy SAFE for BUSD
    // BUSD = SAFE * price() * 100.25%
    // tax = BUSD * 0.25%
    function buyExactAmountOfSafe(uint256 _safeTokensToBuy) public {
        console.log("buyExactAmountOfSafe");
        uint256 usdPriceOfTokensToBuy = _safeTokensToBuy * price();
        console.log("usdPriceOfTokensToBuy", usdPriceOfTokensToBuy);
        uint256 usdTax = usdPriceOfTokensToBuy * BUY_TAX_PERCENT / HUNDRED_PERCENT;
        console.log("usdTax", usdTax);
        uint256 usdToSpend = usdPriceOfTokensToBuy + usdTax;
        console.log("usdToSpend", usdToSpend);
        _mint(_msgSender(), _safeTokensToBuy);
        usd.transferFrom(_msgSender(), address(this), usdToSpend);
        safeVault.deposit(address(this), usdPriceOfTokensToBuy);
        for (uint256 i = 0; i < WALLETS; i++) {
            usd.transfer(wallets[i], usdTax * taxDistributionOnMintAndBurn[i] / HUNDRED_PERCENT);
        }
    }

    function estimatBuyExactAmountOfSafe(uint256 _safeTokensToBuy) public {
    }

    function sell(uint256 _safeTokensToSell) public {
        uint256 usdPriceOfTokensToSell = _safeTokensToSell * price() / 1e18;
        uint256 usdTax = usdPriceOfTokensToSell * BUY_TAX_PERCENT / HUNDRED_PERCENT;
        uint256 usdToSpend = usdPriceOfTokensToSell + usdTax;
        _burn(_msgSender(), _safeTokensToSell);
        safeVault.withdraw(_msgSender(), usdPriceOfTokensToSell);
        safeVault.withdraw(address(this), usdTax);
        for (uint256 i = 0; i < WALLETS; i++) {
            usd.transfer(wallets[i], usdTax * taxDistributionOnMintAndBurn[i] / HUNDRED_PERCENT);
        }
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


    /* ============ View Functions ============ */

    function getUsdReserves() public view returns (uint256) {
        return safeVault.totalSupply();
    }

    function price() public view returns (uint256) {
        return (totalSupply == 0) ? 1e18 : getUsdReserves() * 1e18 / totalSupply;
    }

    function getWallets() public view returns (address[WALLETS] memory) {
        return wallets;
    }

    /* ============ Internal Functions ============ */

    function _mint(address usr, uint256 wad) internal {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }

    function _burn(address usr, uint256 wad) internal {
        require(balanceOf[usr] >= wad, "SafeToken:insufficient-balance");
        if (usr != _msgSender() && allowance[usr][_msgSender()] != type(uint256).max) {
            require(allowance[usr][_msgSender()] >= wad, "SafeToken:insufficient-allowance");
            allowance[usr][_msgSender()] = sub(allowance[usr][_msgSender()], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }


}
