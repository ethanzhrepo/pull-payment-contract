// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PullPayment is Ownable {
    event CasherAdded(address indexed casher);
    event CasherRemoved(address indexed casher);
    event CashersSet(address[] cashers);
    event ToAddressSet(
        address indexed previousToAddress,
        address indexed newToAddress
    );

    event Charge(
        address indexed token,
        address indexed fromAddress,
        uint256 amount,
        string billId
    );

    event BatchChargeResult(
        address indexed token,
        uint256 totalAttempts,
        uint256 successCount,
        uint256 failureCount
    );

    event ChargeFailure(
        address indexed token,
        address indexed fromAddress,
        uint256 amount,
        string reason,
        string billId
    );

    address[] private cashers;
    mapping(address => bool) private isCasher;
    address public toAddress;

    constructor(
        address _owner,
        address[] memory _cashers,
        address _toAddress
    ) Ownable(_owner) {
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
            require(_cashers[i] != _owner, "Owner cannot be a casher");
            require(
                _cashers[i] != _toAddress,
                "Casher and to address cannot be the same address"
            );

            cashers.push(_cashers[i]);
            isCasher[_cashers[i]] = true;
        }

        toAddress = _toAddress;
        emit ToAddressSet(address(0), _toAddress);
        emit CashersSet(_cashers);
    }

    // only casher can charge
    modifier onlyCasher() {
        require(isCasher[msg.sender], "Only casher can charge");
        _;
    }

    function getCashers() public view returns (address[] memory) {
        return cashers;
    }

    function addCasher(address _casher) public onlyOwner {
        require(
            _casher != address(0),
            "Casher address cannot be the zero address"
        );
        require(_casher != owner(), "Casher address cannot be the owner");
        require(
            _casher != toAddress,
            "Casher address cannot be the same as the to address"
        );
        require(!isCasher[_casher], "Address is already a casher");

        cashers.push(_casher);
        isCasher[_casher] = true;
        emit CasherAdded(_casher);
    }

    function removeCasher(address _casher) public onlyOwner {
        require(isCasher[_casher], "Address is not a casher");
        require(cashers.length > 1, "Cannot remove the last casher");

        // Find and remove from array
        for (uint256 i = 0; i < cashers.length; i++) {
            if (cashers[i] == _casher) {
                cashers[i] = cashers[cashers.length - 1];
                cashers.pop();
                break;
            }
        }

        isCasher[_casher] = false;
        emit CasherRemoved(_casher);
    }

    function setCashers(address[] memory _cashers) public onlyOwner {
        require(_cashers.length > 0, "At least one casher is required");

        // Clear existing cashers
        for (uint256 i = 0; i < cashers.length; i++) {
            isCasher[cashers[i]] = false;
        }
        delete cashers;

        // Set new cashers
        for (uint256 i = 0; i < _cashers.length; i++) {
            require(
                _cashers[i] != address(0),
                "Casher address cannot be the zero address"
            );
            require(_cashers[i] != owner(), "Owner cannot be a casher");
            require(
                _cashers[i] != toAddress,
                "Casher and to address cannot be the same address"
            );
            require(!isCasher[_cashers[i]], "Duplicate casher address");

            cashers.push(_cashers[i]);
            isCasher[_cashers[i]] = true;
        }

        emit CashersSet(_cashers);
    }

    function setToAddress(address _toAddress) public onlyOwner {
        require(
            _toAddress != address(0),
            "To address cannot be the zero address"
        );

        // Check that the new to address is not a casher
        require(!isCasher[_toAddress], "To address cannot be a casher");

        address previousToAddress = toAddress;
        toAddress = _toAddress;
        emit ToAddressSet(previousToAddress, _toAddress);
    }

    function charge(
        address _token,
        address _fromAddress,
        uint256 _amount,
        string memory _billId
    ) public onlyCasher {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            toAddress != _fromAddress,
            "To address cannot be the same as the from address"
        );

        IERC20 token = IERC20(_token);
        
        // Record balance before transfer
        uint256 toBalanceBefore = token.balanceOf(toAddress);

        bool res = token.transferFrom(_fromAddress, toAddress, _amount);
        
        if (!res) {
            revert("Transfer failed");
        }
        
        // Verify the to address received at least the expected amount
        uint256 toBalanceAfter = token.balanceOf(toAddress);
        if (toBalanceAfter < toBalanceBefore + _amount) {
            revert("Balance verification failed: insufficient amount received");
        }
        
        emit Charge(_token, _fromAddress, _amount, _billId);
    }

    function batchCharge(
        address[] memory _tokens,
        address[] memory _fromAddresses,
        uint256[] memory _amounts,
        string[] memory _billIds
    ) public onlyCasher {
        require(
            _fromAddresses.length == _amounts.length,
            "From addresses and amounts must have the same length"
        );
        require(
            _fromAddresses.length == _billIds.length,
            "From addresses and bill IDs must have the same length"
        );
        require(
            _fromAddresses.length == _tokens.length,
            "From addresses and tokens must have the same length"
        );

        uint256 successCount = 0;
        uint256 failureCount = 0;

        for (uint256 i = 0; i < _fromAddresses.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            
            // Record balance before transfer
            uint256 toBalanceBefore = token.balanceOf(toAddress);
            
            bool transferSucceeded = false;
            string memory failureReason = "";
            
            try token.transferFrom(_fromAddresses[i], toAddress, _amounts[i]) returns (bool success) {
                if (success) {
                    // Verify the to address received at least the expected amount
                    uint256 toBalanceAfter = token.balanceOf(toAddress);
                    
                    if (toBalanceAfter >= toBalanceBefore + _amounts[i]) {
                        transferSucceeded = true;
                    } else {
                        failureReason = "Balance verification failed: insufficient amount received";
                    }
                } else {
                    failureReason = "Transfer returned false";
                }
            } catch Error(string memory reason) {
                failureReason = reason;
            } catch (bytes memory) {
                failureReason = "Transfer reverted";
            }
            
            if (transferSucceeded) {
                successCount++;
                emit Charge(_tokens[i], _fromAddresses[i], _amounts[i], _billIds[i]);
            } else {
                failureCount++;
                emit ChargeFailure(_tokens[i], _fromAddresses[i], _amounts[i], failureReason, _billIds[i]);
            }
        }

        // Note: BatchChargeResult event now doesn't specify a single token since we support multiple tokens
        emit BatchChargeResult(
            address(0), // Use address(0) to indicate multiple tokens were used
            _fromAddresses.length,
            successCount,
            failureCount
        );
    }

    function withdraw(address _token) public onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}
