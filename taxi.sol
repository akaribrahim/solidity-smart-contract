pragma solidity ^0.7.0;

contract Taxi {
    
    address managerAddress;
    address payable carDealerAddress;
    uint fixedExpenses;
    uint participationFee;
    uint participantsCount;
    
    struct TaxiDriver {
        address driverAddress;
        uint salary;
    }
    struct ProposedCar {
        uint carID;
        uint price;
        uint proposeTime;
        uint validTime;
        uint approvalState;
    }
    
    ProposedCar proposedCar;
    mapping(address => bool) approvingParticipants;
    mapping(address => uint) participants;
    
    
    
    constructor () {
        managerAddress = msg.sender;
        fixedExpenses = 2 ether;
        participationFee = 10 ether;
    }
    
    
    function join() external payable {
        require(msg.value == participationFee, "You must pay exactly 10 ether to join contract");
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
    function carProposeToBusiness(uint carID, uint price, uint validTime, uint approvalState) external {
        require(msg.sender == carDealerAddress, "This function can be called from car dealer only.");
        proposedCar = ProposedCar(carID, price, block.timestamp, validTime, approvalState);
    }
    function approvePurchaseCar() external {
        require(!approvingParticipants[msg.sender], "You already approved the proposed car.");
        if(participants[msg.sender] == 0){
            revert("You must participate the contract for this action.");
        }
        approvingParticipants[msg.sender] = true;
        proposedCar.approvalState += 1;
    }
    function purchaseCar() external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        if(proposedCar.approvalState > participantsCount / 2){
            carDealerAddress.transfer(proposedCar.price * 1 ether);
        }
        else{
            revert("Valid Time exceed or approvalState is less than half of the participants");
        }
    }
    
}