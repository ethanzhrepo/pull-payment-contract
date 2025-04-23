// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PullPayment} from "../src/PullPayment.sol";
import {PullPaymentFactory} from "../src/PullPaymentFactory.sol";

contract PullPaymentScript is Script {
    PullPayment public pullPayment;

    function setUp() public {}

    function run() public {
        // Get deployment configuration from environment variables
        address ownerAddress = vm.envOr("OWNER_ADDRESS", msg.sender);
        address casherAddress = vm.envOr("CASHER_ADDRESS", address(0));
        require(
            ownerAddress != casherAddress,
            "Owner and casher cannot be the same address"
        );
        address toAddress = vm.envOr("TO_ADDRESS", address(0));
        require(
            casherAddress != toAddress || toAddress == address(0),
            "Casher and to address cannot be the same address"
        );
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Begin broadcast with deployer's private key
        vm.startBroadcast(deployerPrivateKey);

        // Deploy PullPayment contract
        pullPayment = new PullPayment(ownerAddress, casherAddress, toAddress);

        console.log("PullPayment contract deployed at:", address(pullPayment));
        console.log("Owner address:", ownerAddress);
        console.log("Casher address:", casherAddress);
        console.log("To address:", toAddress);

        vm.stopBroadcast();
    }
}

contract PullPaymentFactoryScript is Script {
    PullPaymentFactory public factory;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Begin broadcast with deployer's private key
        vm.startBroadcast(deployerPrivateKey);

        // Deploy PullPaymentFactory contract
        factory = new PullPaymentFactory();

        console.log("PullPaymentFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}

contract CreatePullPaymentScript is Script {
    PullPaymentFactory public factory;

    function setUp() public {}

    function run() public {
        // Get factory address and creation parameters
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        address ownerAddress = vm.envAddress("OWNER_ADDRESS");
        address casherAddress = vm.envAddress("CASHER_ADDRESS");
        address toAddress = vm.envAddress("TO_ADDRESS");
        bytes32 salt = bytes32(vm.envUint("SALT"));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Begin broadcast with deployer's private key
        vm.startBroadcast(deployerPrivateKey);

        // Get factory instance
        factory = PullPaymentFactory(factoryAddress);

        // Compute address
        address predictedAddress = factory.computePullPaymentAddress(
            ownerAddress,
            casherAddress,
            toAddress,
            salt
        );
        console.log("Predicted Subscribe address:", predictedAddress);

        // Create PullPayment contract
        address pullPaymentAddress = factory.createPullPayment(
            ownerAddress,
            casherAddress,
            toAddress,
            salt
        );

        console.log("PullPayment contract created at:", pullPaymentAddress);
        console.log("Owner address:", ownerAddress);
        console.log("Casher address:", casherAddress);
        console.log("To address:", toAddress);

        vm.stopBroadcast();
    }
}

// Deploy script with constructor arguments
contract PullPaymentWithArgsScript is Script {
    PullPayment public pullPayment;

    function setUp() public {}

    function run() public {
        // Get deployment configuration from environment variables
        address casherAddress = vm.envOr("CASHER_ADDRESS", address(0));
        address toAddress = vm.envOr("TO_ADDRESS", address(0));
        require(
            msg.sender != casherAddress,
            "Owner and casher cannot be the same address"
        );
        require(
            casherAddress != toAddress || toAddress == address(0),
            "Casher and to address cannot be the same address"
        );
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Begin broadcast with deployer's private key
        vm.startBroadcast(deployerPrivateKey);

        // Deploy PullPayment contract
        pullPayment = new PullPayment(msg.sender, casherAddress, toAddress);

        console.log("PullPayment contract deployed at:", address(pullPayment));
        console.log("Casher address set to:", casherAddress);
        console.log("Recipient address set to:", toAddress);

        vm.stopBroadcast();
    }
}

// Update script for existing contract
contract UpdatePullPaymentScript is Script {
    function setUp() public {}

    function run() public {
        // Get configuration from environment variables
        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");
        address casherAddress = vm.envOr("CASHER_ADDRESS", address(0));
        address toAddress = vm.envOr("TO_ADDRESS", address(0));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Begin broadcast with deployer's private key
        vm.startBroadcast(deployerPrivateKey);

        // Get existing contract instance
        PullPayment pullPayment = PullPayment(contractAddress);

        // Update configuration if provided
        if (casherAddress != address(0)) {
            pullPayment.setCasherAddress(casherAddress);
            console.log("Casher address updated to:", casherAddress);
        }

        if (toAddress != address(0)) {
            pullPayment.setToAddress(toAddress);
            console.log("Recipient address updated to:", toAddress);
        }

        vm.stopBroadcast();
    }
}
