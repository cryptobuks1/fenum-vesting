// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract FenumVesting {
  using SafeMath for uint256;
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;

  address private _owner;
  IERC20 public token;

  uint256 public start;
  uint256 public end;
  uint256 public cliffDuration;

  mapping(address => uint256) public vestedAmount;
  mapping(address => uint256) public totalDrawn;
  mapping(address => uint256) public lastDrawnAt;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event ScheduleCreated(address indexed beneficiary);
  event DrawDown(address indexed beneficiary, uint256 indexed amount);

  constructor(address _token, uint256 _start, uint256 _end, uint256 _cliffDuration) public {
    _status = _NOT_ENTERED;

    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);

    token = IERC20(_token);          // TOKEN_ADDRESS
    start = _start;                  // 2021-01-01T00:00:00.000Z = 1609459200
    end = _end;                      // 2024-01-01T00:00:00.000Z = 1704067200
    cliffDuration = _cliffDuration;  // 30*24*60*60 = 2592000

    //setupPredefinedBeneficiaries();
  }

  /*
  function setupPredefinedBeneficiaries() internal returns (bool) {
    //vestedAmount[0x7F8d5E6C61685cCc92970c17c2659341e7eDAfe2] = 1_000_00;
    return true;
  }
  */

  function owner() public view returns (address) {
    return _owner;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /**
   * @notice Create new vesting schedules in a batch
   * @notice A transfer is used to bring tokens into the VestingDepositAccount so pre-approval is required
   * @param beneficiaries array of beneficiaries of the vested tokens
   * @param amounts array of amount of tokens (in wei)
   * @dev array index of address should be the same as the array index of the amount
   */
  function createVestingSchedules(address[] calldata beneficiaries, uint256[] calldata amounts) external onlyOwner returns (bool) {
    require(beneficiaries.length > 0, "FenumVesting: Empty Data");
    require(beneficiaries.length == amounts.length, "FenumVesting: Array lengths do not match");
    for (uint256 i = 0; i < beneficiaries.length; i = i.add(1)) {
      address beneficiary = beneficiaries[i];
      uint256 amount = amounts[i];
      _createVestingSchedule(beneficiary, amount);
    }
    return true;
  }

  /**
   * @notice Create a new vesting schedule
   * @notice A transfer is used to bring tokens into the VestingDepositAccount so pre-approval is required
   * @param beneficiary beneficiary of the vested tokens
   * @param amount amount of tokens (in wei)
   */
  function createVestingSchedule(address beneficiary, uint256 amount) external onlyOwner returns (bool) {
    return _createVestingSchedule(beneficiary, amount);
  }

  /**
   * @notice Draws down any vested tokens due
   * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
   */
  function drawDown() nonReentrant external returns (bool) {
    return _drawDown(_msgSender());
  }

  /**
   * @notice Vested token balance for a beneficiary
   * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
   * @return _contractBalance total balance proxied via the ERC20 token
   */
  function contractBalance() external view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
   * @notice Vesting schedule and associated data for a beneficiary
   * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
   * @return _amount
   * @return _totalDrawn
   * @return _lastDrawnAt
   * @return _remainingBalance
   */
  function vestingScheduleForBeneficiary(address beneficiary) external view
  returns (uint256 _amount, uint256 _totalDrawn, uint256 _lastDrawnAt, uint256 _remainingBalance) {
    return (
      vestedAmount[beneficiary],
      totalDrawn[beneficiary],
      lastDrawnAt[beneficiary],
      vestedAmount[beneficiary].sub(totalDrawn[beneficiary])
    );
  }

  /**
   * @notice Draw down amount currently available (based on the block timestamp)
   * @param beneficiary beneficiary of the vested tokens
   * @return amount tokens due from vesting schedule
   */
  function availableDrawDownAmount(address beneficiary) external view returns (uint256) {
    return _availableDrawDownAmount(beneficiary);
  }

  /**
   * @notice Balance remaining in vesting schedule
   * @param beneficiary beneficiary of the vested tokens
   * @return remainingBalance tokens still due (and currently locked) from vesting schedule
   */
  function remainingBalance(address beneficiary) external view returns (uint256) {
    return vestedAmount[beneficiary].sub(totalDrawn[beneficiary]);
  }

  function _createVestingSchedule(address beneficiary, uint256 amount) internal returns (bool) {
    require(beneficiary != address(0), "FenumVesting: Beneficiary cannot be empty");
    require(amount > 0, "FenumVesting: Amount cannot be empty");
    // Ensure one per address
    require(vestedAmount[beneficiary] == 0, "FenumVesting: Schedule already in flight");
    vestedAmount[beneficiary] = amount;
    // Vest the tokens into the deposit account and delegate to the beneficiary
    require(token.transferFrom(_msgSender(), address(this), amount), "FenumVesting: Unable to escrow tokens");
    emit ScheduleCreated(beneficiary);
    return true;
  }

  function _drawDown(address beneficiary) internal returns (bool) {
    require(vestedAmount[beneficiary] > 0, "FenumVesting: There is no schedule currently in flight");
    uint256 amount = _availableDrawDownAmount(beneficiary);
    require(amount > 0, "FenumVesting: No allowance left to withdraw");
    // Update last drawn to now
    lastDrawnAt[beneficiary] = _getNow();
    // Increase total drawn amount
    totalDrawn[beneficiary] = totalDrawn[beneficiary].add(amount);
    // Safety measure - this should never trigger
    require(totalDrawn[beneficiary] <= vestedAmount[beneficiary], "FenumVesting: Safety Mechanism - Drawn exceeded Amount Vested");
    // Issue tokens to beneficiary
    require(token.transfer(beneficiary, amount), "FenumVesting: Unable to transfer tokens");
    emit DrawDown(beneficiary, amount);
    return true;
  }

  function _availableDrawDownAmount(address beneficiary) internal view returns (uint256) {
    uint256 nowTime = _getNow();
    // Cliff Period
    if (nowTime <= start.add(cliffDuration)) {
      // the cliff period has not ended, no tokens to draw down
      return 0;
    }
    // Schedule complete
    if (nowTime > end) {
      return vestedAmount[beneficiary].sub(totalDrawn[beneficiary]);
    }
    // Schedule is active
    // Work out when the last invocation was
    uint256 timeLastDrawnOrStart = lastDrawnAt[beneficiary] == 0 ? start : lastDrawnAt[beneficiary];
    // Find out how much time has past since last invocation
    uint256 timePassedSinceLastInvocation = nowTime.sub(timeLastDrawnOrStart);
    // Work out how many due tokens - time passed * rate per second
    uint256 drawDownRate = vestedAmount[beneficiary].mul(1e18).div(end.sub(start));
    uint256 amount = timePassedSinceLastInvocation.mul(drawDownRate).div(1e18);
    return amount;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "FenumVesting: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "FenumVesting: caller is not the owner");
    _;
  }

  function _getNow() internal view returns (uint256) {
    return block.timestamp;
  }

  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  receive() external payable {
    revert("FenumVesting: contract does not accept Ether.");
  }

  fallback() external {
    revert("FenumVesting: contract action not found.");
  }
}
