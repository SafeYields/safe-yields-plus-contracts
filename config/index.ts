import { BigNumberish } from '@ethersproject/bignumber';
import { toWei } from '@utils/output.helper';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

type Distribution = {
  treasury: BigNumberish;
  management: BigNumberish;
};

export type TierPrices = Record<keyof typeof NFTTiers, BigNumberish>;

export const PERCENTAGE_PRECISION_MULTIPLIER = 1_000_000;
export const percent = (value: number) => value * PERCENTAGE_PRECISION_MULTIPLIER;
export const HUNDRED_PERCENT = percent(100);

// export const PRESALE_START_DATE = new Date('March 3, 2023 17:00:00').getTime() / 1000;
export const PRESALE_START_DATE = new Date('March 1, 2023 17:00:00').getTime() / 1000;
export const WEEK = 4 * 60 * 60;

export enum Wallets {
  Treasury,
  Management,
}

export const wallets = async (hre: HardhatRuntimeEnvironment): Promise<string[]> => {
  const { treasury, management } = await hre.getNamedAccounts();
  return [treasury, management];
};

export const tax = {
  buyTaxPercent: percent(0.25),
  sellTaxPercent: percent(0.25),
};

//the rest goes to the vault
export const taxDistributionForSafeToken: Distribution = {
  treasury: percent(30),
  management: percent(20),
};

export const costDistributionForNFT: Distribution = {
  treasury: percent(70),
  management: percent(20),
};

export const referralShareForNFTPurchase = percent(5);
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
export const tierPriceNFT: TierPrices = {
  Tier1: toWei(131.25, 6),
  Tier2: toWei(262.5, 6),
  Tier3: toWei(525, 6),
  Tier4: toWei(1050, 6),
};

export const discountedPresalePriceNFT: TierPrices[] = [0.6, 0.7, 0.8, 0.9].map(discount => {
  return {
    Tier1: toWei(131.25 * discount, 6),
    Tier2: toWei(262.5 * discount, 6),
    Tier3: toWei(525 * discount, 6),
    Tier4: toWei(1050 * discount, 6),
  };
});
export const tierMaxSupplyNFT = [2000, 1000, 1000, 1000];
export const presaleMaxSupply: [number, number, number, number] = [50, 25, 25, 25];
