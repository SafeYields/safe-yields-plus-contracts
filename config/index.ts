import { toWei } from '@utils/output.helper';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

export const PERCENTAGE_PRECISION_MULTIPLIER = 100;
export const percent = (value: number) => value * PERCENTAGE_PRECISION_MULTIPLIER;
export const HUNDRED_PERCENT = percent(100);

export enum Wallets {
  LiquidityPool,
  InvestmentPool,
  Management,
  referralProgram,
}

export const wallets = async (hre: HardhatRuntimeEnvironment): Promise<string[]> => {
  const { liquidity, investments, management, referrals } = await hre.getNamedAccounts();
  return [liquidity, investments, management, referrals];
};

export const taxDistributionForSafeToken = [percent(50), percent(29.5), percent(2), percent(0.5)];
export const costDistributionForNFT = [percent(5), percent(70), percent(20), percent(5)];

export enum Tiers {
  Tier1,
  Tier2,
  Tier3,
  Tier4,
}

export const tierPriceNFT = [toWei(131.25), toWei(262.5), toWei(525), toWei(1050)];
export const tierSupplyNFT = [2000, 1000, 1000, 1000];
