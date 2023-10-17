// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '../interfaces/IERC20.sol';

// ERC20トークンのサンプルコード
// 独自のトークン発行時にはこちらに従う
contract TokenTest is IERC20 {
    uint256 private _totalSupply; // 全てのトークンの数
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner; 
    // {"99sfs999fsfs": "233434343", "hohosj323j2o23": "3333323235"}
    mapping(address => uint256) private _balances; // 各アドレスのトークンバランスを保持するマッピング
    // _allowances[A][C] = amount; // AがCに対して支払い許可としてamountを設定
    // C（DEXみたいなシステム側）がA（ユーザー等）に対してBに送金を許可
    // _allowancesという名前のマッピングは、所有者のアドレス（A）と支払許可を受ける側のアドレス（C）をキーとし、その値として送金できるトークンの量（uint256）を格納します
    // アクセス許可管理の仕組みを実装するために使用される
    // アクセス許可を管理するための2重のマッピングで、所有者と支払い許可を受ける側のアドレスごとに支払えるトークン量を保持
    mapping(address => mapping (address => uint256)) private _allowances; // allowance["A"]["C"] 
    // CがAから10まで引き出し許可する
    // CがAから10まで引き出すことができる
    // allowance["A"]["C"] = 10

    // コントラクトの初期化時に呼び出される
    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        _owner = msg.sender; // Ethereumのスマートコントラクトにおける特殊な変数で、現在の関数を呼び出したアドレスを表す
        _balances[_owner] = _totalSupply;
    }

    // externalすると外部からも呼び出せる
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
 
    // ownerがAでspenerがCのイメージ　
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    // 新しいトークンの発行
    // accountはトークンを受け取るアドレス
    // msg.sender = 関数を呼び出すアドレス
    function mint(address account, uint256 amount) external {
        // オーナーしか新たなトークンを発行できない
        require(msg.sender == _owner, "only contract owner can call mint"); // これは、関数を呼び出したアドレス（msg.sender）がコントラクトの所有者（_owner）であることを要求しています。つまり、コントラクトの所有者でなければ、mint関数やburn関数を呼び出すことができない
        // 指定されたアカウントがゼロアドレス（つまり空のアドレス）でないことを確認
        require(account != address(0), "mint to zero address is not allowed");
        // 全体に増える
        _totalSupply = _totalSupply + amount; 
        // 指定したアカウントのbalanceも増える
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    // トークンの消滅
    function burn(address account, uint256 amount) external {
        // オーナーしか新たなトークンを発行できない
        require(msg.sender == _owner, "only contract owner can call burn");
        require(account != address(0), "burn from the zero address is not allowed");
        // 指定したアカウントのbalanceも増える
        _balances[account] = _balances[account] - amount;
        // 全体に増える
        _totalSupply = _totalSupply - amount; 
        emit Transfer(account, address(0), amount);
    }

    // トークンの送金
    function transfer(address recipient, uint amount) external returns (bool) {
        require(recipient != address(0), "transfer to the zero address is not allowed");
        address sender = msg.sender;
        require(_balances[sender] >= amount, "transfer cannot exceed balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        // ログ
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // 所有者のアドレスが指定したアドレスに対して支払い許可を設定します。支払い許可の量も指定します
    // 所有者のアドレスが指定したアドレス（spender）に対して支払い許可を設定するためのもの
    // spender: 支払い許可を与える対象のアドレス。C
    // amount: 許可するトークン量。
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "approve to the zero is not allowed");
        // A
        address owner = msg.sender;
        // [A][C]
        // A(トークンの所有者)がC(DEXなど)がAのトークンをamount分Bなどに移動させることを許可（Approve）する
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true; 
    }

    // 指定されたアドレスから別のアドレスへトークンを送金します。送金元が許可した範囲内でのみ送金が行われる
    // transferFrom(A, B, 10)
    // allowance["A"]["C"] = 0
    function transferFrom(address sender, address recipient, uint amount) external returns (bool) {
        require(recipient != address(0), "transfer to the zero address is not allowed");
        require(_balances[sender] >= amount, "transfer cannot exceed balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);

        // このメソッドを呼び出した人。C。DEXとか
        address spender = msg.sender;
        // sender(A)のトークンをspender(C)が移動できる量をチェック
        require(_allowances[sender][spender] >= amount, "insufficient allowance");
        _allowances[sender][spender] = _allowances[sender][spender] - amount;
        emit Approval(sender, spender, _allowances[sender][spender]);

        return true;
    }
}