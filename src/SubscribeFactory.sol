// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Subscribe.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract SubscribeFactory {
    event SubscribeCreated(
        address indexed subscribeAddress,
        address indexed owner,
        address indexed casher,
        bytes32 salt
    );

    /**
     * @dev Computes the address of a Subscribe contract that would be deployed using CREATE2
     * @param _owner The owner address for the new Subscribe contract
     * @param _casher The casher address for the new Subscribe contract
     * @param _toAddress The to address for the new Subscribe contract
     * @param _salt A unique value to ensure unique addresses
     * @return The address where the contract will be deployed
     */
    function computeSubscribeAddress(
        address _owner,
        address _casher,
        address _toAddress,
        bytes32 _salt
    ) public view returns (address) {
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

        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(Subscribe).creationCode,
                abi.encode(_owner, _casher, _toAddress)
            )
        );

        return Create2.computeAddress(_salt, bytecodeHash);
    }

    /**
     * @dev Creates a new Subscribe contract using CREATE2
     * @param _owner The owner address for the new Subscribe contract
     * @param _casher The casher address for the new Subscribe contract
     * @param _toAddress The to address for the new Subscribe contract
     * @param _salt A unique value to ensure unique addresses
     * @return The address of the created Subscribe contract
     */
    function createSubscribe(
        address _owner,
        address _casher,
        address _toAddress,
        bytes32 _salt
    ) public returns (address) {
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

        bytes memory bytecode = abi.encodePacked(
            type(Subscribe).creationCode,
            abi.encode(_owner, _casher, _toAddress)
        );

        address subscribeAddress = Create2.deploy(0, _salt, bytecode);

        emit SubscribeCreated(subscribeAddress, _owner, _casher, _salt);

        return subscribeAddress;
    }
}
