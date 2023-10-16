import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import UdexPool from "../artifacts/contracts/UdexPool.sol/UdexPool.json";
import { ContractFactory, Contract } from "ethers";
import { getCreate2Address } from "./lib/utilities";

// "0x" から始まり、40文字の16進数で構成される必要がある
const TEST_ADDRESSES: [string, string] = [
  "0x1234000000000000000000000000000000000000",
  "0x3456000000000000000000000000000000000000",
];
// hardhat networkという、イーサリアムを模したテストネットワークが使われる
describe("UdexFactory", () => {
  async function deployFactoryFixture() {
    // UdexFactoryの情報を読み込む
    const Factory: ContractFactory = await ethers.getContractFactory(
      "UdexFactory"
    );
    // コントラクトをデプロイするというトランザクションの情報をイーサリアムネットワークに送る
    const factory: Contract = await Factory.deploy();
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
    const event = factory.interface.parseLog(receipt.logs[0]);
    expect(event.name).to.eq("PoolCreated");
    const poolAddress: string = event.args[2];
    // poolのアドレスがmappingのstorgeに書き込まれたことをテスト
    expect(await factory.getPool(TEST_ADDRESSES[1], TEST_ADDRESSES[0])).to.eq(
      poolAddress
    );
    expect(await factory.getPool(TEST_ADDRESSES[0], TEST_ADDRESSES[1])).to.eq(
      poolAddress
    );
  });

  it("pool created at expected address", async () => {
    const { factory } = await loadFixture(deployFactoryFixture);
    const bytecode: string = UdexPool.bytecode;
    const [address0, address1] =
      TEST_ADDRESSES[0] < TEST_ADDRESSES[1]
        ? TEST_ADDRESSES
        : [TEST_ADDRESSES[0], TEST_ADDRESSES[1]];
    // デプロイアドレスを取得する
    const create2Address = getCreate2Address(
      factory.address,
      [address0, address1],
      bytecode
    );

    // to.emitでEventが出ていることをテスト
    await expect(factory.createPool(...TEST_ADDRESSES))
      .to.emit(factory, "PoolCreated")
      .withArgs(address0, address1, create2Address);
  });
});
