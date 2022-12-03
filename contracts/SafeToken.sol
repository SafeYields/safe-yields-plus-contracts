// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

/// @title  SafeToken
/// @author crypt0grapher
/// @notice This contract is used as a token
contract SafeToken is Proxied, Pausable, IERC20, IERC20Metadata {
    string public name = "Safe Yields Token";
    string public symbol = "SAFE";
    string public constant version = "1";
    uint8 public decimals = 18;
    // @dev totalSupply is the total number of tokens in existence, we start with zero
    uint256 public totalSupply = 0;
    mapping(address => bool) public blacklist;
    mapping(address => uint256) private _balances;

    // @notice Admins list
    mapping(address => uint256) public wards;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    modifier auth() {
        require(wards[_msgSender()] == 1, "SafeToken:not-authorized");
        _;
    }

    function initialize() public proxied {
        wards[_msgSender()] = 1;
    }

    constructor() public {
        initialize();
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


    function mint(address usr, uint256 wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }

    function burn(address usr, uint256 wad) external auth {
        require(balanceOf[usr] >= wad, "SafeToken:insufficient-balance");
        if (usr != _msgSender() && allowance[usr][_msgSender()] != type(uint256).max) {
            require(allowance[usr][_msgSender()] >= wad, "SafeToken:insufficient-allowance");
            allowance[usr][_msgSender()] = sub(allowance[usr][_msgSender()], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[_msgSender()][usr] = wad;
        emit Approval(_msgSender(), usr, wad);
        return true;
    }

    // @notice Grant access
    // @param guy admin to grant auth
    function rely(address guy) external auth {
        wards[guy] = 1;
    }

    // @notice Deny access
    // @param guy deny auth for
    function deny(address guy) external auth {
        wards[guy] = 0;
    }


    /* ============ Internal Functions ============ */

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }


}
