// <UdexPoolをデプロイするコントラクト>
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract UdexPool {
    // immutable: 一度登録したら変更できない
    address immutable public factory; // PoolContractをデプロイしたFactoryコントラクトのアドレスを入れる
    // このPoolに対応するTokenペアのアドレス
    address public token0;
    address public token1;
}