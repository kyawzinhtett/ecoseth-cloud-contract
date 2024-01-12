// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Wallet {
    using SafeMath for uint256;

    address[] private owners;
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
    event WithdrawalUSDT(
        address indexed withdrawer,
        address indexed user,
        uint256 amount
    );
    event OwnerAdded(address indexed newOwner);

    modifier onlyOwners() {
        bool isAnyOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isAnyOwner = true;
                break;
            }
        }
        require(isAnyOwner, "Only owners can call this function");
        _;
    }

    constructor() {
        owners.push(msg.sender);
    }

    // Add New Owners
    function addOwner(address newOwner) public onlyOwners {
        require(newOwner != address(0), "Invalid new owner address");
        require(!isOwner(newOwner), "Address is already an owner");
        owners.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    // Get Owners
    function getOwners() public view returns (address[] memory) {
        return owners;
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
    function withdrawETH(address user, uint256 _amount) public onlyOwners {
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
    function withdrawUSDT(address user, uint256 _amount) public onlyOwners {
        require(_amount > 0, "Invalid withdrawal amount");
        require(tokenBalances[user] >= _amount, "Insufficient balance");

        IERC20(usdtTokenAddress).transfer(msg.sender, _amount);

        tokenBalances[user] = tokenBalances[user].sub(_amount);

        emit WithdrawalUSDT(msg.sender, user, _amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}

    // Check if an address is an owner
    function isOwner(address _address) public view onlyOwners returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (_address == owners[i]) {
                return true;
            }
        }
        return false;
    }
}
