// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

contract Taxi {
    
    address managerAddress;
    address payable carDealerAddress;
    uint carExpenses;
    uint participationFee;
    uint participantsCount;
    
    uint driverAccount;
    uint driverLastPaymentDay;
    bool isDriverSalaryPaid;
    
    uint carExpensesLastPaymentDay;
    bool isCarExpensesPaid;
    
    uint profit;
    uint profitDividendLastPaymentDay;
    
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
        bool isCarPurchased;
        uint sellCarApprovalState;
    }
    
    ProposedCar public proposedCar;
    TaxiDriver proposedDriver;
    TaxiDriver public settedDriver;
    
    // Each participant is associated with an index when added. 
    //In this way, the balance of all of them is reached when necessary.
    uint[] public participantsBalances;    
    mapping(address => uint) public participantIndex;  
    mapping(address => bool) carApproves;
    mapping(address => bool) driverApproves;
    mapping(address => bool) sellProposalApproves;
    mapping(address => bool) public isParticipant;
    mapping(address => uint) participantsAccounts;
    
    
    
    constructor () {
        managerAddress = msg.sender;
        carExpenses = 2 ether;
        participationFee = 10 ether;
        participantsBalances.push(0);
    }
    
    

    function join() external payable {
        require(msg.value == participationFee, "You must pay exactly 10 ether to join contract");
        if(isParticipant[msg.sender]){
            revert("You already join the contract");
        }
        
        participantIndex[msg.sender] = participantsBalances.length;
        participantsBalances.push(0);
        isParticipant[msg.sender] = true;
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
        proposedCar = ProposedCar(carID, price, block.timestamp, validTime, 0, false, 0);
    }
    function approvePurchaseCar() external {
        require(!carApproves[msg.sender], "You already approved the proposed car.");
        if(!isParticipant[msg.sender]){
            revert("You must participate the contract for this action.");
        }
        else if(proposedCar.price == 0){
            revert("There is no car to approve");
        }
        carApproves[msg.sender] = true;
        proposedCar.approvalState += 1;
    }
    function purchaseCar() external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        if(proposedCar.price == 0){
            revert("There is no proposed car to purchase");
        }
        else if(proposedCar.approvalState > participantsCount / 2){
            if(proposedCar.proposeTime + proposedCar.validTime > block.timestamp){
                carDealerAddress.transfer(proposedCar.price * 1 ether);
                proposedCar.isCarPurchased = true;
            }
            else{
                revert("Valid Time exceed.");
            }
        }
        else{
            revert("approvalState is less than half of the participants");
        }
    }
    function repurchaseCarPropose(uint carID, uint price, uint validTime) external {
        require(msg.sender == carDealerAddress, "This function can be called from car dealer only.");
        if(proposedCar.isCarPurchased){
            proposedCar = ProposedCar(carID, price, block.timestamp, validTime, 0, proposedCar.isCarPurchased, 0);
        }
        else{
            revert("There is no car to sell");
        }
    }
    function approveSellProposal() external {
        require(!sellProposalApproves[msg.sender], "You already approved the sell proposal.");
        if(!isParticipant[msg.sender]){
            revert("You must participate the contract for this action.");
        }
        else if(!proposedCar.isCarPurchased){
            revert("There is no car to sell");
        }
        sellProposalApproves[msg.sender] = true;
        proposedCar.sellCarApprovalState += 1;
    }
    function repurchaseCar() external {
        require(msg.sender == carDealerAddress, "This function can be called from car dealer only.");
        if(!proposedCar.isCarPurchased){
            revert("There is no car to sell.");
        }
        else if(proposedCar.sellCarApprovalState > participantsCount / 2){
            if(proposedCar.proposeTime + proposedCar.validTime > block.timestamp){
                carDealerAddress.transfer(proposedCar.price * 1 ether);
            }
            else{
                revert("Valid Time exceed.");
            }
        }
        else{
            revert("approvalState is less than half of the participants");
        }
    }
    function proposeDriver(address payable driverAddress, uint salary) external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        proposedDriver = TaxiDriver(driverAddress, salary, 0);
    }
    function approveDriver() external {
        require(!driverApproves[msg.sender], "You already approved the proposed driver.");
        if(!isParticipant[msg.sender]){
            revert("You must participate the contract for this action.");
        }
        driverApproves[msg.sender] = true;
        proposedDriver.approvalState += 1;
    }
    function setDriver() external {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        if(proposedDriver.approvalState > participantsCount / 2){
            settedDriver = TaxiDriver(proposedDriver.driverAddress, proposedDriver.salary, 0);
        }
        else if(proposedDriver.salary == 0){
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
    function payTaxiCharge() external payable{
        // Ether cinsinden
        require(settedDriver.salary != 0 || proposedCar.isCarPurchased,
        "We don't have a working taxi right now. Therefore, you cannot have used the taxi.");
    }
    
    modifier driverSalaryDay {
        if (driverLastPaymentDay != 0) { // 0 ise ilk maaşıdır. Değilse en son ne zaman ödendiğine bak.
            require(block.timestamp - driverLastPaymentDay > 30 days,
                "30 days have not passed since the last payment."
            );
        }
        _;
    }
    function releaseSalary() external driverSalaryDay{
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        driverLastPaymentDay = block.timestamp;
        isDriverSalaryPaid = true;
        driverAccount += settedDriver.salary;
    }
    function getSalary() external {
        require(msg.sender == settedDriver.driverAddress, "This function can be called from driver only.");
        if(driverAccount == 0){
            revert("There is no money in driver account");
        }
        settedDriver.driverAddress.transfer(driverAccount * 1 ether);
        driverAccount = 0;
    }
    
    modifier carExpensesDay {
        if (carExpensesLastPaymentDay != 0) {
            require(block.timestamp - driverLastPaymentDay > 180 days,
                "6 months have not passed since the car expenses payment."
            );
        }
        _;
    }
    function payCarExpenses() external carExpensesDay {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        carExpensesLastPaymentDay = block.timestamp;
        isCarExpensesPaid = true;
        carDealerAddress.transfer(carExpenses);
    }
    
    modifier profitDividendDay {
        if (profitDividendLastPaymentDay != 0) {
            require(block.timestamp - driverLastPaymentDay > 180 days,
                "6 months have not passed since the last profit distribution."
            );
        }
        _;
    }
    function payDividend() external profitDividendDay  {
        require(msg.sender == managerAddress, "This function can be called from manager only.");
        if(isCarExpensesPaid && isDriverSalaryPaid){
            // Ödemeler yapıldıktan sonra kontratta kalan paradan
            // ilk giriş ücretlerini çıkarırsak kalan kar olur.
            profitDividendLastPaymentDay = block.timestamp;
            profit = address(this).balance - (participantsCount * participationFee);
            uint dividend = profit / participantsCount;
            for (uint i = 1; i < participantsBalances.length; i++) {
                participantsBalances[i] += dividend;
            }
            if(profit <= 0) {
                revert("There is no profit because no one used our taxi");
            }
        }
    }
    function getDividend() external {
        require(isParticipant[msg.sender], "You did not participate in this contract.");
        if(participantsBalances[participantIndex[msg.sender]] == 0){
            revert("You have no money in your account");
        }
        msg.sender.transfer(participantsBalances[participantIndex[msg.sender]]);
        participantsBalances[participantIndex[msg.sender]] = 0;
    }
}