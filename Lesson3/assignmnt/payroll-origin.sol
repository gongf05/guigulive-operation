
pragma solidity ^0.4.14;

import './SafeMath.sol';
import './Ownable.sol';

contract Payroll is Ownable {
    
    using SafeMath for uint;
    
    // struct with employee info
    struct Employee {
        address id;
        uint salary;
        uint lastPayday;
    }
    
    uint constant payDuration = 10 seconds;
    
    uint totalSalary = 0;
    address owner;
    
    // mapping from address to Employee struct
    mapping(address => Employee) public employees;
    
    // modifier to check whether the target employee exists
    modifier employeeExist(address employeeId){
        var employee = employees[employeeId];
        assert(employee.id != 0x0);
        _;
    }

    
    // 1. pay employee before remove or update employee to avoid mistake
    function _partialPaid(Employee employee) private {
        uint payment = employee.salary
             .mul(now.sub(employee.lastPayday)).div(payDuration);
        employee.id.transfer(payment);
    }

    // 2. owner adds new employee
    function addEmployee(address employeeId, uint salary) onlyOwner {
        var employee = employees[employeeId];
        assert(employee.id == 0x0);
        
        employees[employeeId] = Employee(employeeId, salary.mul(1 ether), now);
        totalSalary = totalSalary.add(employees[employeeId].salary);
    }
    
    // 3. owner remove employee from contract
    function removeEmployee(address employeeId) onlyOwner employeeExist(employeeId){
        var employee = employees[employeeId];
        
        // pay employee before remove him!
        _partialPaid(employee);
        // update totalSalary
        totalSalary.sub(employees[employeeId].salary);
        // remove this employee
        delete employees[employeeId];
    }
    
    // 4. owner update employee's salary
    function updateEmployee(address employeeId, uint salary) onlyOwner employeeExist(employeeId) {
        var employee = employees[employeeId];
        
        // pay employee before update
        _partialPaid(employee);
        
        // update totalSalary correspondingly
        totalSalary = totalSalary.sub(employees[employeeId].salary);
        
        // update employee reocord
        employees[employeeId].salary = salary * 1 ether;
        employees[employeeId].lastPayday = now;
        totalSalary = totalSalary.add(employees[employeeId].salary);
    }
    
    // 5. add fund into contract by owner
    function addFund() payable returns (uint) {
        return this.balance;
    }
    
    // 6. calculate times of pay in this contract - avoid for-loop to save gas!
    function calculateRunway() returns (uint) {
        return this.balance.div(totalSalary);
    }
    
    // 7. check whether this contract has enough fund
    function hasEnoughFund() returns (bool) {
        return calculateRunway() > 0;
    }
    
    // 8. employee get paid from contract
    function getPaid() employeeExist(msg.sender) {
        var employee = employees[msg.sender];
        
        uint nextPayday = employee.lastPayday.add(payDuration);
        assert(nextPayday < now);
        
        employees[msg.sender].lastPayday = nextPayday;
        employee.id.transfer(employee.salary);
    }
    
    
}
