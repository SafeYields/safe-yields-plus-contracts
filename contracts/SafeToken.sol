// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/extensions/AccessControlEnumerable.sol";

/// @title  SafeToken
/// @author crypt0grapher
/// @notice This contract is used as a token
contract SafeToken is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {

}
