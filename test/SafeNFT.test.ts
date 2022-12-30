import { NFTTiers, tierPriceNFT } from '@config';
import { ISafeNFT, ISafeToken } from '@contractTypes/contracts/interfaces';
import erc20abi from 'abi/erc20abi.json';
import { expect } from 'chai';
import newDebug from 'debug';
import { Contract } from 'ethers';
import hardhat, { deployments, ethers } from 'hardhat';
import { Address } from 'hardhat-deploy/dist/types';

const debug = newDebug('safe:SafeNFT.test.ts');

describe('SafeNFT', () => {
  let safeNFTContract: ISafeNFT;
  let safeTokenContract: ISafeToken;
  let usdContract: Contract;
  let namedAccounts: { [name: string]: Address };
  let user: Address;
  let otherUser: Address;

  beforeEach(async () => {
    await deployments.fixture(['SafeVault', 'SafeToken', 'SafeNFT', 'Config']);
    safeTokenContract = await ethers.getContract<ISafeToken>('SafeToken');
    safeNFTContract = await ethers.getContract<ISafeNFT>('SafeNFT');
    namedAccounts = await hardhat.getNamedAccounts();
    usdContract = await ethers.getContractAt(erc20abi, namedAccounts.busd);
    user = namedAccounts.deployer;
    otherUser = (await hardhat.getUnnamedAccounts())[0];
  });

  describe('getPrice(Tiers _tier)', () => {
    Object.entries(NFTTiers)
      .filter(([_, value]) => isNaN(Number(value)))
      .forEach(([tierId, tierName]) => {
        it(`should return a correct price for ${tierName}`, async () => {
          expect(await safeNFTContract.getPrice(tierId)).to.be.equal(tierPriceNFT[tierName as keyof typeof NFTTiers]);
        });
      });
  });
});
