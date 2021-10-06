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
    modifier txnExists(uint256 _txn) {
        require(_txn < transactions.length, "Transaction does not exist.");
        _;
    }
    modifier txnNConfirmed(uint256 _txn) {
        require(
            confirms[_txn][msg.sender] = false,
            "Transaction already confirmed."
        );
        _;
    }
    modifier txnNExecuted(uint256 _txn) {
        require(!transactions[_txn].executed, "Transaction already executed.");
        _;
    }

    //Events
    event submitTransaction(
        address indexed owner,
        uint256 indexed txnIndex,
        address indexed to,
        uint256 amount,
        bytes data
    );
    event confirmTransaction(address indexed owner, uint256 indexed txnIndex);
    event revokeTransaction(address indexed owner, uint256 indexed txnIndex);
    event executeTransaction(address indexed owner, uint256 indexed txnIndex);
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
        uint256 txn = transactions.length;
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
        confirms[txn][msg.sender] = true;
        emit submitTransaction(msg.sender, txn, _receiver, _amount, _data);
    }

    function confirm(uint256 _txn)
        public
        Owner
        txnExists(_txn)
        txnNConfirmed(_txn)
        txnNExecuted(_txn)
    {
        Transaction storage transaction = transactions[_txn];
        transaction.signatureCount += 1;
        confirms[_txn][msg.sender] = true;
        emit confirmTransaction(msg.sender, _txn);
    }

    function revoke(uint256 _txn) public Owner txnExists(_txn) {
        Transaction storage transaction = transactions[_txn];
        require(
            confirms[_txn][msg.sender] = true,
            "Transaction not previously confirmed."
        );
        transaction.signatureCount -= 1;
        confirms[_txn][msg.sender] = false;
        emit revokeTransaction(msg.sender, _txn);
    }

    function execute(uint256 _txn)
        public
        Owner
        txnExists(_txn)
        txnNExecuted(_txn)
    {
        Transaction storage transaction = transactions[_txn];
        require(
            transaction.signatureCount >= confirmationsReq,
            "Minimum consensus not yet reached to execute."
        );
        (bool success, ) = transaction.to.call{value: transaction.amount}(
            transaction.data
        );
        require(success, "Transaction did not execute.");
        transaction.executed = true;
        emit executeTransaction(msg.sender, _txn);
    }

    function getTransaction(uint256 _txn)
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
        Transaction storage transaction = transactions[_txn];
        return (
            transaction.requester,
            transaction.to,
            transaction.amount,
            transaction.data,
            transaction.signatureCount,
            transaction.executed
        );
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }
}
