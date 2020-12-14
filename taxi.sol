pragma solidity ^0.7.0;

contract Taxi {
    
    address managerAddress;
    address payable carDealerAddress;
    uint fixedExpenses;
    uint participationFee;
    uint participantsCount;
    
    struct TaxiDriver {
        address payable driverAddress;
        uint salary;
        uint approvalState;
    }
    struct ProposedCar {
        uint carID;
        uint price;
        uint proposeTime;
        uint validTime;
        uint approvalState;
    }
    
    ProposedCar proposedCar;
    TaxiDriver proposedDriver;
    TaxiDriver settedDriver;
    mapping(address => bool) carApproves;
    mapping(address => bool) driverApproves;
    mapping(address => uint) participants;
    
    
    
    constructor () {
        managerAddress = msg.sender;
        fixedExpenses = 2 ether;
        participationFee = 10 ether;
    }
    
    
    function join() external payable {
        require(msg.value == participationFee, "You must pay exactly 10 ether to join contract");
        if(participants[msg.sender] != 0){
            revert("You already join the contract");
        }
        participants[msg.sender] += participationFee;
        participantsCount += 1;
    }
    function contractBalance() external view returns(uint){
        return address(this).balance;
    }
    function setCarDealer(address payable dealerAddress) external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        carDealerAddress = dealerAddress;
    }
    function carProposeToBusiness(uint carID, uint price, uint validTime) public {
        require(msg.sender == carDealerAddress, "This function can be called from car dealer only.");
        proposedCar = ProposedCar(carID, price, block.timestamp, validTime, 0);
    }
    function approvePurchaseCar() external {
        require(!carApproves[msg.sender], "You already approved the proposed car.");
        if(participants[msg.sender] == 0){
            revert("You must participate the contract for this action.");
        }
        carApproves[msg.sender] = true;
        proposedCar.approvalState += 1;
    }
    function purchaseCar() external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        if(proposedCar.approvalState > participantsCount / 2){
            carDealerAddress.transfer(proposedCar.price * 1 ether);
        }
        else if(proposedCar.price == 0){
            revert("There is no proposed car to purchase");
        }
        else{
            revert("Valid Time exceed or approvalState is less than half of the participants");
        }
    }
    function repurchaseCarPropose(uint carID, uint price, uint validTime) external {
        require(msg.sender == carDealerAddress, "This function can be called from car dealer only.");
        carProposeToBusiness(carID, price, validTime);
    }
    //ApproveSellProposal:      Repurchasecar:
    function proposeDriver(address payable driverAddress, uint salary) external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        proposedDriver = TaxiDriver(driverAddress, salary, 0);
    }
    function approveDriver() external {
        require(!driverApproves[msg.sender], "You already approved the proposed driver.");
        if(participants[msg.sender] == 0){
            revert("You must participate the contract for this action.");
        }
        driverApproves[msg.sender] = true;
        proposedDriver.approvalState += 1;
    }
    function setDriver() external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        if(proposedDriver.approvalState > participantsCount / 2){
            settedDriver = proposedDriver;
        }
        else if(proposedCar.price == 0){
            revert("There is no proposed driver to set");
        }
        else{
            revert("approvalState is less than half of the participants");
        }
    }
    function fireDriver() external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        if(settedDriver.salary == 0){
            revert("No driver has been approved yet.");
        }
        settedDriver.driverAddress.transfer(settedDriver.salary * 1 ether);
        settedDriver = TaxiDriver(address(0), 0, 0);
        proposedDriver = TaxiDriver(address(0), 0, 0);
    }
}