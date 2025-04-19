// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Subscribe} from "../src/Subscribe.sol";
import {SubscribeFactory} from "../src/SubscribeFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing
contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract SubscribeTest is Test {
    Subscribe public subscribe;
    MockToken public token;
    address public owner;
    address public casher;
    address public recipient;
    address public user1;
    address public user2;

    // Setup test variables and environment
    function setUp() public {
        owner = address(this);
        casher = makeAddr("casher");
        recipient = makeAddr("recipient");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        subscribe = new Subscribe(owner, casher, recipient);
        token = new MockToken();

        // Transfer tokens to test users
        uint256 amount = 1000 * 10 ** 18;
        token.transfer(user1, amount);
        token.transfer(user2, amount);
    }

    // Test constructor sets owner and casher correctly
    function testConstructor() public {
        Subscribe newSubscribe = new Subscribe(user1, user2, recipient);
        assertEq(newSubscribe.owner(), user1);
        assertEq(newSubscribe.casherAddress(), user2);
        assertEq(newSubscribe.toAddress(), recipient);
    }

    // Test constructor reverts when owner and casher are the same
    function testConstructorRevertsSameOwnerAndCasher() public {
        vm.expectRevert("Owner and casher cannot be the same address");
        new Subscribe(user1, user1, recipient);
    }
    
    // Test constructor reverts when casher and to address are the same
    function testConstructorRevertsSameCasherAndToAddress() public {
        vm.expectRevert("Casher and to address cannot be the same address");
        new Subscribe(user1, user2, user2);
    }
    
    // Test constructor reverts when to address is zero
    function testConstructorRevertsZeroToAddress() public {
        vm.expectRevert("To address cannot be the zero address");
        new Subscribe(user1, user2, address(0));
    }
    
    // Test constructor reverts when casher address is zero
    function testConstructorRevertsZeroCasherAddress() public {
        vm.expectRevert("Casher address cannot be the zero address");
        new Subscribe(user1, address(0), recipient);
    }

    // Test setting casher address
    function testSetCasherAddress() public {
        address newCasher = makeAddr("newCasher");
        subscribe.setCasherAddress(newCasher);
        assertEq(subscribe.casherAddress(), newCasher);
    }

    // Test setting recipient address
    function testSetToAddress() public {
        address newRecipient = makeAddr("newRecipient");
        subscribe.setToAddress(newRecipient);
        assertEq(subscribe.toAddress(), newRecipient);
    }
    
    // Test setting casher address to zero address
    function testSetCasherAddressRevertsZeroAddress() public {
        vm.expectRevert("Casher address cannot be the zero address");
        subscribe.setCasherAddress(address(0));
    }
    
    // Test setting toAddress to zero address
    function testSetToAddressRevertsZeroAddress() public {
        vm.expectRevert("To address cannot be the zero address");
        subscribe.setToAddress(address(0));
    }
    
    // Test setting casher address to the same as toAddress
    function testSetCasherAddressRevertsSameAsToAddress() public {
        vm.expectRevert("Casher address cannot be the same as the to address");
        subscribe.setCasherAddress(recipient);
    }
    
    // Test setting toAddress to the same as casher
    function testSetToAddressRevertsSameAsCasher() public {
        vm.expectRevert("To address cannot be the same as the casher address");
        subscribe.setToAddress(casher);
    }
    
    // Test setting casher address to owner address
    function testSetCasherAddressRevertsOwnerAddress() public {
        vm.expectRevert("Casher address cannot be the owner");
        subscribe.setCasherAddress(owner);
    }

    // Test that only owner can set casher address
    function testOnlyOwnerCanSetCasherAddress() public {
        vm.prank(user1);
        vm.expectRevert();
        subscribe.setCasherAddress(user1);
    }

    // Test that only owner can set recipient address
    function testOnlyOwnerCanSetToAddress() public {
        vm.prank(user1);
        vm.expectRevert();
        subscribe.setToAddress(user1);
    }

    // Test single charge
    function testCharge() public {
        uint256 amount = 100 * 10 ** 18;

        // Approve contract to spend tokens
        vm.startPrank(user1);
        token.approve(address(subscribe), amount);
        vm.stopPrank();

        uint256 recipientBalanceBefore = token.balanceOf(recipient);
        uint256 user1BalanceBefore = token.balanceOf(user1);

        // Execute charge
        vm.prank(casher);
        subscribe.charge(address(token), user1, amount);

        // Verify balances
        assertEq(token.balanceOf(recipient), recipientBalanceBefore + amount);
        assertEq(token.balanceOf(user1), user1BalanceBefore - amount);
    }

    // Test that only casher can charge
    function testOnlyCasherCanCharge() public {
        uint256 amount = 100 * 10 ** 18;

        // Approve contract to spend tokens
        vm.startPrank(user1);
        token.approve(address(subscribe), amount);

        // Try to charge as user1 (should fail)
        vm.expectRevert("Only casher can charge");
        subscribe.charge(address(token), user1, amount);
        vm.stopPrank();

        // Try to charge as owner (should fail)
        vm.expectRevert("Only casher can charge");
        subscribe.charge(address(token), user1, amount);
    }

    // Test charge with zero amount
    function testChargeWithZeroAmount() public {
        vm.prank(casher);
        vm.expectRevert("Amount must be greater than 0");
        subscribe.charge(address(token), user1, 0);
    }

    // Test charge with same from and to address
    function testChargeWithSameFromAndToAddress() public {
        // Set recipient to user1
        subscribe.setToAddress(user1);

        vm.prank(casher);
        vm.expectRevert("To address cannot be the same as the from address");
        subscribe.charge(address(token), user1, 100);
    }

    // Test charge with insufficient balance
    function testChargeWithInsufficientBalance() public {
        uint256 tooMuchAmount = 2000 * 10 ** 18; // More than user has

        vm.prank(casher);
        vm.expectRevert();
        subscribe.charge(address(token), user1, tooMuchAmount);
    }

    // Test charge with insufficient allowance
    function testChargeWithInsufficientAllowance() public {
        uint256 amount = 100 * 10 ** 18;

        // No approval given
        vm.prank(casher);
        vm.expectRevert();
        subscribe.charge(address(token), user1, amount);
    }

    // Test batch charge
    function testBatchCharge() public {
        uint256 amount1 = 100 * 10 ** 18;
        uint256 amount2 = 200 * 10 ** 18;

        // Approve contract to spend tokens
        vm.startPrank(user1);
        token.approve(address(subscribe), amount1);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(subscribe), amount2);
        vm.stopPrank();

        uint256 recipientBalanceBefore = token.balanceOf(recipient);
        uint256 user1BalanceBefore = token.balanceOf(user1);
        uint256 user2BalanceBefore = token.balanceOf(user2);

        // Execute batch charge
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount1;
        amounts[1] = amount2;

        vm.prank(casher);
        subscribe.batchCharge(address(token), users, amounts);

        // Verify balances
        assertEq(
            token.balanceOf(recipient),
            recipientBalanceBefore + amount1 + amount2
        );
        assertEq(token.balanceOf(user1), user1BalanceBefore - amount1);
        assertEq(token.balanceOf(user2), user2BalanceBefore - amount2);
    }

    // Test batch charge with array length mismatch
    function testBatchChargeWithArrayLengthMismatch() public {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.prank(casher);
        vm.expectRevert("From addresses and amounts must have the same length");
        subscribe.batchCharge(address(token), users, amounts);
    }

    // Test withdraw function
    function testWithdraw() public {
        // Transfer some tokens to the contract
        uint256 amount = 100 * 10 ** 18;
        token.transfer(address(subscribe), amount);

        uint256 ownerBalanceBefore = token.balanceOf(owner);

        // Execute withdraw
        subscribe.withdraw(address(token));

        // Verify balances
        assertEq(token.balanceOf(owner), ownerBalanceBefore + amount);
        assertEq(token.balanceOf(address(subscribe)), 0);
    }

    // Test that only owner can withdraw
    function testOnlyOwnerCanWithdraw() public {
        vm.prank(user1);
        vm.expectRevert();
        subscribe.withdraw(address(token));
    }
    
    // Test event emission for setCasherAddress
    function testSetCasherAddressEvent() public {
        address newCasher = makeAddr("newCasher");
        vm.expectEmit(true, true, false, true);
        emit Subscribe.CasherAddressSet(casher, newCasher);
        subscribe.setCasherAddress(newCasher);
    }
    
    // Test event emission for setToAddress
    function testSetToAddressEvent() public {
        address newToAddress = makeAddr("newToAddress");
        vm.expectEmit(true, true, false, true);
        emit Subscribe.ToAddressSet(recipient, newToAddress);
        subscribe.setToAddress(newToAddress);
    }
    
    // Test event emission for charge
    function testChargeEvent() public {
        uint256 amount = 100 * 10 ** 18;
        
        // Approve contract to spend tokens
        vm.startPrank(user1);
        token.approve(address(subscribe), amount);
        vm.stopPrank();
        
        vm.expectEmit(true, true, false, true);
        emit Subscribe.Charge(address(token), user1, amount);
        
        vm.prank(casher);
        subscribe.charge(address(token), user1, amount);
    }
}
