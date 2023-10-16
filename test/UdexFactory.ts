import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ContractFactory, Contract } from "ethers";

// "0x" から始まり、40文字の16進数で構成される必要がある
const TEST_ADDRESSES: [string, string] = [
  "0x1234000000000000000000000000000000000000",
  "0x3456000000000000000000000000000000000000",
];
// hardhat networkという、イーサリアムを模したテストネットワークが使われる
describe("UdexFactory", () => {
  async function deployFactoryFixture() {
    // UdexFactoryの情報を読み込む
    const Factory = await ethers.getContractFactory("UdexFactory");
    // コントラクトをデプロイするというトランザクションの情報をイーサリアムネットワークに送る
    const factory = await Factory.deploy();
    // コントラクトの情報がイーサリアム上に書き込まれたことを確認する
    await factory.deployed();
    return { factory };
  }

  it("get no pool address before creation", async () => {
    const { factory } = await loadFixture(deployFactoryFixture);
    expect(await factory.getPool(...TEST_ADDRESSES)).to.eq(
      ethers.constants.AddressZero
    );
  });

  it("get pool address after creation", async () => {
    const { factory } = await loadFixture(deployFactoryFixture);
    // イーサリアムノードにトランザクションを送信する
    // 戻り値としてpoolのアドレス値は返ってこない
    const tx = await factory.createPool(...TEST_ADDRESSES);
    // 処理中に発行されたEventはレシートに書き込まれる
    const receipt = await tx.wait();
    const event = factory.interface.
  });
});
