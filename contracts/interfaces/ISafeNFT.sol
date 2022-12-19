// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


/// @title  ISafeVault
/// @author crypt0grapher
/// @notice Safe Yield Vault depositing to the third-party yield farms
interface ISafeNFT is IERC1155 {
    enum Tiers {Tier1, Tier2, Tier3, Tier4}

    /**
    *   @notice purchase Safe NFT for exact amount of USD
    *   @param _tier tier of the NFT to purchase which stands for ERC1155 token id [0..3]
    *   @param _amount amount of USD to spend
    */
    function buy(Tiers _tier, uint256 _amount) external;

    /**
    *   @notice distribute profit among the NFT holders, the function just fixes the amount of the reward currently deposited to the
    *   @param _amountUSD amount of USD to distribute
    */
    function distributeRewards(uint256 _amountUSD) external;

    /**
    *   @notice claims NFT rewards for the caller of the function
    */
    function claimReward() external;

    /**
    *   @notice returns the amount of the reward share for the NFT holder
    */
    function pendingRewards() external returns (uint256);

    /**
    *   @notice gets the share of the NFTs of the caller to the treasury
    */
    function percentOfTreasury() external returns (uint256);

}
