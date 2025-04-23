// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PullPaymentFactory} from "../src/PullPaymentFactory.sol";
import {PullPayment} from "../src/PullPayment.sol";

contract PullPaymentFactoryDeployer is Script {
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

contract PullPaymentDeployer is Script {
    PullPaymentFactory public factory;

    function setUp() public {}

    function run() public {
        // Get deployment configuration from environment variables
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

        // Calculate the predicted address
        address predictedAddress = factory.computePullPaymentAddress(
            ownerAddress,
            casherAddress,
            toAddress,
            salt
        );
        console.log("Predicted PullPayment contract address:", predictedAddress);

        // Deploy Subscribe contract through factory
        address pullPaymentAddress = factory.createPullPayment(
            ownerAddress,
            casherAddress,
            toAddress,
            salt
        );

        console.log("PullPayment contract deployed at:", pullPaymentAddress);
        console.log("Owner:", ownerAddress);
        console.log("Casher:", casherAddress);
        console.log("To Address:", toAddress);

        vm.stopBroadcast();
    }
}

contract PullPaymentAddressCalculator is Script {
    PullPaymentFactory public factory;

    function setUp() public {}

    function run() public {
        // Get parameters from environment variables
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        address ownerAddress = vm.envAddress("OWNER_ADDRESS");
        address casherAddress = vm.envAddress("CASHER_ADDRESS");
        address toAddress = vm.envAddress("TO_ADDRESS");
        bytes32 salt = bytes32(vm.envUint("SALT"));

        // No broadcast needed for this script as it's read-only

        // Get factory instance
        factory = PullPaymentFactory(factoryAddress);

        // Calculate the predicted address
        address predictedAddress = factory.computePullPaymentAddress(
            ownerAddress,
            casherAddress,
            toAddress,
            salt
        );

        console.log("Calculated PullPayment contract address:");
        console.log("  Factory:", factoryAddress);
        console.log("  Owner:", ownerAddress);
        console.log("  Casher:", casherAddress);
        console.log("  To Address:", toAddress);
        console.log("  Salt (as uint):", uint256(salt));
        console.log("  Predicted address:", predictedAddress);
    }
}

contract MultipleSaltCalculator is Script {
    PullPaymentFactory public factory;

    function setUp() public {}

    function run() public {
        // Get parameters from environment variables
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        address ownerAddress = vm.envAddress("OWNER_ADDRESS");
        address casherAddress = vm.envAddress("CASHER_ADDRESS");
        address toAddress = vm.envAddress("TO_ADDRESS");
        uint256 startSalt = vm.envUint("START_SALT");
        uint256 count = vm.envOr("COUNT", uint256(10)); // Default to 10 calculations

        // No broadcast needed for this script as it's read-only

        // Get factory instance
        factory = PullPaymentFactory(factoryAddress);

        console.log("Calculating PullPayment contract addresses:");
        console.log("  Factory:", factoryAddress);
        console.log("  Owner:", ownerAddress);
        console.log("  Casher:", casherAddress);
        console.log("  To Address:", toAddress);

        // Calculate addresses for multiple salts
        for (uint256 i = 0; i < count; i++) {
            bytes32 salt = bytes32(startSalt + i);
            address predictedAddress = factory.computePullPaymentAddress(
                ownerAddress,
                casherAddress,
                toAddress,
                salt
            );

            console.log("Salt", startSalt + i, "->", predictedAddress);
        }
    }
}
