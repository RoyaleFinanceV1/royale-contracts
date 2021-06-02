// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import './SafeERC20.sol';
import '../../Interfaces/CurveAaveInterface.sol';
import '../../Interfaces/DFYNInterface.sol';

contract AaveStrategy{
    
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint constant public N_COINS=3;
    
    address public royaleAddress;   //royale pool address
    address public yieldDistributor;  //account where all yield will be sent
    IERC20[N_COINS] public tokens;
    IERC20 public poolToken;
    IERC20 public WMatic;
    aavePool public pool;
    aaveGauge public gauge;
    DFYN public dfyn;
    address public weth;
    
    
    uint256 public constant DENOMINATOR = 10000;

    uint256 public depositSlip = 100;

    uint256 public withdrawSlip = 100;
   
    address public wallet;
    
    address public nominatedWallet; 
    
    modifier onlyAuthorized(){
      require(wallet == msg.sender|| msg.sender==royaleAddress, "Not authorized");
      _;
    }

    modifier onlyWallet(){
        require((wallet==msg.sender),"Not Authorized");
        _;
    }

    modifier onlyRoyaleLP() {
        require(msg.sender == royaleAddress, "Not authorized");
        _;
    }
    
    constructor(
         address _wallet,
         IERC20[3] memory _tokens, 
         address _royaleaddress,
         address _yieldDistributor,
         address _pool,
         address _poolToken,
         address _wmatic,
         address _gauge,
         address _dfyn,
         address _weth
         ) public {

        wallet=_wallet;
        tokens = _tokens;
        royaleAddress =_royaleaddress;
        yieldDistributor=_yieldDistributor;
        pool = aavePool(_pool);
        poolToken = IERC20(_poolToken);
        WMatic=IERC20(_wmatic);
        gauge = aaveGauge(_gauge);
        dfyn=DFYN(_dfyn);
        weth=_weth;
    }
    
    
    function nominateNewOwner(address _wallet) external onlyWallet {
        nominatedWallet = _wallet;
        emit walletNominated(_wallet);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedWallet, "You must be nominated before you can accept ownership");
        emit walletChanged(wallet, nominatedWallet);
        wallet = nominatedWallet;
        nominatedWallet = address(0);
    }

    function changeRoyaleLP(address _address)external onlyWallet(){
        royaleAddress=_address;
    }

    function changeYieldDistributor(address _address)external onlyWallet(){
        yieldDistributor=_address;
    }
    
    function changeDepositSlip(uint _value)external onlyWallet(){
        depositSlip=_value;
    }
    
    function changeWithdrawSlip(uint _value)external onlyWallet(){
        withdrawSlip=_value;
    }
    
    // deposits stable tokens into the aave pool and stake recived LPtoken in the curve aave pool gauge
    function deposit(uint[N_COINS] memory amounts) external onlyRoyaleLP(){
        uint currentTotal;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
               uint decimal;
               decimal=tokens[i].decimals();
               tokens[i].safeApprove(address(pool),0);
               tokens[i].safeApprove(address(pool), amounts[i]); 
               currentTotal =currentTotal.add(amounts[i].mul(1e18).div(10**decimal));
            }
        }
        uint256 mintAmount = currentTotal.mul(1e18).div(pool.get_virtual_price());
        pool.add_liquidity(amounts,  mintAmount.mul(DENOMINATOR.sub(depositSlip)).div(DENOMINATOR),true);
        stakeLP();   
    }
    
    //withdraws stable tokens from the aave pool.Unstake required LPtokens and stake LP tokens if not used.
    function withdraw(uint[N_COINS] memory amounts,uint[N_COINS] memory max_burn) external onlyRoyaleLP() {
        uint burnAmount;
        for(uint i=0;i<N_COINS;i++){
             burnAmount = burnAmount.add(max_burn[i]);
        }
        burnAmount=burnAmount.mul(DENOMINATOR.add(withdrawSlip)).div(DENOMINATOR);
        unstakeLP(burnAmount);
        pool.remove_liquidity_imbalance(amounts, burnAmount,true);
        for(uint8 i=0;i<N_COINS;i++){
            if(amounts[i]!=0){
               tokens[i].safeTransfer(royaleAddress, tokens[i].balanceOf(address(this)));
            }
        }
        if(poolToken.balanceOf(address(this))>0){
            stakeLP();
        } 
    }
    
    //unstake all the LPtokens and withdraw all the Stable tokens from aave pool 
    function withdrawAll() external onlyRoyaleLP() returns(uint256[N_COINS] memory){
       unstakeLP(gauge.balanceOf(address(this)));
        uint256[N_COINS] memory withdrawAmt;
        pool.remove_liquidity(poolToken.balanceOf(address(this)),withdrawAmt,true);
        for(uint8 i=0;i<N_COINS;i++){
            if(tokens[i].balanceOf(address(this))!=0){
                withdrawAmt[i]=tokens[i].balanceOf(address(this));
                tokens[i].safeTransfer(royaleAddress,withdrawAmt[i]); 
            }
        }
        return withdrawAmt; 
    } 
    
    //Stakes LP token into the curve aave pool gauage
    function stakeLP() public onlyAuthorized() {
        uint depositAmt = poolToken.balanceOf(address(this)) ;
        poolToken.safeApprove(address(gauge),0);
        poolToken.safeApprove(address(gauge), depositAmt);
        gauge.deposit(depositAmt);  
        emit staked(depositAmt);
    }
    
    //For unstaking LP tokens
    function unstakeLP(uint _amount) public  onlyAuthorized(){
        require(gauge.balanceOf(address(this)) >= _amount,"You have not staked that much amount");
        gauge.withdraw(_amount);
        emit unstaked(_amount);
    }
    
    //function for claiming wmatic rewards
    function claimWMatic()external onlyWallet(){
        gauge.claim_rewards();
    }
    
    //function for claiming historic rewards
    function claimHistoricReward(address[8] memory _rewardTokens)external onlyWallet(){
        gauge.claim_historic_rewards(_rewardTokens);
    }
    
    function swapWMatic(uint _amount,uint _minimumAmount,uint _index)external onlyWallet(){
        require(WMatic.balanceOf(address(this))>=_amount,"Insufficient WMatic amount");
        WMatic.safeApprove(address(dfyn),0);
        WMatic.safeApprove(address(dfyn),_amount);
        address[] memory path;
        path = new address[](3);
        path[0] = address(WMatic);
        path[1] = weth;
        path[2] = address(tokens[_index]);
        dfyn.swapExactTokensForTokens(
            _amount, 
            _minimumAmount, 
            path, 
            address(yieldDistributor), 
            now + 600
        );
    }
    
    // Added to support recovering tokens
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyWallet() {
        require(_tokenAddress != address(poolToken), "Cannot withdraw LP token");
        IERC20(_tokenAddress).safeTransfer(address(yieldDistributor), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }
    

    event unstaked(uint amount);
    event staked(uint amount);
    event walletNominated(address newOwner);
    event walletChanged(address oldOwner, address newOwner); 
    event Recovered(address,uint);
    
}
