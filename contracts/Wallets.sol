// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wallets {
    /// @dev precision constant, stands as 100%
    uint256 public constant HUNDRED_PERCENT = 100_000_000;

    /// @notice total wallets on the protocol less vault, see Wallets enum, this can be basically any number
    /// @dev this is used for the loop in the distribution function, vault gets the rest
    uint256 public constant WALLETS = 2;

    // @notice token wallets configuration
    address[WALLETS] public wallets;

    /// @notice protocol wallets for easy enumeration,
    /// @dev the order is extremely important once deployed, see configuration scripts, rewards distribution is the balance of SafeNFT,
    enum WalletsUsed {
        Treasury,
        Management
    }

    function _setWallets(address[WALLETS] memory _wallets) internal {
        wallets = _wallets;
    }

    /// @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    /// @dev walletPercentageDistribution is intentionally storage since this is called from the child contract to avoid unnecessary copy to memory
    /// @dev walletPercentageDistribution has different meaning in the child contracts, but always the same length and kept in storage
    function _distribute(IERC20 _paymentToken, uint256 _amount, uint256[WALLETS] storage walletPercentageDistribution) internal returns (uint256) {
        uint256 amountPaid = 0;

        for (uint256 i = 0; i < WALLETS; i++) {
            uint256 amount = (_amount * walletPercentageDistribution[i]) / HUNDRED_PERCENT;
            _paymentToken.transfer(wallets[i], amount);
            amountPaid += amount;
        }
        return amountPaid;
    }

    // @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    function _transferPercent(IERC20 _paymentToken, uint256 _amount, address _receiver, uint256 _percent) internal returns (uint256) {
        uint256 balance = _paymentToken.balanceOf(address(this));
        uint256 amount = (_amount * _percent) / HUNDRED_PERCENT;
        require(balance >= amount, "Not enough balance on the contract");
        _paymentToken.transfer(_receiver, amount);
        return amount;
    }

    function _getTotalShare(uint256 _amount, uint256[WALLETS] storage _walletPercentageDistribution, uint256 _extraShare) internal view returns (uint256) {
        uint256 totalPercentage = 0;
        //reducing sload calls
        uint256 WALLETS = WALLETS;
        for (uint256 i = 0; i < WALLETS; i++) {
            totalPercentage += _walletPercentageDistribution[i];
        }
        totalPercentage += _extraShare;
        return _amount * totalPercentage / HUNDRED_PERCENT;
    }

    /// @dev this is getting the owner from the proxy contract, the proxy contract is ERC-173 compliant and support transferOnwership
    /// @dev service function used by children contracts which are at least SafeVault.sol and SafeToken.sol
    function _getOwner() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}
