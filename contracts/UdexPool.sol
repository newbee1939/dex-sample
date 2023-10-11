// <UdexPoolをデプロイするコントラクト>
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract UdexPool {
    // これら3つはstate variables
    // immutable: 一度登録したら変更できない
    address immutable public factory; // PoolContractをデプロイしたFactoryコントラクトのアドレスを入れる
    // このPoolに対応するTokenペアのアドレス
    address public token0;
    address public token1;

    // コントラクトをデプロイするときに呼び出される
    constructor() {
        //
    }
}