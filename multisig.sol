// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.5;

contract multiSigWallet {
    //Variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public confirmationsReq;
    mapping(uint256 => mapping(address => bool)) public confirms;
    struct Transaction {
        address requester;
        address to;
        uint256 amount;
        bytes data;
        uint8 signatureCount;
        bool executed;
    }
    Transaction[] public transactions;

    //Modifiers
    modifier Owner() {
        require(isOwner[msg.sender], "Not authorized owner");
        _;
    }
    modifier txExists(uint256 _tx) {
        require(_tx < transactions.length, "Transaction does not exist.");
        _;
    }
    modifier txNConfirmed(uint256 _tx) {
        require(
            confirms[_tx][msg.sender] = false,
            "Transaction already confirmed."
        );
        _;
    }
    modifier txNExecuted(uint256 _tx) {
        require(!transactions[_tx].executed, "Transaction already executed.");
        _;
    }

    //Events
    event submitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 amount,
        bytes data
    );
    event confirmTransaction(address indexed owner, uint256 indexed txIndex);
    event revokeTransaction(address indexed owner, uint256 indexed txIndex);
    event executeTransaction(address indexed owner, uint256 indexed txIndex);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    // Constructor
    constructor(address[] memory _owners, uint256 _confirmations) {
        require(_owners.length != 0, "Addresses of Owners are required.");
        require(
            _confirmations <= owners.length,
            "Invalid number of confirmations."
        );
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Owner Can not be Null address.");
            require(!isOwner[_owners[i]], "Address is already an owner.");
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }
        confirmationsReq = _confirmations;
    }

    // Functions
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function Submit(
        address _receiver,
        uint256 _amount,
        bytes memory _data
    ) public Owner {
        uint256 tx = transactions.length;
        transactions.push(
            Transaction({
                requester: msg.sender,
                to: _receiver,
                amount: _amount,
                data: _data,
                signatureCount: 1,
                executed: false
            })
        );
        confirms[tx][msg.sender] = true;
        emit submitTransaction(msg.sender, tx, _receiver, _amount, _data);
    }

    function confirm(uint256 _tx)
        public
        Owner
        txExists(_tx)
        txNConfirmed(_tx)
        txNExecuted(_tx)
    {
        Transaction storage transaction = transactions[_tx];
        transaction.signatureCount += 1;
        confirms[_tx][msg.sender] = true;
        emit confirmTransaction(msg.sender, _tx);
    }

    function revoke(uint256 _tx) public Owner txExists(_tx) {
        Transaction storage transaction = transactions[_tx];
        require(
            confirms[_tx][msg.sender] = true,
            "Transaction not previously confirmed."
        );
        transaction.signatureCount -= 1;
        confirms[_tx][msg.sender] = false;
        emit revokeTransaction(msg.sender, _tx);
    }

    function execute(uint256 _tx) public Owner txExists(_tx) txNExecuted(_tx) {
        Transaction storage transaction = transactions[_tx];
        require(
            transaction.signatureCount >= confirmationsReq,
            "Minimum consensus not yet reached to execute."
        );
        (bool success, ) = transaction.to.call{value: transaction.amount}(
            transaction.data
        );
        require(success, "Transaction did not execute.");
        transaction.executed = true;
        emit executeTransaction(msg.sender, _tx);
    }

    function getTransaction(uint256 _tx)
        public
        view
        returns (
            address requester,
            address to,
            uint256 amount,
            bytes memory data,
            uint8 signatureCount,
            bool executed
        )
    {
        Transaction storage transaction = transactions[_tx];
        return (
            transaction.requester,
            transaction.to,
            transaction.amount,
            transaction.data,
            transaction.signatureCount,
            transaction.executed
        );
    }

    function getTransactionCount(uint256 _tx) public view returns (int256) {
        return transactions.length;
    }
}
