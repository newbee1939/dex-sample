import { expect } from "chai";
import { ethers } from "hardhat";
import { ContractFactory, Contract } from "ethers";

const TEST_ADDRESSES: [string, string] = [
  '0x12340000000000000000000000000000000000000',
  '0x34560000000000000000000000000000000000000',
]
// hardhat networkという、イーサリアムを模したテストネットワークが使われる
describe("UdexFactory", () => {
  it("get no pool address before creation", async () => {
    // UdexFactoryの情報を読み込む
    const Factory = await ethers.getContractFactory(
      "UdexFactory"
    );
    // コントラクトをデプロイするというトランザクションの情報をイーサリアムネットワークに送る
    const factory = await Factory.deploy();
    // コントラクトの情報がイーサリアム上に書き込まれたことを確認する
    await factory.deployed();
    
    expect(await factory.getPool(...TEST_ADDRESSES)).to.eq(ethers.constants.AddressZero);
  });
});
