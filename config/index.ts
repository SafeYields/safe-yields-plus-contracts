import { BigNumberish } from '@ethersproject/bignumber';
import { toWei } from '@utils/output.helper';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

type Distribution = {
  investments: BigNumberish;
  management: BigNumberish;
};

export const PERCENTAGE_PRECISION_MULTIPLIER = 100;
export const percent = (value: number) => value * PERCENTAGE_PRECISION_MULTIPLIER;
export const HUNDRED_PERCENT = percent(10000);

export enum Wallets {
  InvestmentPool,
  Management,
}

export const wallets = async (hre: HardhatRuntimeEnvironment): Promise<string[]> => {
  const { investments, management } = await hre.getNamedAccounts();
  return [investments, management];
};

//the rest goes to the vault
export const taxDistributionForSafeToken: Distribution = {
  investments: percent(30),
  management: percent(20),
};

export const costDistributionForNFT: Distribution = {
  investments: percent(75),
  management: percent(20),
};
//the rest goes to teh vault
export const profitDistributionForNFT: Distribution = {
  investments: percent(25),
  management: percent(20),
};

export enum NFTTiers {
  Tier1,
  Tier2,
  Tier3,
  Tier4,
}

// export const tierPriceNFT = [toWei(131.25), toWei(262.5), toWei(525), toWei(1050)];
export const tierPriceNFT: Record<keyof typeof NFTTiers, BigNumberish> = {
  Tier1: toWei(131.25),
  Tier2: toWei(262.5),
  Tier3: toWei(525),
  Tier4: toWei(1050),
};
export const tierMaxSupplyNFT = [2000, 1000, 1000, 1000];
