// <UdexPoolをデプロイするコントラクト>
// Poolコントラクトは、factoryコントラクトからデプロイする
// 流動性Poolは、預けられたトークンペアに対して流動性トークンを発行する
// -> 流動性トークン自体がERC20になっている
// -> UdexPoolのコントラクトはERC20のコントラクトを継承して作られる
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import './libraries/Math.sol';
import './interfaces/IERC20.sol';
import './UdexERC20.sol';

// isで継承できる
contract UdexPool is UdexERC20("Udex Token", "UDX", 18) {
    // これら3つはstate variables
    // immutable: 一度登録したら変更できない
    address immutable public factory; // PoolContractをデプロイしたFactoryコントラクトのアドレスを入れる
    // このPoolに対応するTokenペアのアドレス
    address public token0;
    address public token1;

    // コントラクトをデプロイするときに呼び出される
    // constructorに引数は渡したくない？
    constructor() {
        // factoryコントラクトのアドレスが入っている
        factory = msg.sender;
    }

    // constructorの実行直後に呼び出す
    // externalした関数は、このファイル内から呼び出すことはできない
    function initialize(address _token0, address _token1) external {
        // 引っかかった場合は、revertが走って、それまでの処理がなかったことになる
        require(msg.sender == factory, 'UdexPool: initialization forbidden');

        token0 = _token0;
        token1 = _token1;
    }
}