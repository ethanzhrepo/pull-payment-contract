// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Subscribe} from "../src/Subscribe.sol";
import {SubscribeFactory} from "../src/SubscribeFactory.sol";

contract SubscribeScript is Script {
    Subscribe public subscribe;

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

        // Deploy Subscribe contract
        subscribe = new Subscribe(ownerAddress, casherAddress, toAddress);

        console.log("Subscribe contract deployed at:", address(subscribe));
        console.log("Owner address:", ownerAddress);
        console.log("Casher address:", casherAddress);
        console.log("To address:", toAddress);

        vm.stopBroadcast();
    }
}

contract SubscribeFactoryScript is Script {
    SubscribeFactory public factory;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Begin broadcast with deployer's private key
        vm.startBroadcast(deployerPrivateKey);

        // Deploy SubscribeFactory contract
        factory = new SubscribeFactory();

        console.log("SubscribeFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}

contract CreateSubscribeScript is Script {
    SubscribeFactory public factory;

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
        factory = SubscribeFactory(factoryAddress);

        // Compute address
        address predictedAddress = factory.computeSubscribeAddress(
            ownerAddress,
            casherAddress,
            toAddress,
            salt
        );
        console.log("Predicted Subscribe address:", predictedAddress);

        // Create Subscribe contract
        address subscribeAddress = factory.createSubscribe(
            ownerAddress,
            casherAddress,
            toAddress,
            salt
        );

        console.log("Subscribe contract created at:", subscribeAddress);
        console.log("Owner address:", ownerAddress);
        console.log("Casher address:", casherAddress);
        console.log("To address:", toAddress);

        vm.stopBroadcast();
    }
}

// Deploy script with constructor arguments
contract SubscribeWithArgsScript is Script {
    Subscribe public subscribe;

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

        // Deploy Subscribe contract
        subscribe = new Subscribe(msg.sender, casherAddress, toAddress);

        console.log("Subscribe contract deployed at:", address(subscribe));
        console.log("Casher address set to:", casherAddress);
        console.log("Recipient address set to:", toAddress);

        vm.stopBroadcast();
    }
}

// Update script for existing contract
contract UpdateSubscribeScript is Script {
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
        Subscribe subscribe = Subscribe(contractAddress);

        // Update configuration if provided
        if (casherAddress != address(0)) {
            subscribe.setCasherAddress(casherAddress);
            console.log("Casher address updated to:", casherAddress);
        }

        if (toAddress != address(0)) {
            subscribe.setToAddress(toAddress);
            console.log("Recipient address updated to:", toAddress);
        }

        vm.stopBroadcast();
    }
}
