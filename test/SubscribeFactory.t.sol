// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Subscribe} from "../src/Subscribe.sol";
import {SubscribeFactory} from "../src/SubscribeFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SubscribeFactoryTest is Test {
    SubscribeFactory public factory;
    address public owner;
    address public casher;
    address public toAddress;
    address public user1;
    address public user2;

    function setUp() public {
        factory = new SubscribeFactory();
        owner = makeAddr("owner");
        casher = makeAddr("casher");
        toAddress = makeAddr("toAddress");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    // Test computing contract address
    function testComputeSubscribeAddress() public {
        bytes32 salt = bytes32(uint256(1));
        address computedAddress = factory.computeSubscribeAddress(
            owner,
            casher,
            toAddress,
            salt
        );

        // Ensure the address is not zero
        assertTrue(computedAddress != address(0));

        // Create the contract with the same parameters
        address actualAddress = factory.createSubscribe(owner, casher, toAddress, salt);

        // Check that the computed address matches the actual address
        assertEq(computedAddress, actualAddress);
    }

    // Test creating contract
    function testCreateSubscribe() public {
        bytes32 salt = bytes32(uint256(2));

        // Create contract
        address subscribeAddress = factory.createSubscribe(owner, casher, toAddress, salt);

        // Verify contract was created
        Subscribe subscribe = Subscribe(subscribeAddress);

        // Check owner and casher are set correctly
        assertEq(subscribe.owner(), owner);
        assertEq(subscribe.casherAddress(), casher);
        assertEq(subscribe.toAddress(), toAddress);
    }

    // Test creating contract with same salt but different parameters
    function testCreateSubscribeWithSameSalt() public {
        bytes32 salt = bytes32(uint256(3));

        // Create first contract
        address firstAddress = factory.createSubscribe(owner, casher, toAddress, salt);
        
        // The test should pass if we try to deploy to the same address
        // CREATE2 will revert if we try to deploy another contract to the same address
        vm.expectRevert();
        factory.createSubscribe(owner, casher, toAddress, salt);
    }

    // Test creating contract with same parameters but different salt
    function testCreateSubscribeWithDifferentSalt() public {
        bytes32 salt1 = bytes32(uint256(4));
        bytes32 salt2 = bytes32(uint256(5));

        // Create first contract
        address address1 = factory.createSubscribe(owner, casher, toAddress, salt1);

        // Create second contract with same parameters but different salt
        address address2 = factory.createSubscribe(owner, casher, toAddress, salt2);

        // Verify different addresses
        assertTrue(address1 != address2);
    }

    // Test reverting when owner and casher are the same
    function testCreateSubscribeRevertsSameOwnerAndCasher() public {
        bytes32 salt = bytes32(uint256(6));

        // Try to create contract with same owner and casher
        vm.expectRevert("Owner and casher cannot be the same address");
        factory.createSubscribe(owner, owner, toAddress, salt);
    }

    // Test compute address reverting when owner and casher are the same
    function testComputeAddressRevertsSameOwnerAndCasher() public {
        bytes32 salt = bytes32(uint256(7));

        // Try to compute address with same owner and casher
        vm.expectRevert("Owner and casher cannot be the same address");
        factory.computeSubscribeAddress(owner, owner, toAddress, salt);
    }
    
    // Test reverting when casher and toAddress are the same
    function testCreateSubscribeRevertsSameCasherAndToAddress() public {
        bytes32 salt = bytes32(uint256(8));

        // Try to create contract with same casher and toAddress
        vm.expectRevert("Casher and to address cannot be the same address");
        factory.createSubscribe(owner, casher, casher, salt);
    }
    
    // Test reverting when toAddress is zero
    function testCreateSubscribeRevertsZeroToAddress() public {
        bytes32 salt = bytes32(uint256(9));

        // Try to create contract with zero toAddress
        vm.expectRevert("To address cannot be the zero address");
        factory.createSubscribe(owner, casher, address(0), salt);
    }
    
    // Test reverting when casher is zero
    function testCreateSubscribeRevertsZeroCasher() public {
        bytes32 salt = bytes32(uint256(10));

        // Try to create contract with zero casher
        vm.expectRevert("Casher address cannot be the zero address");
        factory.createSubscribe(owner, address(0), toAddress, salt);
    }
    
    // Test compute address reverting when casher and toAddress are the same
    function testComputeAddressRevertsSameCasherAndToAddress() public {
        bytes32 salt = bytes32(uint256(11));

        // Try to compute address with same casher and toAddress
        vm.expectRevert("Casher and to address cannot be the same address");
        factory.computeSubscribeAddress(owner, casher, casher, salt);
    }
    
    // Test compute address reverting when toAddress is zero
    function testComputeAddressRevertsZeroToAddress() public {
        bytes32 salt = bytes32(uint256(12));

        // Try to compute address with zero toAddress
        vm.expectRevert("To address cannot be the zero address");
        factory.computeSubscribeAddress(owner, casher, address(0), salt);
    }
    
    // Test compute address reverting when casher is zero
    function testComputeAddressRevertsZeroCasher() public {
        bytes32 salt = bytes32(uint256(13));

        // Try to compute address with zero casher
        vm.expectRevert("Casher address cannot be the zero address");
        factory.computeSubscribeAddress(owner, address(0), toAddress, salt);
    }
    
    // Test events for createSubscribe
    function testCreateSubscribeEvents() public {
        bytes32 salt = bytes32(uint256(14));
        
        // First calculate the address that will be created
        address predictedAddress = factory.computeSubscribeAddress(
            owner,
            casher,
            toAddress,
            salt
        );
        
        // Now set up the expected event with the correct address
        vm.expectEmit(true, true, true, true);
        emit SubscribeFactory.SubscribeCreated(predictedAddress, owner, casher, salt);
        
        // Create the contract
        address subscribeAddress = factory.createSubscribe(owner, casher, toAddress, salt);
        
        // Verify the address matches our prediction
        assertEq(subscribeAddress, predictedAddress);
        
        // Verify Subscribe contract was created correctly
        Subscribe subscribe = Subscribe(subscribeAddress);
        assertEq(subscribe.owner(), owner);
        assertEq(subscribe.casherAddress(), casher);
        assertEq(subscribe.toAddress(), toAddress);
    }
}
