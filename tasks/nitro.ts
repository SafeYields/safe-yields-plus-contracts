import { percent } from '@config';
import { SafeNFT } from '@contractTypes/contracts';
import { info, networkInfo, success } from '@utils/output.helper';
import { task, types } from 'hardhat/config';
import moment from 'moment';

const timeStampFormat = 'DD.MM.YYYY HH:mm:ss?';
export default task('nitro', 'gets and sets presale date to now or other date')
  .addOptionalParam(
    'test',
    'update the date (default is false which only reads and displays the date)',
    true,
    types.boolean,
  )
  .addOptionalParam('date', `presale date to set in format ${timeStampFormat}`, '06.04.2023 00:00:00', types.string)
  .addOptionalParam('duration', `presale duration in seconds`, 2 * 24 * 3600, types.int)
  .setAction(async ({ test, date, duration }, hre) => {
    await networkInfo(hre, info);

    const nftContract = await hre.ethers.getContract<SafeNFT>('SafeNFT');
    info(`nitroPresale: ${(await nftContract.nitroPresale()).toString()}`);
    info(
      `nitroPresaleStartDate: ${moment
        .unix((await nftContract.nitroPresaleStartDate()).toNumber())
        .format(timeStampFormat)}`,
    );
    info(`nitroPresaleDuration: ${(await nftContract.nitroPresaleDuration()).toNumber()}`);
    info(`nitroPresaleDiscount: ${(await nftContract.nitroPresaleDiscount()).toNumber()}`);

    if (!test) {
      const timeStamp = moment(date, timeStampFormat).unix();
      info(`setting presale start to ${date}, which is ${timeStamp}`);
      await (
        await nftContract.setNitroPresale(
          true,
          timeStamp,
          duration,
          percent(90),
          '0x3dF475F4c39912e142955265e8f5c38dAd286FE3',
        )
      ).wait();
    }
    success('Done.');
  });
