// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title  ISafeToken
/// @author crypt0grapher
/// @notice This contract is used as a token
interface ISafeToken is IERC20, IERC20Metadata {

    /**
    *   @notice buySafeForExactAmountOfUSD Safe Yield tokens with BUSD
    *   @param _usdToSpend number of tokens to buy, the respective amount of BUSD will be deducted from the user, Safe Yield token will be minted
    */
    function buySafeForExactAmountOfUSD(uint256 _usdToSpend) external;

    function buyExactAmountOfSafe(uint256 _safeTokensToBuy) external;

    /**
    *   @notice sell Safe Yield tokens for BUSD
    *   @param _safeTokensToSell number of tokens to sell, the respective amount of BUSD will be returned from the user, Safe Yield token will be burned
    */
    function sell(uint256 _safeTokensToSell) external;

    function mint(address usr, uint256 wad) external;

    function burn(address usr, uint256 wad) external;

    function getWallets() external view returns (address[3] memory);

    /**
    *   @notice price of 1 Safe Yield token in StableCoin
    */
    function usd() external view returns (IERC20);

    /**
    *   @notice price of 1 Safe Yield token in StableCoin
    */
    function price() external view returns (uint256);
}
