import { BigNumberish } from '@ethersproject/bignumber';
import { toWei } from '@utils/output.helper';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

type Distribution = {
  treasury: BigNumberish;
  management: BigNumberish;
};

export const PERCENTAGE_PRECISION_MULTIPLIER = 100;
export const percent = (value: number) => value * PERCENTAGE_PRECISION_MULTIPLIER;
export const HUNDRED_PERCENT = percent(10000);

export enum Wallets {
  Treasury,
  Management,
}

export const wallets = async (hre: HardhatRuntimeEnvironment): Promise<string[]> => {
  const { treasury, management } = await hre.getNamedAccounts();
  return [treasury, management];
};

//the rest goes to the vault
export const taxDistributionForSafeToken: Distribution = {
  treasury: percent(30),
  management: percent(20),
};

export const costDistributionForNFT: Distribution = {
  treasury: percent(75),
  management: percent(20),
};
//the rest goes to teh vault
export const profitDistributionForNFT: Distribution = {
  treasury: percent(25),
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
  Tier1: toWei(131.25, 6),
  Tier2: toWei(262.5, 6),
  Tier3: toWei(525, 6),
  Tier4: toWei(1050, 6),
};
export const tierMaxSupplyNFT = [2000, 1000, 1000, 1000];
