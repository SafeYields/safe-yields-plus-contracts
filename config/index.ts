import { toWei } from '@utils/output.helper';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

export const PERCENTAGE_PRECISION_MULTIPLIER = 100;
export const percent = (value: number) => value * PERCENTAGE_PRECISION_MULTIPLIER;
export const HUNDRED_PERCENT = percent(10000);

export enum Wallets {
  LiquidityPool,
  InvestmentPool,
  Management,
}

export const wallets = async (hre: HardhatRuntimeEnvironment): Promise<string[]> => {
  const { liquidity, investments, management } = await hre.getNamedAccounts();
  return [liquidity, investments, management];
};

export const taxDistributionForSafeToken = [percent(50), percent(30), percent(20)];
export const costDistributionForNFT = [percent(5), percent(75), percent(20)];

export enum Tiers {
  Tier1,
  Tier2,
  Tier3,
  Tier4,
}

export const tierPriceNFT = [toWei(131.25), toWei(262.5), toWei(525), toWei(1050)];
export const tierSupplyNFT = [2000, 1000, 1000, 1000];
