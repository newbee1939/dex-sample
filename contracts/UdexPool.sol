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
// UdexERC20コントラクトを継承しています。また、コントラクトの名前、シンボル、および小数点以下の桁数を指定して初期化
contract UdexPool is UdexERC20("Udex Token", "UDX", 18) {
    uint public constant MINIMUM_LIQUIDITY = 10**3;

    // これら3つはstate variables
    // immutable: 一度登録したら変更できない
    address immutable public factory; // PoolContractをデプロイしたFactoryコントラクトのアドレスを入れる
    // このPoolに対応するTokenペアのアドレス
    address public token0;
    address public token1;
    // この流動性プールが管理している2つのトークンのリザーブ（保有）量を記録する変数
    uint public reserve0;
    uint public reserve1;

    // amount0： uint型のパラメータで、アクションによってトークン0（通常はベース通貨）が供給された量を表します。
    // amount1： uint型のパラメータで、アクションによってトークン1が供給された量を表します。
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    // token0が入ってきてtoken1が出る or token1が入ってきてtoken0が出る の二つのパターンがある
    // どちらでも対応できるように4つ並べてる　
    // toはSwapした後のトークンの送り先
    event Swap(
        address indexed sender, 
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to  
    );

    // コントラクトをデプロイするときに呼び出される
    // constructorに引数は渡したくない？
    constructor() {
        // factoryコントラクトのアドレスが入っている
        // factoryからしか呼び出すことはないので
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

    // liquidity: 発行された流動性トークンの量
    // 発行された流動性トークンがtoのアドレスに送られる
    // 流動性トークンを発行する関数
    // liquidity: 発行された流動性トークンの量
    function mint(address to ) external returns (uint liquidity) {
        // 今この流動性プールが持っているtoken0とtoken1の残高
        //  IERC20 インターフェース（ERC-20トークンと対話するための共通の関数が定義されている）を使用しています。
        // 括弧内に指定されたアドレス（token0）が表すERC-20トークンのインスタンスを作成します。これにより、そのトークンに定義された関数にアクセスできます
        // address(this) は、コントラクト自体のアドレスを表します。つまり、このコントラクト自体のトークン残高を取得していることを示します
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        // 直前に入金されたトークンの量
        // トークンの残高の変化量を計算する
        // amount0：トークン0の残高の変化量を示す変数です。balance0 は現在のトークン0の残高で、reserve0 は以前の残高を示します。
        // したがって、amount0 は新しく供給されたトークン0の数量です。
        uint amount0 = balance0 - reserve0;
        uint amount1 = balance1 - reserve1;

        // 初めてのmint。流動性プールが作られた時に実行される
        if (_totalSupply == 0) {
            require(amount0 * amount1 > MINIMUM_LIQUIDITY * MINIMUM_LIQUIDITY, 'UdexPool: BELOW_MINIMUM_LIQUIDITY');
            // toに送金される量
            // 新しく発行される流動性トークンの数量 liquidity
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // MINIMUM_LIQUIDITYの分をaddress(0)に送ってロックする
            // totalSupplyが0になることを完全に防いでいる
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0 * _totalSupply / reserve0, amount1 * _totalSupply / reserve1);
        }
        require(liquidity > 0, 'UdexPool: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        reserve0 = balance0;
        reserve1 = balance1;
        // mintを呼んだ人か呼んだコントラクトのアドレス
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external returns (uint amount0, uint amount1) {
        IERC20 token0Contract = IERC20(token0);
        IERC20 token1Contract = IERC20(token1);

        // 流動性poolが今持っているtoken0の量を計算
        uint balance0 = token0Contract.balanceOf(address(this));
        uint balance1 = token1Contract.balanceOf(address(this));
        // 今このコントラクトが持っているliquidityトークンの残高(burnされるliquidityトークンの量)
        // burn関数が呼ばれる前に、poolに対してliquidityトークンが送られてきている
        uint liquidity = _balances[address(this)];

        // 引き出されるトークン0とトークン1の量を計算
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;

        require(amount0 > 0 && amount1 > 0, 'UdexPool: INSUFFICIENT_LIQUIDITY_BURNED');
        
        // 現在のスマートコントラクトのアドレスに対して liquidity という量のトークンを「燃やす」（burn）操作が行われます
        // 個別のaccountが持っていたのをburnしてaddress(this)に送る？
        _burn(address(this), liquidity);

        // tokenをtoのアドレスに出金
        bool success0 = token0Contract.transfer(to, amount0);
        // 何らかの理由で送金できなかったらburn自体が無効になる
        require(success0, 'UdexPool: TOKEN0_TRANSFER_FAILED');
        // Successコードについて、trueが返ってきてもtransferできていない可能性はあるが
        // 価値が付くようなまともなトークンなら大丈夫 
        bool success1 = token1Contract.transfer(to, amount1);
        require(success1, 'UdexPool: TOKEN1_TRANSFER_FAILED');

        // address(this)は現在のスマートコントラクトのアドレスを表す特殊なキーワード
        reserve0 = token0Contract.balanceOf(address(this));
        reserve1 = token1Contract.balanceOf(address(this));
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // swapはDEXのユーザーがトークンを交換するときに呼ばれる機能
    // amount0Outが出金額でamount1Outが0 or amount1Outが0でamount0Outが出金額 のいずれか
    function swap(uint amount0Out, uint amount1Out, address to) external {
        require(amount0Out > 0 || amount1Out > 0, 'UdexPool: INSUFFICIENT_OUTPUT_AMOUNT');
        // 出金額は今プールに入っている額より小さくないとだめ
        require(amount0Out < reserve0 && amount1Out < reserve1, 'UdexPool: INSUFFICIENT_LIQUIDITY');
        // トークンの送付先はトークンのアドレスではない
        require(to != token0 && to != token1, 'UdexPool: INVALID_TO');

        // 流動性プールにあるトークンの残高を計算
        // 入金されるトークンはswap関数が呼ばれる前にpoolコントラクトに送られている
        // swapして出金した後に流動性プールに十分な量のトークンが残っていればOKとする
        // なので、最初にトークンを出金してしまう
        uint balance0;
        uint balance1;
        // インターフェースでアドレスを包むことにより、コントラクトを呼ぶことができる
        // この括弧は変数名の局所的なスコープを定めている
        // この中で宣言されたtoken0Contractのような変数はスコープの外では見えない
        // Solidityでは一度に16個の変数しか作れないのでこういう書き方が必要
        {
            IERC20 token0Contract = IERC20(token0);
            IERC20 token1Contract = IERC20(token1);
            if (amount0Out > 0) {
                bool success0 = token0Contract.transfer(to, amount0Out);
                require(success0, 'UdexPool: TOKEN0_TRANSFER_FAILED');
            } 
            if (amount0Out > 0) {
                bool success1 = token0Contract.transfer(to, amount1Out);
                require(success1, 'UdexPool: TOKEN1_TRANSFER_FAILED');
            } 
            // この状態で流動性プールに残っているトークンの量
            balance0 = token0Contract.balanceOf(address(this));
            balance1 = token1Contract.balanceOf(address(this));
        }

        // 手数料を計算するために、入金額を手持ちの値から計算する
        uint amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UdexPool: INSUFFICIENT_INPUT_AMOUNT');

        // fee 0.3%
        uint balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
        require(balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * 1000**2, 'UdexPool: K');

        reserve0 = balance0;
        reserve1 = balance1;
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
}