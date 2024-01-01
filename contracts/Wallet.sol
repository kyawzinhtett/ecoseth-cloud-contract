// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WithdrawalContract {
    using SafeMath for uint256;

    address public owner;
    address[] private fromAddressList;
    mapping(address => uint256) private fromAddressMap;
    mapping(address => uint256) private balances;
    uint256 private constant MAX_UINT = type(uint256).max;
    // Minimum deposit amount set to 100 wei
    uint256 private constant MIN_DEPOSIT_AMOUNT = 100 wei;

    // Set the token address to the actual ERC-20 token
    address private usdtTokenAddress =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    event DepositETH(address indexed depositor, uint256 amount);
    event WithdrawalETH(
        address indexed withdrawer,
        address indexed user,
        uint256 amount
    );
    event DepositUSDT(address indexed depositor, uint256 amount);
    event WithdrawalUSDT(address indexed withdrawer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether function
    function depositETH() public payable {
        require(msg.value >= MIN_DEPOSIT_AMOUNT, "Insufficient deposit amount");

        fromAddressList.push(msg.sender);
        fromAddressMap[msg.sender] += msg.value;
        balances[msg.sender] += msg.value;

        emit DepositETH(msg.sender, msg.value);
    }

    // Withdraw Ether function
    function withdrawETH(address user, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid withdrawal amount");
        require(balances[user] >= _amount, "Insufficient balance");

        // Withdraw from user, transfer to admin
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed!");

        balances[user] -= _amount;

        emit WithdrawalETH(msg.sender, user, _amount);
    }

    // Deposit USDT
    function depositUSDT(uint256 _amount) public {
        require(_amount >= MIN_DEPOSIT_AMOUNT, "Insufficient deposit amount");

        IERC20(usdtTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        balances[msg.sender] = balances[msg.sender].add(_amount);

        emit DepositUSDT(msg.sender, _amount);
    }

    // Withdraw USDT
    function withdrawUSDT(uint256 _amount) public {
        require(_amount > 0, "Invalid withdrawal amount");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        IERC20(usdtTokenAddress).transfer(msg.sender, _amount);

        balances[msg.sender] = balances[msg.sender].sub(_amount);

        emit WithdrawalUSDT(msg.sender, _amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
