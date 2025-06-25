// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./PullPayment.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract PullPaymentFactory {
    event PullPaymentCreated(
        address indexed pullPaymentAddress,
        address indexed owner,
        address[] cashers,
        bytes32 salt
    );

    /**
     * @dev Computes the address of a PullPayment contract that would be deployed using CREATE2
     * @param _owner The owner address for the new PullPayment contract
     * @param _cashers The casher addresses for the new PullPayment contract
     * @param _toAddress The to address for the new PullPayment contract
     * @param _salt A unique value to ensure unique addresses
     * @return The address where the contract will be deployed
     */
    function computePullPaymentAddress(
        address _owner,
        address[] memory _cashers,
        address _toAddress,
        bytes32 _salt
    ) public view returns (address) {
        require(_cashers.length > 0, "At least one casher is required");
        
        require(
            _toAddress != address(0),
            "To address cannot be the zero address"
        );

        // Validate cashers
        for (uint256 i = 0; i < _cashers.length; i++) {
            require(
                _cashers[i] != address(0),
                "Casher address cannot be the zero address"
            );
            require(
                _cashers[i] != _owner,
                "Owner cannot be a casher"
            );
            require(
                _cashers[i] != _toAddress,
                "Casher and to address cannot be the same address"
            );
            
            // Check for duplicates
            for (uint256 j = i + 1; j < _cashers.length; j++) {
                require(
                    _cashers[i] != _cashers[j],
                    "Duplicate casher address"
                );
            }
        }

        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(PullPayment).creationCode,
                abi.encode(_owner, _cashers, _toAddress)
            )
        );

        return Create2.computeAddress(_salt, bytecodeHash);
    }

    /**
     * @dev Creates a new PullPayment contract using CREATE2
     * @param _owner The owner address for the new PullPayment contract
     * @param _cashers The casher addresses for the new PullPayment contract
     * @param _toAddress The to address for the new PullPayment contract
     * @param _salt A unique value to ensure unique addresses
     * @return The address of the created PullPayment contract
     */
    function createPullPayment(
        address _owner,
        address[] memory _cashers,
        address _toAddress,
        bytes32 _salt
    ) public returns (address) {
        require(_cashers.length > 0, "At least one casher is required");
        
        require(
            _toAddress != address(0),
            "To address cannot be the zero address"
        );

        // Validate cashers
        for (uint256 i = 0; i < _cashers.length; i++) {
            require(
                _cashers[i] != address(0),
                "Casher address cannot be the zero address"
            );
            require(
                _cashers[i] != _owner,
                "Owner cannot be a casher"
            );
            require(
                _cashers[i] != _toAddress,
                "Casher and to address cannot be the same address"
            );
            
            // Check for duplicates
            for (uint256 j = i + 1; j < _cashers.length; j++) {
                require(
                    _cashers[i] != _cashers[j],
                    "Duplicate casher address"
                );
            }
        }

        bytes memory bytecode = abi.encodePacked(
            type(PullPayment).creationCode,
            abi.encode(_owner, _cashers, _toAddress)
        );

        address pullPaymentAddress = Create2.deploy(0, _salt, bytecode);

        emit PullPaymentCreated(pullPaymentAddress, _owner, _cashers, _salt);

        return pullPaymentAddress;
    }
}
