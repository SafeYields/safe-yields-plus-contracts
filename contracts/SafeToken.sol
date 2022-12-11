// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./interfaces/ISafeToken.sol";
import "./interfaces/ISafeVault.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

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
    uint256 public constant WALLETS = 4;

    /// @notice protocol wallets for easy enumeration,
    /// @dev the order is extremely important once deployed, see configuration scripts
    // rewards distribution is the balance of SafeNFT,
    enum Wallets {
        LiquidityPool,
        InvestmentPool,
        Management,
        referralProgram
    }

    // @notice token wallets configuration
    address[WALLETS] wallets;

    // @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    uint256[WALLETS] public taxDistributionOnMint;

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

    function initialize(address _usdToken, address _safeVault, address[WALLETS] memory _wallets, uint256[WALLETS] memory _taxDistributionOnMint) public proxied {
        admin[_msgSender()] = 1;
        safeVault = ISafeVault(_safeVault);
        usd = IERC20(_usdToken);
        wallets = _wallets;
        taxDistributionOnMint = _taxDistributionOnMint;
        usd.approve(address(safeVault), type(uint256).max);
    }

    constructor(address _usdToken, address _safeVault, address[WALLETS] memory _wallets, uint256[WALLETS] memory _taxDistributionOnMint)  {
        initialize(_usdToken, _safeVault, _wallets, _taxDistributionOnMint);
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

    function buy(uint256 _safeTokensToBuy) public {
        uint256 usdPriceOfTokensToBuy = _safeTokensToBuy * price();
        uint256 usdTax = usdPriceOfTokensToBuy * BUY_TAX_PERCENT / HUNDRED_PERCENT;
        uint256 usdToSpend = usdPriceOfTokensToBuy + usdTax;
        _mint(_msgSender(), _safeTokensToBuy);

        usd.transferFrom(_msgSender(), address(this), usdToSpend);
        safeVault.deposit(address(this), usdPriceOfTokensToBuy);
        for (uint256 i = 0; i < WALLETS; i++) {
            usd.transfer(wallets[i], usdTax * taxDistributionOnMint[i] / HUNDRED_PERCENT);
        }

    }

    function sell(uint256 _safeTokensToSell) public {
        uint256 usdPriceOfTokensToSell = _safeTokensToSell * price();
        uint256 usdTax = usdPriceOfTokensToSell * BUY_TAX_PERCENT / HUNDRED_PERCENT;
        uint256 usdToSpend = usdPriceOfTokensToSell + usdTax;
        _burn(_msgSender(), _safeTokensToSell);
        safeVault.withdraw(_msgSender(), usdPriceOfTokensToSell);
        safeVault.withdraw(address(this), usdTax);
        for (uint256 i = 0; i < WALLETS; i++) {
            usd.transfer(wallets[i], usdTax * taxDistributionOnMint[i] / HUNDRED_PERCENT);
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
        return usd.balanceOf(address(this)) + safeVault.totalSupply();
    }

    function price() public view returns (uint256) {
        return getUsdReserves() / totalSupply;
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
