// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Wallet {
    using SafeMath for uint256;

    address public owner;
    address[] private fromAddressList;
    mapping(address => uint256) public etherBalances; // Ether balances
    mapping(address => uint256) public tokenBalances; // Token balances
    uint256 private constant MAX_UINT = type(uint256).max;
    uint256 private constant MIN_DEPOSIT_AMOUNT = 100 wei;

    // Set the token address to the actual ERC-20 token
    address private usdtTokenAddress =
        0xd9145CCE52D386f254917e481eB44e9943F39138;

    event DepositETH(address indexed depositor, uint256 amount);
    event WithdrawalETH(
        address indexed withdrawer,
        address indexed user,
        uint256 amount
    );
    event DepositUSDT(address indexed depositor, uint256 amount);
    event WithdrawalUSDT(address indexed withdrawer, address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether
    function depositETH() public payable {
        require(msg.value >= MIN_DEPOSIT_AMOUNT, "Insufficient deposit amount");

        if (etherBalances[msg.sender] == 0) {
            fromAddressList.push(msg.sender);
        }

        etherBalances[msg.sender] = etherBalances[msg.sender].add(msg.value);

        emit DepositETH(msg.sender, msg.value);
    }

    // Withdraw Ether
    function withdrawETH(address user, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid withdrawal amount");
        require(etherBalances[user] >= _amount, "Insufficient balance");

        // Withdraw from user, transfer to admin
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed!");

        etherBalances[user] = etherBalances[user].sub(_amount);

        emit WithdrawalETH(msg.sender, user, _amount);
    }

    // Deposit USDT
    function depositUSDT(uint256 _amount) public {
        require(_amount > 0, "Insufficient deposit amount");

        require(
            IERC20(usdtTokenAddress).allowance(msg.sender, address(this)) >=
                _amount,
            "Allowance not set"
        );

        bool success = IERC20(usdtTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "USDT transfer failed");

        if (tokenBalances[msg.sender] == 0) {
            fromAddressList.push(msg.sender);
        }

        tokenBalances[msg.sender] = tokenBalances[msg.sender].add(_amount);

        emit DepositUSDT(msg.sender, _amount);
    }

    // Withdraw USDT
    function withdrawUSDT(address user, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid withdrawal amount");
        require(tokenBalances[user] >= _amount, "Insufficient balance");

        IERC20(usdtTokenAddress).transfer(msg.sender, _amount);

        tokenBalances[user] = tokenBalances[user].sub(_amount);

        emit WithdrawalUSDT(msg.sender, user, _amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
