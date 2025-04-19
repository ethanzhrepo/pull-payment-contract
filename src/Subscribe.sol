// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Subscribe is Ownable {
    using SafeERC20 for IERC20;

    event CasherAddressSet(
        address indexed previousCasher,
        address indexed newCasher
    );
    event ToAddressSet(
        address indexed previousToAddress,
        address indexed newToAddress
    );

    event Charge(
        address indexed token,
        address indexed fromAddress,
        uint256 amount
    );


    constructor(
        address _owner,
        address _casher,
        address _toAddress
    ) Ownable(_owner) {
        require(
            _owner != _casher,
            "Owner and casher cannot be the same address"
        );
        require(
            _casher != _toAddress,
            "Casher and to address cannot be the same address"
        );
        require(
            _toAddress != address(0),
            "To address cannot be the zero address"
        );
        require(
            _casher != address(0),
            "Casher address cannot be the zero address"
        );
        casherAddress = _casher;
        emit CasherAddressSet(address(0), _casher);
        toAddress = _toAddress;
        emit ToAddressSet(address(0), _toAddress);
    }

    address public casherAddress;

    address public toAddress;

    // only casher can charge
    modifier onlyCasher() {
        require(msg.sender == casherAddress, "Only casher can charge");
        _;
    }

    function setCasherAddress(address _casherAddress) public onlyOwner {
        require(
            _casherAddress != toAddress,
            "Casher address cannot be the same as the to address"
        );
        require(
            _casherAddress != owner(),
            "Casher address cannot be the owner"
        );
        require(
            _casherAddress != address(0),
            "Casher address cannot be the zero address"
        );
        address previousCasher = casherAddress;
        casherAddress = _casherAddress;
        emit CasherAddressSet(previousCasher, _casherAddress);
    }

    function setToAddress(address _toAddress) public onlyOwner {
        require(
            _toAddress != casherAddress,
            "To address cannot be the same as the casher address"
        );
        require(
            _toAddress != address(0),
            "To address cannot be the zero address"
        );
        address previousToAddress = toAddress;
        toAddress = _toAddress;
        emit ToAddressSet(previousToAddress, _toAddress);
    }

    function charge(
        address _token,
        address _fromAddress,
        uint256 _amount
    ) public onlyCasher {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            toAddress != _fromAddress,
            "To address cannot be the same as the from address"
        );
        
        IERC20(_token).safeTransferFrom(_fromAddress, toAddress, _amount);
        emit Charge(_token, _fromAddress, _amount);
    }

    function batchCharge(
        address _token,
        address[] memory _fromAddresses,
        uint256[] memory _amounts
    ) public onlyCasher {
        require(
            _fromAddresses.length == _amounts.length,
            "From addresses and amounts must have the same length"
        );
        for (uint256 i = 0; i < _fromAddresses.length; i++) {
            charge(_token, _fromAddresses[i], _amounts[i]);
        }
    }

    function withdraw(address _token) public onlyOwner {
        IERC20(_token).safeTransfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}
