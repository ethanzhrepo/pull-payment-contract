// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PullPayment} from "../src/PullPayment.sol";
import {PullPaymentFactory} from "../src/PullPaymentFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PullPaymentFactoryTest is Test {
    PullPaymentFactory public factory;
    address public owner;
    address public casher;
    address public toAddress;
    address public user1;
    address public user2;

    function setUp() public {
        factory = new PullPaymentFactory();
        owner = makeAddr("owner");
        casher = makeAddr("casher");
        toAddress = makeAddr("toAddress");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    // Test computing contract address
    function testComputePullPaymentAddress() public {
        bytes32 salt = bytes32(uint256(1));
        
        address[] memory cashers = new address[](1);
        cashers[0] = casher;
        
        address computedAddress = factory.computePullPaymentAddress(
            owner,
            cashers,
            toAddress,
            salt
        );

        // Ensure the address is not zero
        assertTrue(computedAddress != address(0));

        // Create the contract with the same parameters
        address actualAddress = factory.createPullPayment(owner, cashers, toAddress, salt);

        // Check that the computed address matches the actual address
        assertEq(computedAddress, actualAddress);
    }

    // Test creating contract
    function testCreatePullPayment() public {
        bytes32 salt = bytes32(uint256(2));
        
        address[] memory cashers = new address[](1);
        cashers[0] = casher;

        // Create contract
        address pullPaymentAddress = factory.createPullPayment(owner, cashers, toAddress, salt);

        // Verify contract was created
        PullPayment pullPayment = PullPayment(pullPaymentAddress);

        // Check owner and cashers are set correctly
        assertEq(pullPayment.owner(), owner);
        
        address[] memory resultCashers = pullPayment.getCashers();
        assertEq(resultCashers.length, 1);
        assertEq(resultCashers[0], casher);
        assertEq(pullPayment.toAddress(), toAddress);
    }

    // Test creating contract with same salt but different parameters
    function testCreatePullPaymentWithSameSalt() public {
        bytes32 salt = bytes32(uint256(3));
        
        address[] memory cashers = new address[](1);
        cashers[0] = casher;

        // Create first contract
        address firstAddress = factory.createPullPayment(owner, cashers, toAddress, salt);
        
        // The test should pass if we try to deploy to the same address
        // CREATE2 will revert if we try to deploy another contract to the same address
        vm.expectRevert();
        factory.createPullPayment(owner, cashers, toAddress, salt);
    }

    // Test creating contract with same parameters but different salt
    function testCreatePullPaymentWithDifferentSalt() public {
        bytes32 salt1 = bytes32(uint256(4));
        bytes32 salt2 = bytes32(uint256(5));
        
        address[] memory cashers = new address[](1);
        cashers[0] = casher;

        // Create first contract
        address address1 = factory.createPullPayment(owner, cashers, toAddress, salt1);

        // Create second contract with same parameters but different salt
        address address2 = factory.createPullPayment(owner, cashers, toAddress, salt2);

        // Verify different addresses
        assertTrue(address1 != address2);
    }

    // Test reverting when owner and casher are the same
    function testCreatePullPaymentRevertsSameOwnerAndCasher() public {
        bytes32 salt = bytes32(uint256(6));
        
        address[] memory cashers = new address[](1);
        cashers[0] = owner;

        // Try to create contract with same owner and casher
        vm.expectRevert("Owner cannot be a casher");
        factory.createPullPayment(owner, cashers, toAddress, salt);
    }

    // Test compute address reverting when owner and casher are the same
    function testComputeAddressRevertsSameOwnerAndCasher() public {
        bytes32 salt = bytes32(uint256(7));
        
        address[] memory cashers = new address[](1);
        cashers[0] = owner;

        // Try to compute address with same owner and casher
        vm.expectRevert("Owner cannot be a casher");
        factory.computePullPaymentAddress(owner, cashers, toAddress, salt);
    }
    
    // Test reverting when casher and toAddress are the same
    function testCreatePullPaymentRevertsSameCasherAndToAddress() public {
        bytes32 salt = bytes32(uint256(8));
        
        address[] memory cashers = new address[](1);
        cashers[0] = toAddress;

        // Try to create contract with same casher and toAddress
        vm.expectRevert("Casher and to address cannot be the same address");
        factory.createPullPayment(owner, cashers, toAddress, salt);
    }
    
    // Test reverting when toAddress is zero
    function testCreatePullPaymentRevertsZeroToAddress() public {
        bytes32 salt = bytes32(uint256(9));
        
        address[] memory cashers = new address[](1);
        cashers[0] = casher;

        // Try to create contract with zero toAddress
        vm.expectRevert("To address cannot be the zero address");
        factory.createPullPayment(owner, cashers, address(0), salt);
    }
    
    // Test reverting when casher is zero
    function testCreatePullPaymentRevertsZeroCasher() public {
        bytes32 salt = bytes32(uint256(10));
        
        address[] memory cashers = new address[](1);
        cashers[0] = address(0);

        // Try to create contract with zero casher
        vm.expectRevert("Casher address cannot be the zero address");
        factory.createPullPayment(owner, cashers, toAddress, salt);
    }
    
    // Test compute address reverting when casher and toAddress are the same
    function testComputeAddressRevertsSameCasherAndToAddress() public {
        bytes32 salt = bytes32(uint256(11));
        
        address[] memory cashers = new address[](1);
        cashers[0] = toAddress;

        // Try to compute address with same casher and toAddress
        vm.expectRevert("Casher and to address cannot be the same address");
        factory.computePullPaymentAddress(owner, cashers, toAddress, salt);
    }
    
    // Test compute address reverting when toAddress is zero
    function testComputeAddressRevertsZeroToAddress() public {
        bytes32 salt = bytes32(uint256(12));
        
        address[] memory cashers = new address[](1);
        cashers[0] = casher;

        // Try to compute address with zero toAddress
        vm.expectRevert("To address cannot be the zero address");
        factory.computePullPaymentAddress(owner, cashers, address(0), salt);
    }
    
    // Test compute address reverting when casher is zero
    function testComputeAddressRevertsZeroCasher() public {
        bytes32 salt = bytes32(uint256(13));
        
        address[] memory cashers = new address[](1);
        cashers[0] = address(0);

        // Try to compute address with zero casher
        vm.expectRevert("Casher address cannot be the zero address");
        factory.computePullPaymentAddress(owner, cashers, toAddress, salt);
    }
    
    // Test events for createPullPayment
    function testCreatePullPaymentEvents() public {
        bytes32 salt = bytes32(uint256(14));
        
        address[] memory cashers = new address[](1);
        cashers[0] = casher;
        
        // First calculate the address that will be created
        address predictedAddress = factory.computePullPaymentAddress(
            owner,
            cashers,
            toAddress,
            salt
        );
        
        // Now set up the expected event with the correct address
        vm.expectEmit(true, true, false, true);
        emit PullPaymentFactory.PullPaymentCreated(predictedAddress, owner, cashers, salt);
        
        // Create the contract
        address pullPaymentAddress = factory.createPullPayment(owner, cashers, toAddress, salt);
        
        // Verify the address matches our prediction
        assertEq(pullPaymentAddress, predictedAddress);
        
        // Verify PullPayment contract was created correctly
        PullPayment pullPayment = PullPayment(pullPaymentAddress);
        assertEq(pullPayment.owner(), owner);
        
        address[] memory resultCashers = pullPayment.getCashers();
        assertEq(resultCashers.length, 1);
        assertEq(resultCashers[0], casher);
        assertEq(pullPayment.toAddress(), toAddress);
    }
}
