pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simple ERC20Basic contract
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20
 * @dev Additional features of ERC20Basic
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Simple math operations with safety checks, which can throw an error
 */
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);

        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
  
}

/**
 * @title BasicToken
 * @dev Basic version of StandardToken without allowances
 */
contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);

        return true;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title StandardToken
 * @dev Basic standard token
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];
        
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

/**
 * @title Ownable
 * @dev Save owner address, provides only owner control and can transfer ownership
 */
contract Ownable {
    
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));      
        owner = newOwner;
    }

}

/**
 * @title MintableToken
 * @dev Simple ERC20 token with mintable functions
 */
contract MintableToken is StandardToken, Ownable {
    
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
  
}

/**
 * @title RNTtoken
 * @dev Creates simple coin with name, symbol and number of decimals
 */
contract RNTtoken is MintableToken {
    
    string public constant name = "Bitrent";
    
    string public constant symbol = "RNT";
    
    uint32 public constant decimals = 18;
    
}


/**
 * @title MainSale
 * @dev Contract for managing token main sale
 */
contract MainSale is Ownable {

    using SafeMath for uint;
    
    address multisig; // stores ETH investment
    address restricted; // tokens for us
    
    address[] keys;
    mapping(address => uint) investors;
    
    RNTtoken public token = new RNTtoken();
    
    uint public start;
    uint public period;

    uint public hardcap;
    uint public openSaleTokens;
    uint public ourTokens;
    uint public minPurchase;
    uint public totalInvestment;
    
    function MainSale() {

        multisig = 0x583031d1113ad414f02576bd6afabfb302140225;
        restricted = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148;

        start = 1512129600;
        period = 30;
        
        hardcap = 100000 ether;
        openSaleTokens = 699000000;
        ourTokens = 101000000;
        minPurchase = 0.01 ether;

    }
    
    modifier saleIsOn() {
       require(now > start && now < start + period * 1 days);
       _;
    }
    
    modifier saleIsOut() {
        require(now > start + period * 1 days);
        _;
    }

    modifier isUnderHardCap() {
        require(totalInvestment <= hardcap);
        _;
    }
    
    modifier isOverMinPurchase() {
        require(msg.value >= minPurchase);
        _;
    }
    
    function addInvestment() public {
        if (investors[msg.sender] == 0) {
            investors[msg.sender] = msg.value;
            keys.push(msg.sender);
        } else {
            investors[msg.sender] += msg.value;
        }
    }
    
    function() external saleIsOn isUnderHardCap isOverMinPurchase payable {
        multisig.transfer(msg.value);
        addInvestment();
        totalInvestment += msg.value;
    }
    
    function transferOwnershipRNTtoken(address newOwner) onlyOwner {
        require(newOwner != address(0));      
        owner = newOwner;
    }

    function getInvestment(address _investor) onlyOwner returns(uint) {
        return investors[_investor];
    }
    
    function createTokens() /*saleIsOut*/ onlyOwner payable {
        for(uint i = 0; i < keys.length; i++) {
            token.mint(keys[i], investors[keys[i]].mul(openSaleTokens).div(totalInvestment));
        }
        // Our tokens
        token.mint(restricted, ourTokens);
        
        // Finish minting
        token.finishMinting();
    }

}