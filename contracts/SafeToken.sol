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
    uint256 public constant buyTaxPercentage = 25;
    uint256 public constant sellTaxPercentage = 25;

    // @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    uint256 public constant liquidityPoolDistribution = 5000;
    uint256 public constant investmentPoolDistribution = 2950;
    uint256 public constant managementDistribution = 2000;
    uint256 public constant referralProgramDistribution = 50;

    uint256 constant HUNDRED_PERCENT = 10000;

    // @notice Project wallets
    address public liquidityPoolAddress;
    address public investmentPoolAddress;
    address public managementAddress;
    address public referralProgramAddress;

    IERC20 public usdToken;
    ISafeVault public vault;

    /* ============ Modifiers ============ */

    modifier auth() {
        require(admin[_msgSender()] == 1, "SafeToken:not-authorized");
        _;
    }

    /* ============ Changing State Functions ============ */

    function initialize(address _usdToken, address _vault, address _liquidityPoolAddress, address _investmentPoolAddress, address _managementAddress, address _referralProgramAddress) public proxied {
        admin[_msgSender()] = 1;
        vault = ISafeVault(_vault);
        usdToken = IERC20(_usdToken);
        investmentPoolAddress = _investmentPoolAddress;
        liquidityPoolAddress = _liquidityPoolAddress;
        managementAddress = _managementAddress;
        referralProgramAddress = _referralProgramAddress;
        usdToken.approve(address(this), type(uint256).max);
    }

    constructor(address _usdToken, address _vault, address _liquidityPoolAddress, address _investmentPoolAddress, address _managementAddress, address _referralProgramAddress)  {
        initialize(_usdToken, _vault, _liquidityPoolAddress, _investmentPoolAddress, _managementAddress, _referralProgramAddress);
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

    function buy(uint256 _amount) public payable {
        uint256 tax = _amount * buyTaxPercentage / HUNDRED_PERCENT;
        uint256 amount = _amount - tax;
        uint256 safeAmount = amount * price();
        _mint(_msgSender(), safeAmount);

        IERC20(usdToken).transferFrom(_msgSender(), address(this), _amount);
        IERC20(usdToken).transferFrom(address(this), liquidityPoolAddress, tax * liquidityPoolDistribution / HUNDRED_PERCENT);
        IERC20(usdToken).transferFrom(address(this), investmentPoolAddress, tax * investmentPoolDistribution / HUNDRED_PERCENT);
        IERC20(usdToken).transferFrom(address(this), managementAddress, tax * managementDistribution / HUNDRED_PERCENT);
        IERC20(usdToken).transferFrom(address(this), referralProgramAddress, tax * referralProgramDistribution / HUNDRED_PERCENT);
    }

    function sell(uint256 amount) public {
        payable(msg.sender).transfer(amount * price());
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
        return usdToken.balanceOf(address(this)) + vault.totalSupply();
    }

    function price() public view returns (uint256) {
        return getUsdReserves() / totalSupply;
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
