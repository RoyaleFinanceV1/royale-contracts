// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import './SafeERC20.sol';
import '../../Interfaces/EllipsisInterface.sol';
import '../../Interfaces/PancakeInterface.sol';

contract poolStrategy{
    
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public royaleAddress;   //royale pool address
    address public yieldDistributor;  //account where all yield will be sent
    IERC20 public daiPoolToken;  // DAI pool LP token
    IERC20 public pool3Token;   // 3pool LP token
    IERC20 public epsToken;     //EPS token
    IERC20[N_COINS] public tokens;  // DAI / USDC / USDT / BUSD
    EllipsisDAIPool public daiPool;  //DAI pool address
    Ellipsis3Pool public pool3;     //3pool address
    DepositZap public depositZap;    // DAI pool deposit zap address
    LPStaker public lpStaker;   //LP token staker contract address
    EPSStaker public epsStaker; //EPS token staker contract address
    Pancake public pancake;
    address public WBNB;
    
    uint constant public N_COINS=4;
    
    uint public poolID=4;
    
    uint256 public constant DENOMINATOR = 10000;

    uint256 public depositSlip = 100;

    uint256 public withdrawSlip = 100;
    
    uint[]  poolId;
    
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
         IERC20[N_COINS] memory _tokens, 
         address _royaleaddress,
         address _yieldDistributor,
         address _daiPoolToken,
         address _pool3Token,
         address _epsToken,
         address _daiPool,
         address _pool3,
         address _depositZap,
         address _lpStaker,
         address _epsStaker,
         address _pancake,
         address _wbnb
         ) public {
        poolId.push(poolID);
        wallet=_wallet;
        tokens = _tokens;
        royaleAddress =_royaleaddress;
        yieldDistributor=_yieldDistributor;
        daiPoolToken=IERC20(_daiPoolToken);
        pool3Token=IERC20(_pool3Token);
        epsToken=IERC20(_epsToken);
        daiPool=EllipsisDAIPool(_daiPool);
        pool3=Ellipsis3Pool(_pool3);
        depositZap=DepositZap(_depositZap);
        lpStaker=LPStaker(_lpStaker);
        epsStaker=EPSStaker(_epsStaker);
        pancake=Pancake(_pancake);
        WBNB=_wbnb;
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
    
  
    // deposits stable tokens into the Daipool and stake recived LPtoken
    function deposit(uint[N_COINS] memory amounts) external onlyRoyaleLP(){
        uint currentTotal;
        for(uint i=0;i<N_COINS;i++){
            if(i!=0){
                currentTotal=currentTotal.add(amounts[i]);
            }
            tokens[i].safeApprove(address(depositZap),0);
            tokens[i].safeApprove(address(depositZap),amounts[i]);
        }
        uint minimumMintAmount=currentTotal.mul(1e18).div(pool3.get_virtual_price());
        currentTotal=amounts[0]+minimumMintAmount;
        uint256 mintAmount = currentTotal.mul(1e18).div(daiPool.get_virtual_price());
        depositZap.add_liquidity(amounts,  mintAmount.mul(DENOMINATOR.sub(depositSlip)).div(DENOMINATOR));
        stakeLP();   
    }
    
    //withdraws stable tokens from the 3pool.Unstake required LPtokens and stake LP tokens if not used.
    function withdraw(uint[N_COINS] memory amounts,uint[N_COINS] memory max_burn) external onlyRoyaleLP() {
        uint burnAmount;
        for(uint i=0;i<N_COINS;i++){
             burnAmount = burnAmount.add(max_burn[i]);
        }
        burnAmount=burnAmount.mul(DENOMINATOR.add(withdrawSlip)).div(DENOMINATOR);
        unstakeLP(burnAmount);
        daiPoolToken.safeApprove(address(depositZap),0);
        daiPoolToken.safeApprove(address(depositZap),burnAmount);
        depositZap.remove_liquidity_imbalance(amounts, burnAmount);
        for(uint8 i=0;i<N_COINS;i++){
            if(amounts[i]!=0){
               tokens[i].safeTransfer(royaleAddress, tokens[i].balanceOf(address(this)));
            }
        }
        if(daiPoolToken.balanceOf(address(this))>0){
            stakeLP();
        } 
    }
    
    //unstake all the LPtokens and withdraw all the Stable tokens from pool 
    function withdrawAll() external onlyRoyaleLP() returns(uint256[N_COINS] memory){
        if(checkClaimableToken()>0){
            claimLPEPS();
        }
        lpStaker.emergencyWithdraw(poolID);
        uint256[N_COINS] memory withdrawAmt;
        daiPoolToken.safeApprove(address(depositZap),0);
        daiPoolToken.safeApprove(address(depositZap),daiPoolToken.balanceOf(address(this)));
        depositZap.remove_liquidity(daiPoolToken.balanceOf(address(this)),withdrawAmt);
        for(uint8 i=0;i<N_COINS;i++){
            if(tokens[i].balanceOf(address(this))!=0){
                withdrawAmt[i]=tokens[i].balanceOf(address(this));
                tokens[i].safeTransfer(royaleAddress,withdrawAmt[i]); 
            }
        }
        return withdrawAmt; 
    } 
    
    
    //Stakes LP token(dai3EPS) into the curve 3pool gauage
    function stakeLP() public onlyAuthorized() {
        uint depositAmt = daiPoolToken.balanceOf(address(this)) ;
        daiPoolToken.safeApprove(address(lpStaker),0);
        daiPoolToken.safeApprove(address(lpStaker), depositAmt);
        lpStaker.deposit(poolID,depositAmt);  
        emit staked(depositAmt);
    }

    //For unstaking LP tokens(dai3EPS)
    function unstakeLP(uint _amount) public  onlyAuthorized(){
       uint totalStaked;
       (totalStaked,)=lpStaker.userInfo(poolID,address(this));
        require(totalStaked >= _amount,"You have not staked that much amount");
        lpStaker.withdraw(poolID,_amount);
        emit unstaked(_amount);
    }
    
     //Checking claimable EPS tokens.
    function checkClaimableToken()public view  returns(uint256){
        return lpStaker.claimableReward(poolID,address(this));
    }

    //for claiming EPS tokens which accumalates on staking dai3EPS.
    //Vested EPS
    function claimLPEPS() public onlyAuthorized(){
        lpStaker.claim(poolId);
        emit epsVested();
    }
    
    //For staking EPS 
    function stakeEPS(uint _amount,bool _lock) external onlyWallet(){
        require(_amount>0,"can not stake 0");
        epsToken.safeApprove(address(epsStaker),0);
        epsToken.safeApprove(address(epsStaker),_amount);
        epsStaker.stake(_amount,_lock);
        emit EPSStaked(_amount);
        
    }
    
    //for unstaking EPS and EPS remain in this contract
    function unstakEPS(uint _amount)external onlyWallet(){
        epsStaker.withdraw(_amount);
        emit EPSWithdrawn(_amount);
    }
    
    
    //claim rewards,  _transfer =true for transfering claimed EPS token to be transfered to distributed wallet
    //false in case we don't want to transfer EPS tokens
    //busd will always be transfered
    function claimReward(bool _transfer) external onlyWallet(){
        uint busdAmount=tokens[1].balanceOf(address(this));
        uint epsAmount=epsToken.balanceOf(address(this));
        epsStaker.getReward();
        uint busdAmountAfter=tokens[1].balanceOf(address(this));
        uint epsAmountAfter=epsToken.balanceOf(address(this));
        emit rewardClaimed(epsAmountAfter.sub(epsAmount),busdAmountAfter.sub(busdAmount));
        if(_transfer){
            if((epsAmountAfter.sub(epsAmount))>0){
                epsToken.safeTransfer(yieldDistributor,epsAmountAfter.sub(epsAmount));
            }
        }
        if((busdAmountAfter.sub(busdAmount))>0){
            tokens[1].safeTransfer(yieldDistributor,busdAmountAfter.sub(busdAmount));
        }
    }
    
    //withwithdrawExpiredlockEPS - where lock is expired,  _transfer =true for transfering EPS token to be transfered to distributed wallet
    //false in case we don't want to transfer EPS tokens
    function withdrawExpiredlockEPS(bool _transfer)external onlyWallet(){
        uint epsAmount=epsToken.balanceOf(address(this));
        epsStaker.withdrawExpiredLocks();
        uint epsAmountAfter=epsToken.balanceOf(address(this));
        if(_transfer){
            if((epsAmountAfter.sub(epsAmount))>0){
                 epsToken.safeTransfer(yieldDistributor,epsAmountAfter.sub(epsAmount));
            }
        }
        emit EPSWithdrawn(epsAmountAfter.sub(epsAmount));
    }
    
    //check how much amount is unlocked and able to withdraw
    function checkUnlockedBalance()public view returns(uint){
        return epsStaker.unlockedBalance(address(this));
    }
    
    //Exit all earned EPS(with penalty if applicable) and unlocked EPS 
    //claim rewards
    function ExitAllStakedEPS(bool _transfer) external onlyWallet(){
        uint busdAmount=tokens[1].balanceOf(address(this));
        uint epsAmount=epsToken.balanceOf(address(this));
        epsStaker.exit();
        uint busdAmountAfter=tokens[1].balanceOf(address(this));
        uint epsAmountAfter=epsToken.balanceOf(address(this));
        if(_transfer){
            if((epsAmountAfter.sub(epsAmount))>0){
                epsToken.safeTransfer(yieldDistributor,epsAmountAfter.sub(epsAmount));
            }
        }
        if((busdAmountAfter.sub(busdAmount))>0){
            tokens[1].safeTransfer(yieldDistributor,busdAmountAfter.sub(busdAmount));
        }
    }
    
    //_index = 0-DAI , 1-BUSD , 2-USDC , 3-USDT (swap EPS to stable token)
    function swapEPS(uint _amount , uint _index ,uint _minAmount) external onlyWallet(){
        require(epsToken.balanceOf(address(this))>=_amount,"Insufficient EPS amount");
        epsToken.safeApprove(address(pancake),0);
        epsToken.safeApprove(address(pancake),_amount);
        address[] memory path;
        path = new address[](3);
        path[0] = address(epsToken);
        path[1] = WBNB;
        path[2] = address(tokens[_index]);
        pancake.swapExactTokensForTokens(
            _amount, 
            _minAmount, 
            path, 
            address(yieldDistributor), 
            now + 600
        );
        emit yieldTransfered();
    }
    
   // Added to support recovering tokens
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyWallet() {
        require(_tokenAddress != address(daiPoolToken), "Cannot withdraw DAI LP token");
        IERC20(_tokenAddress).safeTransfer(address(yieldDistributor), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }
    
    
    event yieldTransfered();
    event rewardClaimed(uint EPS,uint BUSD);
    event EPSWithdrawn(uint );
    event EPSStaked(uint );
    event epsVested();
    event unstaked(uint);
    event staked(uint);
    event walletNominated(address newOwner);
    event walletChanged(address oldOwner, address newOwner);
    event Recovered(address,uint);
  
}