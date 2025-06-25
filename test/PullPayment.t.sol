// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PullPayment} from "../src/PullPayment.sol";
import {PullPaymentFactory} from "../src/PullPaymentFactory.sol";
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

contract PullPaymentTest is Test {
    PullPayment public pullPayment;
    MockToken public token;
    address public owner;
    address public casher;
    address public casher2;
    address public recipient;
    address public user1;
    address public user2;

    // Setup test variables and environment
    function setUp() public {
        owner = address(this);
        casher = makeAddr("casher");
        casher2 = makeAddr("casher2");
        recipient = makeAddr("recipient");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        address[] memory cashers = new address[](1);
        cashers[0] = casher;
        pullPayment = new PullPayment(owner, cashers, recipient);
        token = new MockToken();

        // Transfer tokens to test users
        uint256 amount = 1000 * 10 ** 18;
        token.transfer(user1, amount);
        token.transfer(user2, amount);
    }

    // Test constructor sets owner and cashers correctly
    function testConstructor() public {
        address[] memory cashers = new address[](1);
        cashers[0] = user2;
        PullPayment newPullPayment = new PullPayment(user1, cashers, recipient);
        assertEq(newPullPayment.owner(), user1);
        
        address[] memory resultCashers = newPullPayment.getCashers();
        assertEq(resultCashers.length, 1);
        assertEq(resultCashers[0], user2);
        assertEq(newPullPayment.toAddress(), recipient);
    }

    // Test constructor reverts when owner and casher are the same
    function testConstructorRevertsSameOwnerAndCasher() public {
        address[] memory cashers = new address[](1);
        cashers[0] = user1;
        vm.expectRevert("Owner cannot be a casher");
        new PullPayment(user1, cashers, recipient);
    }
    
    // Test constructor reverts when casher and to address are the same
    function testConstructorRevertsSameCasherAndToAddress() public {
        address[] memory cashers = new address[](1);
        cashers[0] = user2;
        vm.expectRevert("Casher and to address cannot be the same address");
        new PullPayment(user1, cashers, user2);
    }
    
    // Test constructor reverts when to address is zero
    function testConstructorRevertsZeroToAddress() public {
        address[] memory cashers = new address[](1);
        cashers[0] = user2;
        vm.expectRevert("To address cannot be the zero address");
        new PullPayment(user1, cashers, address(0));
    }
    
    // Test constructor reverts when casher address is zero
    function testConstructorRevertsZeroCasherAddress() public {
        address[] memory cashers = new address[](1);
        cashers[0] = address(0);
        vm.expectRevert("Casher address cannot be the zero address");
        new PullPayment(user1, cashers, recipient);
    }

    // Test constructor reverts when no cashers provided
    function testConstructorRevertsNoCashers() public {
        address[] memory cashers = new address[](0);
        vm.expectRevert("At least one casher is required");
        new PullPayment(user1, cashers, recipient);
    }

    // Test adding casher
    function testAddCasher() public {
        address newCasher = makeAddr("newCasher");
        pullPayment.addCasher(newCasher);
        
        address[] memory cashers = pullPayment.getCashers();
        assertEq(cashers.length, 2);
        assertEq(cashers[1], newCasher);
    }

    // Test removing casher
    function testRemoveCasher() public {
        // First add another casher so we can remove one
        address newCasher = makeAddr("newCasher");
        pullPayment.addCasher(newCasher);
        
        // Now remove the original casher
        pullPayment.removeCasher(casher);
        
        address[] memory cashers = pullPayment.getCashers();
        assertEq(cashers.length, 1);
        assertEq(cashers[0], newCasher);
    }

    // Test setting multiple cashers
    function testSetCashers() public {
        address[] memory newCashers = new address[](2);
        newCashers[0] = makeAddr("newCasher1");
        newCashers[1] = makeAddr("newCasher2");
        
        pullPayment.setCashers(newCashers);
        
        address[] memory resultCashers = pullPayment.getCashers();
        assertEq(resultCashers.length, 2);
        assertEq(resultCashers[0], newCashers[0]);
        assertEq(resultCashers[1], newCashers[1]);
    }

    // Test setting recipient address
    function testSetToAddress() public {
        address newRecipient = makeAddr("newRecipient");
        pullPayment.setToAddress(newRecipient);
        assertEq(pullPayment.toAddress(), newRecipient);
    }
    
    // Test adding casher with zero address
    function testAddCasherRevertsZeroAddress() public {
        vm.expectRevert("Casher address cannot be the zero address");
        pullPayment.addCasher(address(0));
    }
    
    // Test setting toAddress to zero address
    function testSetToAddressRevertsZeroAddress() public {
        vm.expectRevert("To address cannot be the zero address");
        pullPayment.setToAddress(address(0));
    }
    
    // Test adding casher that is the same as toAddress
    function testAddCasherRevertsSameAsToAddress() public {
        vm.expectRevert("Casher address cannot be the same as the to address");
        pullPayment.addCasher(recipient);
    }
    
    // Test setting toAddress to an existing casher
    function testSetToAddressRevertsExistingCasher() public {
        vm.expectRevert("To address cannot be a casher");
        pullPayment.setToAddress(casher);
    }
    
    // Test adding casher with owner address
    function testAddCasherRevertsOwnerAddress() public {
        vm.expectRevert("Casher address cannot be the owner");
        pullPayment.addCasher(owner);
    }

    // Test that only owner can add casher
    function testOnlyOwnerCanAddCasher() public {
        vm.prank(user1);
        vm.expectRevert();
        pullPayment.addCasher(user1);
    }

    // Test that only owner can set recipient address
    function testOnlyOwnerCanSetToAddress() public {
        vm.prank(user1);
        vm.expectRevert();
        pullPayment.setToAddress(user1);
    }

    // Test single charge
    function testCharge() public {
        uint256 amount = 100 * 10 ** 18;

        // Approve contract to spend tokens
        vm.startPrank(user1);
        token.approve(address(pullPayment), amount);
        vm.stopPrank();

        uint256 recipientBalanceBefore = token.balanceOf(recipient);
        uint256 user1BalanceBefore = token.balanceOf(user1);

        // Execute charge
        vm.prank(casher);
        pullPayment.charge(address(token), user1, amount, "BILL-001");

        // Verify balances
        assertEq(token.balanceOf(recipient), recipientBalanceBefore + amount);
        assertEq(token.balanceOf(user1), user1BalanceBefore - amount);
    }

    // Test that only casher can charge
    function testOnlyCasherCanCharge() public {
        uint256 amount = 100 * 10 ** 18;

        // Approve contract to spend tokens
        vm.startPrank(user1);
        token.approve(address(pullPayment), amount);

        // Try to charge as user1 (should fail)
        vm.expectRevert("Only casher can charge");
        pullPayment.charge(address(token), user1, amount, "BILL-002");
        vm.stopPrank();

        // Try to charge as owner (should fail)
        vm.expectRevert("Only casher can charge");
        pullPayment.charge(address(token), user1, amount, "BILL-003");
    }

    // Test charge with zero amount
    function testChargeWithZeroAmount() public {
        vm.prank(casher);
        vm.expectRevert("Amount must be greater than 0");
        pullPayment.charge(address(token), user1, 0, "BILL-004");
    }

    // Test charge with same from and to address
    function testChargeWithSameFromAndToAddress() public {
        // Set recipient to user1
        pullPayment.setToAddress(user1);

        vm.prank(casher);
        vm.expectRevert("To address cannot be the same as the from address");
        pullPayment.charge(address(token), user1, 100, "BILL-005");
    }

    // Test charge with insufficient balance
    function testChargeWithInsufficientBalance() public {
        uint256 tooMuchAmount = 2000 * 10 ** 18; // More than user has

        vm.prank(casher);
        vm.expectRevert();
        pullPayment.charge(address(token), user1, tooMuchAmount, "BILL-006");
    }

    // Test charge with insufficient allowance
    function testChargeWithInsufficientAllowance() public {
        uint256 amount = 100 * 10 ** 18;

        // No approval given
        vm.prank(casher);
        vm.expectRevert();
        pullPayment.charge(address(token), user1, amount, "BILL-007");
    }

    // Test batch charge
    function testBatchCharge() public {
        uint256 amount1 = 100 * 10 ** 18;
        uint256 amount2 = 200 * 10 ** 18;

        // Approve contract to spend tokens
        vm.startPrank(user1);
        token.approve(address(pullPayment), amount1);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(pullPayment), amount2);
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

        string[] memory billIds = new string[](2);
        billIds[0] = "BILL-USER1-001";
        billIds[1] = "BILL-USER2-001";

        vm.prank(casher);
        pullPayment.batchCharge(address(token), users, amounts, billIds);

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

        string[] memory billIds = new string[](2);
        billIds[0] = "BILL-001";
        billIds[1] = "BILL-002";

        vm.prank(casher);
        vm.expectRevert("From addresses and amounts must have the same length");
        pullPayment.batchCharge(address(token), users, amounts, billIds);
    }

    // Test batch charge with bill IDs array length mismatch
    function testBatchChargeWithBillIdsLengthMismatch() public {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        string[] memory billIds = new string[](1);
        billIds[0] = "BILL-001";

        vm.prank(casher);
        vm.expectRevert("From addresses and bill IDs must have the same length");
        pullPayment.batchCharge(address(token), users, amounts, billIds);
    }

    // Test withdraw function
    function testWithdraw() public {
        // Transfer some tokens to the contract
        uint256 amount = 100 * 10 ** 18;
        token.transfer(address(pullPayment), amount);

        uint256 ownerBalanceBefore = token.balanceOf(owner);

        // Execute withdraw
        pullPayment.withdraw(address(token));

        // Verify balances
        assertEq(token.balanceOf(owner), ownerBalanceBefore + amount);
        assertEq(token.balanceOf(address(pullPayment)), 0);
    }

    // Test that only owner can withdraw
    function testOnlyOwnerCanWithdraw() public {
        vm.prank(user1);
        vm.expectRevert();
        pullPayment.withdraw(address(token));
    }
    
    // Test event emission for addCasher
    function testAddCasherEvent() public {
        address newCasher = makeAddr("newCasher");
        vm.expectEmit(true, false, false, true);
        emit PullPayment.CasherAdded(newCasher);
        pullPayment.addCasher(newCasher);
    }
    
    // Test event emission for setToAddress
    function testSetToAddressEvent() public {
        address newToAddress = makeAddr("newToAddress");
        vm.expectEmit(true, true, false, true);
        emit PullPayment.ToAddressSet(recipient, newToAddress);
        pullPayment.setToAddress(newToAddress);
    }
    
    // Test event emission for charge
    function testChargeEvent() public {
        uint256 amount = 100 * 10 ** 18;
        string memory billId = "BILL-EVENT-001";
        
        // Approve contract to spend tokens
        vm.startPrank(user1);
        token.approve(address(pullPayment), amount);
        vm.stopPrank();
        
        vm.expectEmit(true, true, false, true);
        emit PullPayment.Charge(address(token), user1, amount, billId);
        
        vm.prank(casher);
        pullPayment.charge(address(token), user1, amount, billId);
    }
}
